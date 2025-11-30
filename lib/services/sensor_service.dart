

//Dual BLE
//cpr_training_app/lib/services/sensor_service.dart
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class SensorService {
  // BLE Configuration - matches your ESP32 setup
  static const String serviceUuid = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  static const String characteristicUuid = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
  static const String deviceNamePrefix = "CPR_Monitor";

  // Connection state for multiple devices
  Map<String, BluetoothDevice> _connectedDevices = {};
  Map<String, StreamSubscription<List<int>>> _characteristicSubscriptions = {};

  bool _isConnecting = false;
  bool _isScanning = false;

  // Pressure tracking
  double _currentPressure = 0.0;
  bool get isPressureActive => _currentPressure > 10.0;
  double get currentPressure => _currentPressure;

  // Data streams
  final _connectionStatusController = StreamController<String>.broadcast();
  final _sensorDataController = StreamController<SensorData>.broadcast();
  final _rawDataController = StreamController<RawSensorData>.broadcast();
  final _deviceConnectionController = StreamController<DeviceConnectionEvent>.broadcast();
  final _pressureController = StreamController<double>.broadcast();

  // Available devices
  final List<BluetoothDevice> _availableDevices = [];

  // Getters
  bool get isConnected => _connectedDevices.isNotEmpty;
  bool get isConnecting => _isConnecting;
  bool get isScanning => _isScanning;
  List<String> get connectedDeviceNames => _connectedDevices.values.map((d) => d.platformName).toList();
  List<BluetoothDevice> get connectedDevices => _connectedDevices.values.toList();
  List<BluetoothDevice> get availableDevices => List.unmodifiable(_availableDevices);

  // Streams
  Stream<String> get connectionStatusStream => _connectionStatusController.stream;
  Stream<SensorData> get sensorDataStream => _sensorDataController.stream;
  Stream<RawSensorData> get rawDataStream => _rawDataController.stream;
  Stream<DeviceConnectionEvent> get deviceConnectionStream => _deviceConnectionController.stream;
  Stream<double> get pressureStream => _pressureController.stream;

  // Initialize the service
  Future<void> initialize() async {
    debugPrint('Initializing SensorService...');

    // Listen to FlutterBluePlus adapter state
    FlutterBluePlus.adapterState.listen((BluetoothAdapterState state) {
      switch (state) {
        case BluetoothAdapterState.off:
          _updateConnectionStatus('Bluetooth is turned off');
          disconnectAll();
          break;
        case BluetoothAdapterState.on:
          _updateConnectionStatus('Bluetooth ready - Tap Connect to start');
          break;
        default:
          _updateConnectionStatus('Bluetooth state: ${state.name}');
          break;
      }
    });

    _updateConnectionStatus('Sensor service initialized');
  }

  // Start scanning for CPR devices
  Future<void> startScan({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (_isScanning || _isConnecting) return;

    _isScanning = true;
    _availableDevices.clear();
    _updateConnectionStatus('Scanning for CPR devices...');

    try {
      // Check if Bluetooth is supported and enabled
      if (await FlutterBluePlus.isSupported == false) {
        throw Exception('Bluetooth not supported on this device');
      }

      final adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        throw Exception('Bluetooth is not enabled');
      }

      // Start scanning
      await FlutterBluePlus.startScan(
        timeout: timeout,
        androidUsesFineLocation: false,
      );

      // Listen to scan results
      final scanSubscription = FlutterBluePlus.scanResults.listen((
          List<ScanResult> results,
          ) {
        for (ScanResult result in results) {
          final device = result.device;
          final deviceName = device.platformName;

          // Filter for CPR devices and avoid duplicates
          if ((deviceName.startsWith(deviceNamePrefix) || deviceName.contains("Pressure")) &&
              !_availableDevices.any((d) => d.remoteId == device.remoteId)) {
            _availableDevices.add(device);
            debugPrint('Found device: $deviceName (${device.remoteId})');
          }
        }
      });

      // Wait for scan to complete
      await FlutterBluePlus.isScanning.where((scanning) => !scanning).first;

      await scanSubscription.cancel();

      _updateConnectionStatus(
        _availableDevices.isEmpty
            ? 'No devices found'
            : 'Found ${_availableDevices.length} device(s)',
      );
    } catch (e) {
      debugPrint('Scan error: $e');
      _updateConnectionStatus('Scan failed: ${e.toString()}');
    } finally {
      _isScanning = false;
    }
  }

  // Connect to a specific device
  Future<void> connectToDevice(BluetoothDevice device) async {
    if (_isConnecting || _connectedDevices.containsKey(device.remoteId.toString())) return;

    _isConnecting = true;
    _updateConnectionStatus('Connecting to ${device.platformName}...');

    try {
      // Connect to device with timeout
      await device.connect(autoConnect: false).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Connection timeout', const Duration(seconds: 15));
        },
      );

      debugPrint('Connected to ${device.platformName}');

      // Discover services
      final services = await device.discoverServices();
      debugPrint('Discovered ${services.length} services');

      // Find the CPR service
      BluetoothService? cprService;
      for (var service in services) {
        if (service.uuid.toString().toLowerCase() == serviceUuid.toLowerCase()) {
          cprService = service;
          break;
        }
      }

      if (cprService == null) {
        throw Exception('CPR service not found. Make sure the ESP32 firmware is correct.');
      }

      debugPrint('Found CPR service: ${cprService.uuid}');

      // Find the data characteristic
      BluetoothCharacteristic? dataCharacteristic;
      for (var characteristic in cprService.characteristics) {
        if (characteristic.uuid.toString().toLowerCase() == characteristicUuid.toLowerCase()) {
          dataCharacteristic = characteristic;
          break;
        }
      }

      if (dataCharacteristic == null) {
        throw Exception('CPR data characteristic not found');
      }

      debugPrint('Found data characteristic: ${dataCharacteristic.uuid}');

      // Check if characteristic supports notifications
      if (!dataCharacteristic.properties.notify) {
        throw Exception('Data characteristic does not support notifications');
      }

      // Enable notifications
      await dataCharacteristic.setNotifyValue(true);
      debugPrint('Notifications enabled for ${device.platformName}');

      // Subscribe to data stream with device ID
      final subscription = dataCharacteristic.onValueReceived.listen(
            (data) => _handleSensorData(data, device),
        onError: (error) {
          debugPrint('Characteristic subscription error for ${device.platformName}: $error');
          _disconnectDevice(device);
        },
      );

      // Store connection
      final deviceId = device.remoteId.toString();
      _connectedDevices[deviceId] = device;
      _characteristicSubscriptions[deviceId] = subscription;

      _updateConnectionStatus('Connected to ${device.platformName}');

      // Notify about new connection
      _deviceConnectionController.add(DeviceConnectionEvent(
        deviceId: deviceId,
        deviceName: device.platformName,
        isConnected: true,
      ));

      debugPrint('Successfully connected and subscribed to ${device.platformName}');

    } catch (e) {
      debugPrint('Connection failed to ${device.platformName}: $e');
      _updateConnectionStatus('Connection failed: ${e.toString()}');

      try {
        await device.disconnect();
      } catch (disconnectError) {
        debugPrint('Error during cleanup disconnect: $disconnectError');
      }
    } finally {
      _isConnecting = false;
    }
  }

  // Disconnect from specific device
  Future<void> disconnectDevice(BluetoothDevice device) async {
    await _disconnectDevice(device);
  }

  // Disconnect from all devices
  Future<void> disconnectAll() async {
    for (final device in _connectedDevices.values.toList()) {
      await _disconnectDevice(device);
    }
  }

  Future<void> _disconnectDevice(BluetoothDevice device) async {
    final deviceId = device.remoteId.toString();

    try {
      // Cancel characteristic subscription
      await _characteristicSubscriptions[deviceId]?.cancel();
      _characteristicSubscriptions.remove(deviceId);

      // Disconnect device
      await device.disconnect();
      debugPrint('Disconnected from ${device.platformName}');

    } catch (e) {
      debugPrint('Disconnect error: $e');
    } finally {
      // Remove from connected devices
      _connectedDevices.remove(deviceId);

      // Notify about disconnection
      _deviceConnectionController.add(DeviceConnectionEvent(
        deviceId: deviceId,
        deviceName: device.platformName,
        isConnected: false,
      ));

      if (_connectedDevices.isEmpty) {
        _updateConnectionStatus('Disconnected from all devices');
      } else {
        _updateConnectionStatus('${_connectedDevices.length} device(s) connected');
      }
    }
  }

  // Handle incoming sensor data with device info
  void _handleSensorData(List<int> data, BluetoothDevice device) {
    try {
      final dataString = String.fromCharCodes(data).trim();
      final deviceId = device.remoteId.toString();
      final deviceName = device.platformName;

      // Create raw data object for debugging
      final rawData = RawSensorData(
        timestamp: DateTime.now(),
        rawBytes: Uint8List.fromList(data),
        length: data.length,
        deviceId: deviceId,
        deviceName: deviceName,
      );
      _rawDataController.add(rawData);

      debugPrint('Received BLE data from $deviceName: $dataString');

      // Parse CSV format differently based on device type
      final parts = dataString.split(',');

      // Check if this is pressure data (Time(ms), Raw ADC, Pressure(0-100))
      if (parts.length == 3 && (deviceName.contains("Pressure") || deviceName.contains("Secondary"))) {
        // Secondary ESP32 sending pressure data
        try {
          final timeMs = int.parse(parts[0]);
          final rawAdc = int.parse(parts[1]);
          final pressure = double.parse(parts[2]);

          _currentPressure = pressure;
          _pressureController.add(pressure);

          debugPrint('Pressure from $deviceName: $pressure (Raw: $rawAdc, Time: $timeMs ms) - Active: ${isPressureActive}');
        } catch (parseError) {
          debugPrint('Error parsing pressure values from $deviceName: $parseError');
        }
      }
      // Primary ESP32 sending depth/count/tilt data
      else if (parts.length >= 4 && (deviceName.contains("CPR_Monitor") || deviceName.contains("Primary"))) {
        try {
          final depth = double.parse(parts[0]);
          final count = int.parse(parts[1]);
          final tiltX = double.parse(parts[2]);
          final tiltY = double.parse(parts[3]);

          // Only create sensor data if pressure is active
          if (isPressureActive) {
            final sensorData = SensorData(
              timestamp: DateTime.now(),
              deviceId: deviceId,
              deviceName: deviceName,
              compressionDepth: depth,
              compressionCount: count,
              tiltX: tiltX,
              tiltY: tiltY,
            );

            _sensorDataController.add(sensorData);

            debugPrint(
              'Parsed from $deviceName: Depth=${depth}mm, Count=$count, TiltX=$tiltX°, TiltY=$tiltY°',
            );
          } else {
            debugPrint('Pressure not active ($_currentPressure) - ignoring data from $deviceName');
          }
        } catch (parseError) {
          debugPrint('Error parsing values from $deviceName: $parseError');
        }
      } else {
        debugPrint('Unknown data format from $deviceName: ${parts.length} values - $dataString');
      }
    } catch (e) {
      debugPrint('Error handling sensor data from ${device.platformName}: $e');
    }
  }

  // Check if device is connected
  bool isDeviceConnected(String deviceId) {
    return _connectedDevices.containsKey(deviceId);
  }

  // Get connected device by ID
  BluetoothDevice? getConnectedDevice(String deviceId) {
    return _connectedDevices[deviceId];
  }

  // Update connection status
  void _updateConnectionStatus(String status) {
    debugPrint('Connection status: $status');
    _connectionStatusController.add(status);
  }

  // Get first available device (for auto-connect)
  BluetoothDevice? getFirstAvailableDevice() {
    return _availableDevices.isNotEmpty ? _availableDevices.first : null;
  }

  // Auto-connect to first available device
  Future<void> autoConnect() async {
    if (_isConnecting || isConnected) return;

    await startScan();

    final device = getFirstAvailableDevice();
    if (device != null) {
      await connectToDevice(device);
    } else {
      _updateConnectionStatus('No devices found for auto-connect');
    }
  }

  // Auto-connect to all available devices
  Future<void> autoConnectAll() async {
    if (_isConnecting) return;

    await startScan();

    for (final device in _availableDevices) {
      if (!_connectedDevices.containsKey(device.remoteId.toString())) {
        await connectToDevice(device);
        // Small delay between connections
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
  }

  // Dispose resources
  void dispose() {
    debugPrint('Disposing SensorService...');

    disconnectAll();
    _connectionStatusController.close();
    _sensorDataController.close();
    _rawDataController.close();
    _deviceConnectionController.close();
    _pressureController.close();
  }
}

// Data models for sensor information
class SensorData {
  final DateTime timestamp;
  final String deviceId;
  final String deviceName;
  final double compressionDepth;
  final int compressionCount;
  final double tiltX;
  final double tiltY;

  const SensorData({
    required this.timestamp,
    required this.deviceId,
    required this.deviceName,
    required this.compressionDepth,
    required this.compressionCount,
    required this.tiltX,
    required this.tiltY,
  });

  @override
  String toString() {
    return 'SensorData(device: $deviceName, depth=${compressionDepth}mm, count=$compressionCount, tiltX=$tiltX°, tiltY=$tiltY°)';
  }
}

class RawSensorData {
  final DateTime timestamp;
  final Uint8List rawBytes;
  final int length;
  final String deviceId;
  final String deviceName;

  const RawSensorData({
    required this.timestamp,
    required this.rawBytes,
    required this.length,
    required this.deviceId,
    required this.deviceName,
  });

  String get hexString {
    return rawBytes
        .take(length > 32 ? 32 : length)
        .map((b) => '0x${b.toRadixString(16).padLeft(2, '0').toUpperCase()}')
        .join(' ');
  }

  String get asciiString {
    return String.fromCharCodes(rawBytes.take(length));
  }

  @override
  String toString() {
    return 'RawSensorData(device: $deviceName, length=$length, ascii="$asciiString")';
  }
}

// New class for device connection events
class DeviceConnectionEvent {
  final String deviceId;
  final String deviceName;
  final bool isConnected;

  const DeviceConnectionEvent({
    required this.deviceId,
    required this.deviceName,
    required this.isConnected,
  });
}