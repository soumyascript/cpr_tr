// //cpr_training_app/lib/services/sensor_service.dart
// import 'dart:async';
// //import 'dart:typed_data';
// import 'package:flutter/foundation.dart';
// import 'package:flutter_blue_plus/flutter_blue_plus.dart';
//
// class SensorService {
//   // BLE Configuration - matches your ESP32 setup
//   static const String serviceUuid = "12345678-1234-1234-1234-123456789abc";
//   static const String characteristicUuid =
//       "12345678-1234-1234-1234-123456789abc";
//   static const String deviceNamePrefix = "CPR-";
//
//   // Connection state
//   BluetoothDevice? _connectedDevice;
//   StreamSubscription<List<int>>? _characteristicSubscription;
//
//   bool _isConnected = false;
//   bool _isConnecting = false;
//   bool _isScanning = false;
//
//   // Data streams
//   final _connectionStatusController = StreamController<String>.broadcast();
//   final _sensorDataController = StreamController<SensorData>.broadcast();
//   final _rawDataController = StreamController<RawSensorData>.broadcast();
//
//   // Available devices
//   final List<BluetoothDevice> _availableDevices = [];
//
//   // Getters
//   bool get isConnected => _isConnected;
//   bool get isConnecting => _isConnecting;
//   bool get isScanning => _isScanning;
//   String? get connectedDeviceName => _connectedDevice?.platformName;
//   String? get connectedDeviceAddress => _connectedDevice?.remoteId.toString();
//   List<BluetoothDevice> get availableDevices =>
//       List.unmodifiable(_availableDevices);
//
//   // Streams
//   Stream<String> get connectionStatusStream =>
//       _connectionStatusController.stream;
//   Stream<SensorData> get sensorDataStream => _sensorDataController.stream;
//   Stream<RawSensorData> get rawDataStream => _rawDataController.stream;
//
//   // Initialize the service
//   Future<void> initialize() async {
//     debugPrint('Initializing SensorService...');
//
//     // Listen to FlutterBluePlus adapter state
//     FlutterBluePlus.adapterState.listen((BluetoothAdapterState state) {
//       switch (state) {
//         case BluetoothAdapterState.off:
//           _updateConnectionStatus('Bluetooth is turned off');
//           if (_isConnected) {
//             disconnect();
//           }
//           break;
//         case BluetoothAdapterState.on:
//           _updateConnectionStatus('Bluetooth ready - Tap Connect to start');
//           break;
//         default:
//           _updateConnectionStatus('Bluetooth state: ${state.name}');
//           break;
//       }
//     });
//
//     _updateConnectionStatus('Sensor service initialized');
//   }
//
//   // Start scanning for CPR devices
//   Future<void> startScan({
//     Duration timeout = const Duration(seconds: 10),
//   }) async {
//     if (_isScanning || _isConnecting) return;
//
//     _isScanning = true;
//     _availableDevices.clear();
//     _updateConnectionStatus('Scanning for CPR devices...');
//
//     try {
//       // Check if Bluetooth is supported and enabled
//       if (await FlutterBluePlus.isSupported == false) {
//         throw Exception('Bluetooth not supported on this device');
//       }
//
//       final adapterState = await FlutterBluePlus.adapterState.first;
//       if (adapterState != BluetoothAdapterState.on) {
//         throw Exception('Bluetooth is not enabled');
//       }
//
//       // Start scanning
//       await FlutterBluePlus.startScan(
//         timeout: timeout,
//         androidUsesFineLocation: false,
//       );
//
//       // Listen to scan results
//       final scanSubscription = FlutterBluePlus.scanResults.listen((
//         List<ScanResult> results,
//       ) {
//         for (ScanResult result in results) {
//           final device = result.device;
//           final deviceName = device.platformName;
//
//           // Filter for CPR devices and avoid duplicates
//           if (deviceName.startsWith(deviceNamePrefix) &&
//               !_availableDevices.any((d) => d.remoteId == device.remoteId)) {
//             _availableDevices.add(device);
//             debugPrint('Found CPR device: $deviceName (${device.remoteId})');
//           }
//         }
//       });
//
//       // Wait for scan to complete
//       await FlutterBluePlus.isScanning.where((scanning) => !scanning).first;
//
//       await scanSubscription.cancel();
//
//       _updateConnectionStatus(
//         _availableDevices.isEmpty
//             ? 'No CPR devices found'
//             : 'Found ${_availableDevices.length} CPR device(s)',
//       );
//     } catch (e) {
//       debugPrint('Scan error: $e');
//       _updateConnectionStatus('Scan failed: ${e.toString()}');
//     } finally {
//       _isScanning = false;
//     }
//   }
//
//   // Connect to a specific device
//   Future<void> connectToDevice(BluetoothDevice device) async {
//     if (_isConnecting || _isConnected) return;
//
//     _isConnecting = true;
//     _updateConnectionStatus('Connecting to ${device.platformName}...');
//
//     try {
//       // Connect to device with timeout
//       await device.connect(autoConnect: false).timeout(
//         const Duration(seconds: 15),
//         onTimeout: () {
//           throw TimeoutException(
//             'Connection timeout',
//             const Duration(seconds: 15),
//           );
//         },
//       );
//
//       debugPrint('Connected to ${device.platformName}');
//
//       // Discover services
//       final services = await device.discoverServices();
//       debugPrint('Discovered ${services.length} services');
//
//       // Find the CPR service
//       BluetoothService? cprService;
//       for (var service in services) {
//         if (service.uuid.toString().toLowerCase() ==
//             serviceUuid.toLowerCase()) {
//           cprService = service;
//           break;
//         }
//       }
//
//       if (cprService == null) {
//         throw Exception(
//           'CPR service not found. Make sure the ESP32 firmware is correct.',
//         );
//       }
//
//       debugPrint('Found CPR service: ${cprService.uuid}');
//
//       // Find the data characteristic
//       BluetoothCharacteristic? dataCharacteristic;
//       for (var characteristic in cprService.characteristics) {
//         if (characteristic.uuid.toString().toLowerCase() ==
//             characteristicUuid.toLowerCase()) {
//           dataCharacteristic = characteristic;
//           break;
//         }
//       }
//
//       if (dataCharacteristic == null) {
//         throw Exception('CPR data characteristic not found');
//       }
//
//       debugPrint('Found data characteristic: ${dataCharacteristic.uuid}');
//
//       // Check if characteristic supports notifications
//       if (!dataCharacteristic.properties.notify) {
//         throw Exception('Data characteristic does not support notifications');
//       }
//
//       // Enable notifications
//       await dataCharacteristic.setNotifyValue(true);
//       debugPrint('Notifications enabled');
//
//       // Subscribe to data stream
//       _characteristicSubscription = dataCharacteristic.onValueReceived.listen(
//         _handleSensorData,
//         onError: (error) {
//           debugPrint('Characteristic subscription error: $error');
//           disconnect();
//         },
//       );
//
//       // Update connection state
//       _connectedDevice = device;
//       _isConnected = true;
//       _updateConnectionStatus('Connected to ${device.platformName}');
//
//       debugPrint(
//         'Successfully connected and subscribed to ${device.platformName}',
//       );
//     } catch (e) {
//       debugPrint('Connection failed: $e');
//       _updateConnectionStatus('Connection failed: ${e.toString()}');
//
//       // Clean up on failure
//       try {
//         await device.disconnect();
//       } catch (disconnectError) {
//         debugPrint('Error during cleanup disconnect: $disconnectError');
//       }
//     } finally {
//       _isConnecting = false;
//     }
//   }
//
//   // Disconnect from current device
//   Future<void> disconnect() async {
//     try {
//       // Cancel characteristic subscription
//       await _characteristicSubscription?.cancel();
//       _characteristicSubscription = null;
//
//       // Disconnect device
//       if (_connectedDevice != null) {
//         await _connectedDevice!.disconnect();
//         debugPrint('Disconnected from ${_connectedDevice!.platformName}');
//       }
//     } catch (e) {
//       debugPrint('Disconnect error: $e');
//     } finally {
//       // Reset state
//       _connectedDevice = null;
//       _isConnected = false;
//       _isConnecting = false;
//       _updateConnectionStatus('Disconnected');
//     }
//   }
//
//   // Handle incoming sensor data
//   void _handleSensorData(List<int> data) {
//     try {
//       // Create raw data object for debugging
//       final rawData = RawSensorData(
//         timestamp: DateTime.now(),
//         rawBytes: Uint8List.fromList(data),
//         length: data.length,
//       );
//       _rawDataController.add(rawData);
//
//       // Parse the data according to ESP32 protocol
//       if (data.length >= 8) {
//         final bytes = Uint8List.fromList(data);
//         final buffer = ByteData.sublistView(bytes);
//
//         // Extract values (little-endian format)
//         final timestamp = buffer.getUint32(0, Endian.little);
//         final sensor1Value = buffer.getUint16(4, Endian.little);
//         final sensor2Value = buffer.getUint16(6, Endian.little);
//
//         // Create sensor data object
//         final sensorData = SensorData(
//           timestamp: DateTime.now(),
//           espTimestamp: timestamp,
//           sensor1Raw: sensor1Value,
//           sensor2Raw: sensor2Value,
//         );
//
//         _sensorDataController.add(sensorData);
//
//         debugPrint(
//           'Sensor data: t=${timestamp}ms, s1=$sensor1Value, s2=$sensor2Value',
//         );
//       } else {
//         debugPrint('Invalid data length: ${data.length} bytes (expected 8)');
//       }
//     } catch (e) {
//       debugPrint('Error parsing sensor data: $e');
//     }
//   }
//
//   // Update connection status
//   void _updateConnectionStatus(String status) {
//     debugPrint('Connection status: $status');
//     _connectionStatusController.add(status);
//   }
//
//   // Get first available device (for auto-connect)
//   BluetoothDevice? getFirstAvailableDevice() {
//     return _availableDevices.isNotEmpty ? _availableDevices.first : null;
//   }
//
//   // Auto-connect to first available device
//   Future<void> autoConnect() async {
//     if (_isConnected || _isConnecting) return;
//
//     await startScan();
//
//     final device = getFirstAvailableDevice();
//     if (device != null) {
//       await connectToDevice(device);
//     } else {
//       _updateConnectionStatus('No CPR devices found for auto-connect');
//     }
//   }
//
//   // Dispose resources
//   void dispose() {
//     debugPrint('Disposing SensorService...');
//
//     disconnect();
//     _connectionStatusController.close();
//     _sensorDataController.close();
//     _rawDataController.close();
//   }
// }
//
// // Data models for sensor information
// class SensorData {
//   final DateTime timestamp;
//   final int espTimestamp;
//   final int sensor1Raw;
//   final int sensor2Raw;
//
//   const SensorData({
//     required this.timestamp,
//     required this.espTimestamp,
//     required this.sensor1Raw,
//     required this.sensor2Raw,
//   });
//
//   // Format elapsed time like in your example
//   String get formattedElapsedTime {
//     final totalSeconds = espTimestamp ~/ 1000;
//     final hours = totalSeconds ~/ 3600;
//     final minutes = (totalSeconds % 3600) ~/ 60;
//     final seconds = totalSeconds % 60;
//     final ms = espTimestamp % 1000;
//
//     if (hours > 0) {
//       return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
//     } else if (minutes > 0) {
//       return '$minutes:${seconds.toString().padLeft(2, '0')}.${ms.toString().padLeft(3, '0')}';
//     } else {
//       return '$seconds.${ms.toString().padLeft(3, '0')}s';
//     }
//   }
//
//   @override
//   String toString() {
//     return 'SensorData(t=$espTimestamp, s1=$sensor1Raw, s2=$sensor2Raw)';
//   }
// }
//
// class RawSensorData {
//   final DateTime timestamp;
//   final Uint8List rawBytes;
//   final int length;
//
//   const RawSensorData({
//     required this.timestamp,
//     required this.rawBytes,
//     required this.length,
//   });
//
//   String get hexString {
//     return rawBytes
//         .take(8)
//         .map((b) => '0x${b.toRadixString(16).padLeft(2, '0').toUpperCase()}')
//         .join(' ');
//   }
//
//   String get binaryString {
//     return rawBytes
//         .take(8)
//         .map((b) => 'b${b.toRadixString(2).padLeft(8, '0')}')
//         .join(' ');
//   }
//
//   String get decimalString {
//     return '[${rawBytes.take(8).join(', ')}]';
//   }
//
//   @override
//   String toString() {
//     return 'RawSensorData(length=$length, hex=$hexString)';
//   }
// }





//cpr_training_app/lib/services/sensor_service.dart
// import 'dart:async';
// import 'package:flutter/foundation.dart';
// import 'package:flutter_blue_plus/flutter_blue_plus.dart';
//
// class SensorService {
//   // BLE Configuration - matches your ESP32 setup
//   static const String serviceUuid = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
//   static const String characteristicUuid = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
//   static const String deviceNamePrefix = "CPR_Monitor";
//
//   // Connection state
//   BluetoothDevice? _connectedDevice;
//   StreamSubscription<List<int>>? _characteristicSubscription;
//
//   bool _isConnected = false;
//   bool _isConnecting = false;
//   bool _isScanning = false;
//
//   // Data streams
//   final _connectionStatusController = StreamController<String>.broadcast();
//   final _sensorDataController = StreamController<SensorData>.broadcast();
//   final _rawDataController = StreamController<RawSensorData>.broadcast();
//
//   // Available devices
//   final List<BluetoothDevice> _availableDevices = [];
//
//   // Getters
//   bool get isConnected => _isConnected;
//   bool get isConnecting => _isConnecting;
//   bool get isScanning => _isScanning;
//   String? get connectedDeviceName => _connectedDevice?.platformName;
//   String? get connectedDeviceAddress => _connectedDevice?.remoteId.toString();
//   List<BluetoothDevice> get availableDevices =>
//       List.unmodifiable(_availableDevices);
//
//   // Streams
//   Stream<String> get connectionStatusStream =>
//       _connectionStatusController.stream;
//   Stream<SensorData> get sensorDataStream => _sensorDataController.stream;
//   Stream<RawSensorData> get rawDataStream => _rawDataController.stream;
//
//   // Initialize the service
//   Future<void> initialize() async {
//     debugPrint('Initializing SensorService...');
//
//     // Listen to FlutterBluePlus adapter state
//     FlutterBluePlus.adapterState.listen((BluetoothAdapterState state) {
//       switch (state) {
//         case BluetoothAdapterState.off:
//           _updateConnectionStatus('Bluetooth is turned off');
//           if (_isConnected) {
//             disconnect();
//           }
//           break;
//         case BluetoothAdapterState.on:
//           _updateConnectionStatus('Bluetooth ready - Tap Connect to start');
//           break;
//         default:
//           _updateConnectionStatus('Bluetooth state: ${state.name}');
//           break;
//       }
//     });
//
//     _updateConnectionStatus('Sensor service initialized');
//   }
//
//   // Start scanning for CPR devices
//   Future<void> startScan({
//     Duration timeout = const Duration(seconds: 10),
//   }) async {
//     if (_isScanning || _isConnecting) return;
//
//     _isScanning = true;
//     _availableDevices.clear();
//     _updateConnectionStatus('Scanning for CPR devices...');
//
//     try {
//       // Check if Bluetooth is supported and enabled
//       if (await FlutterBluePlus.isSupported == false) {
//         throw Exception('Bluetooth not supported on this device');
//       }
//
//       final adapterState = await FlutterBluePlus.adapterState.first;
//       if (adapterState != BluetoothAdapterState.on) {
//         throw Exception('Bluetooth is not enabled');
//       }
//
//       // Start scanning
//       await FlutterBluePlus.startScan(
//         timeout: timeout,
//         androidUsesFineLocation: false,
//       );
//
//       // Listen to scan results
//       final scanSubscription = FlutterBluePlus.scanResults.listen((
//           List<ScanResult> results,
//           ) {
//         for (ScanResult result in results) {
//           final device = result.device;
//           final deviceName = device.platformName;
//
//           // Filter for CPR devices and avoid duplicates
//           if (deviceName.startsWith(deviceNamePrefix) &&
//               !_availableDevices.any((d) => d.remoteId == device.remoteId)) {
//             _availableDevices.add(device);
//             debugPrint('Found CPR device: $deviceName (${device.remoteId})');
//           }
//         }
//       });
//
//       // Wait for scan to complete
//       await FlutterBluePlus.isScanning.where((scanning) => !scanning).first;
//
//       await scanSubscription.cancel();
//
//       _updateConnectionStatus(
//         _availableDevices.isEmpty
//             ? 'No CPR devices found'
//             : 'Found ${_availableDevices.length} CPR device(s)',
//       );
//     } catch (e) {
//       debugPrint('Scan error: $e');
//       _updateConnectionStatus('Scan failed: ${e.toString()}');
//     } finally {
//       _isScanning = false;
//     }
//   }
//
//   // Connect to a specific device
//   Future<void> connectToDevice(BluetoothDevice device) async {
//     if (_isConnecting || _isConnected) return;
//
//     _isConnecting = true;
//     _updateConnectionStatus('Connecting to ${device.platformName}...');
//
//     try {
//       // Connect to device with timeout
//       await device.connect(autoConnect: false).timeout(
//         const Duration(seconds: 15),
//         onTimeout: () {
//           throw TimeoutException(
//             'Connection timeout',
//             const Duration(seconds: 15),
//           );
//         },
//       );
//
//       debugPrint('Connected to ${device.platformName}');
//
//       // Discover services
//       final services = await device.discoverServices();
//       debugPrint('Discovered ${services.length} services');
//
//       // Find the CPR service
//       BluetoothService? cprService;
//       for (var service in services) {
//         if (service.uuid.toString().toLowerCase() ==
//             serviceUuid.toLowerCase()) {
//           cprService = service;
//           break;
//         }
//       }
//
//       if (cprService == null) {
//         throw Exception(
//           'CPR service not found. Make sure the ESP32 firmware is correct.',
//         );
//       }
//
//       debugPrint('Found CPR service: ${cprService.uuid}');
//
//       // Find the data characteristic
//       BluetoothCharacteristic? dataCharacteristic;
//       for (var characteristic in cprService.characteristics) {
//         if (characteristic.uuid.toString().toLowerCase() ==
//             characteristicUuid.toLowerCase()) {
//           dataCharacteristic = characteristic;
//           break;
//         }
//       }
//
//       if (dataCharacteristic == null) {
//         throw Exception('CPR data characteristic not found');
//       }
//
//       debugPrint('Found data characteristic: ${dataCharacteristic.uuid}');
//
//       // Check if characteristic supports notifications
//       if (!dataCharacteristic.properties.notify) {
//         throw Exception('Data characteristic does not support notifications');
//       }
//
//       // Enable notifications
//       await dataCharacteristic.setNotifyValue(true);
//       debugPrint('Notifications enabled');
//
//       // Subscribe to data stream
//       _characteristicSubscription = dataCharacteristic.onValueReceived.listen(
//         _handleSensorData,
//         onError: (error) {
//           debugPrint('Characteristic subscription error: $error');
//           disconnect();
//         },
//       );
//
//       // Update connection state
//       _connectedDevice = device;
//       _isConnected = true;
//       _updateConnectionStatus('Connected to ${device.platformName}');
//
//       debugPrint(
//         'Successfully connected and subscribed to ${device.platformName}',
//       );
//     } catch (e) {
//       debugPrint('Connection failed: $e');
//       _updateConnectionStatus('Connection failed: ${e.toString()}');
//
//       // Clean up on failure
//       try {
//         await device.disconnect();
//       } catch (disconnectError) {
//         debugPrint('Error during cleanup disconnect: $disconnectError');
//       }
//     } finally {
//       _isConnecting = false;
//     }
//   }
//
//   // Disconnect from current device
//   Future<void> disconnect() async {
//     try {
//       // Cancel characteristic subscription
//       await _characteristicSubscription?.cancel();
//       _characteristicSubscription = null;
//
//       // Disconnect device
//       if (_connectedDevice != null) {
//         await _connectedDevice!.disconnect();
//         debugPrint('Disconnected from ${_connectedDevice!.platformName}');
//       }
//     } catch (e) {
//       debugPrint('Disconnect error: $e');
//     } finally {
//       // Reset state
//       _connectedDevice = null;
//       _isConnected = false;
//       _isConnecting = false;
//       _updateConnectionStatus('Disconnected');
//     }
//   }
//
//   // Handle incoming sensor data - UPDATED FOR NEW FORMAT
//   void _handleSensorData(List<int> data) {
//     try {
//       // Convert bytes to string
//       final dataString = String.fromCharCodes(data).trim();
//
//       // Create raw data object for debugging
//       final rawData = RawSensorData(
//         timestamp: DateTime.now(),
//         rawBytes: Uint8List.fromList(data),
//         length: data.length,
//       );
//       _rawDataController.add(rawData);
//
//       debugPrint('Received BLE data: $dataString');
//
//       // Parse CSV format: Depth,Count,TiltX,TiltY
//       final parts = dataString.split(',');
//
//       if (parts.length >= 4) {
//         try {
//           final depth = double.parse(parts[0]);
//           final count = int.parse(parts[1]);
//           final tiltX = double.parse(parts[2]);
//           final tiltY = double.parse(parts[3]);
//
//           // Create sensor data object
//           final sensorData = SensorData(
//             timestamp: DateTime.now(),
//             espTimestamp: 0, // Not provided by ESP32 anymore
//             sensor1Raw: depth.toInt(), // Use depth as sensor1
//             sensor2Raw: 0, // Not used anymore
//             compressionDepth: depth,
//             compressionCount: count,
//             tiltX: tiltX,
//             tiltY: tiltY,
//           );
//
//           _sensorDataController.add(sensorData);
//
//           debugPrint(
//             'Parsed: Depth=${depth}mm, Count=$count, TiltX=$tiltX°, TiltY=$tiltY°',
//           );
//         } catch (parseError) {
//           debugPrint('Error parsing values: $parseError');
//         }
//       } else {
//         debugPrint('Invalid data format: expected 4 values, got ${parts.length}');
//       }
//     } catch (e) {
//       debugPrint('Error handling sensor data: $e');
//     }
//   }
//
//   // Update connection status
//   void _updateConnectionStatus(String status) {
//     debugPrint('Connection status: $status');
//     _connectionStatusController.add(status);
//   }
//
//   // Get first available device (for auto-connect)
//   BluetoothDevice? getFirstAvailableDevice() {
//     return _availableDevices.isNotEmpty ? _availableDevices.first : null;
//   }
//
//   // Auto-connect to first available device
//   Future<void> autoConnect() async {
//     if (_isConnected || _isConnecting) return;
//
//     await startScan();
//
//     final device = getFirstAvailableDevice();
//     if (device != null) {
//       await connectToDevice(device);
//     } else {
//       _updateConnectionStatus('No CPR devices found for auto-connect');
//     }
//   }
//
//   // Dispose resources
//   void dispose() {
//     debugPrint('Disposing SensorService...');
//
//     disconnect();
//     _connectionStatusController.close();
//     _sensorDataController.close();
//     _rawDataController.close();
//   }
// }
//
// // Data models for sensor information - UPDATED
// class SensorData {
//   final DateTime timestamp;
//   final int espTimestamp;
//   final int sensor1Raw;
//   final int sensor2Raw;
//   final double compressionDepth; // NEW: depth in mm
//   final int compressionCount; // NEW: compression count
//   final double tiltX; // NEW: tilt angle X
//   final double tiltY; // NEW: tilt angle Y
//
//   const SensorData({
//     required this.timestamp,
//     required this.espTimestamp,
//     required this.sensor1Raw,
//     required this.sensor2Raw,
//     this.compressionDepth = 0.0,
//     this.compressionCount = 0,
//     this.tiltX = 0.0,
//     this.tiltY = 0.0,
//   });
//
//   // Format elapsed time
//   String get formattedElapsedTime {
//     final totalSeconds = espTimestamp ~/ 1000;
//     final hours = totalSeconds ~/ 3600;
//     final minutes = (totalSeconds % 3600) ~/ 60;
//     final seconds = totalSeconds % 60;
//     final ms = espTimestamp % 1000;
//
//     if (hours > 0) {
//       return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
//     } else if (minutes > 0) {
//       return '$minutes:${seconds.toString().padLeft(2, '0')}.${ms.toString().padLeft(3, '0')}';
//     } else {
//       return '$seconds.${ms.toString().padLeft(3, '0')}s';
//     }
//   }
//
//   @override
//   String toString() {
//     return 'SensorData(depth=${compressionDepth}mm, count=$compressionCount, tiltX=$tiltX°, tiltY=$tiltY°)';
//   }
// }
//
// class RawSensorData {
//   final DateTime timestamp;
//   final Uint8List rawBytes;
//   final int length;
//
//   const RawSensorData({
//     required this.timestamp,
//     required this.rawBytes,
//     required this.length,
//   });
//
//   String get hexString {
//     return rawBytes
//         .take(length > 32 ? 32 : length)
//         .map((b) => '0x${b.toRadixString(16).padLeft(2, '0').toUpperCase()}')
//         .join(' ');
//   }
//
//   String get asciiString {
//     return String.fromCharCodes(rawBytes.take(length));
//   }
//
//   @override
//   String toString() {
//     return 'RawSensorData(length=$length, ascii="$asciiString")';
//   }
// }

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

  // Connection state
  BluetoothDevice? _connectedDevice;
  StreamSubscription<List<int>>? _characteristicSubscription;

  bool _isConnected = false;
  bool _isConnecting = false;
  bool _isScanning = false;

  // Data streams
  final _connectionStatusController = StreamController<String>.broadcast();
  final _sensorDataController = StreamController<SensorData>.broadcast();
  final _rawDataController = StreamController<RawSensorData>.broadcast();

  // Available devices
  final List<BluetoothDevice> _availableDevices = [];

  // Getters
  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  bool get isScanning => _isScanning;
  String? get connectedDeviceName => _connectedDevice?.platformName;
  String? get connectedDeviceAddress => _connectedDevice?.remoteId.toString();
  List<BluetoothDevice> get availableDevices =>
      List.unmodifiable(_availableDevices);

  // Streams
  Stream<String> get connectionStatusStream =>
      _connectionStatusController.stream;
  Stream<SensorData> get sensorDataStream => _sensorDataController.stream;
  Stream<RawSensorData> get rawDataStream => _rawDataController.stream;

  // Initialize the service
  Future<void> initialize() async {
    debugPrint('Initializing SensorService...');

    // Listen to FlutterBluePlus adapter state
    FlutterBluePlus.adapterState.listen((BluetoothAdapterState state) {
      switch (state) {
        case BluetoothAdapterState.off:
          _updateConnectionStatus('Bluetooth is turned off');
          if (_isConnected) {
            disconnect();
          }
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
          if (deviceName.startsWith(deviceNamePrefix) &&
              !_availableDevices.any((d) => d.remoteId == device.remoteId)) {
            _availableDevices.add(device);
            debugPrint('Found CPR device: $deviceName (${device.remoteId})');
          }
        }
      });

      // Wait for scan to complete
      await FlutterBluePlus.isScanning.where((scanning) => !scanning).first;

      await scanSubscription.cancel();

      _updateConnectionStatus(
        _availableDevices.isEmpty
            ? 'No CPR devices found'
            : 'Found ${_availableDevices.length} CPR device(s)',
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
    if (_isConnecting || _isConnected) return;

    _isConnecting = true;
    _updateConnectionStatus('Connecting to ${device.platformName}...');

    try {
      // Connect to device with timeout
      await device.connect(autoConnect: false).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException(
            'Connection timeout',
            const Duration(seconds: 15),
          );
        },
      );

      debugPrint('Connected to ${device.platformName}');

      // Discover services
      final services = await device.discoverServices();
      debugPrint('Discovered ${services.length} services');

      // Find the CPR service
      BluetoothService? cprService;
      for (var service in services) {
        if (service.uuid.toString().toLowerCase() ==
            serviceUuid.toLowerCase()) {
          cprService = service;
          break;
        }
      }

      if (cprService == null) {
        throw Exception(
          'CPR service not found. Make sure the ESP32 firmware is correct.',
        );
      }

      debugPrint('Found CPR service: ${cprService.uuid}');

      // Find the data characteristic
      BluetoothCharacteristic? dataCharacteristic;
      for (var characteristic in cprService.characteristics) {
        if (characteristic.uuid.toString().toLowerCase() ==
            characteristicUuid.toLowerCase()) {
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
      debugPrint('Notifications enabled');

      // Subscribe to data stream
      _characteristicSubscription = dataCharacteristic.onValueReceived.listen(
        _handleSensorData,
        onError: (error) {
          debugPrint('Characteristic subscription error: $error');
          disconnect();
        },
      );

      // Update connection state
      _connectedDevice = device;
      _isConnected = true;
      _updateConnectionStatus('Connected to ${device.platformName}');

      debugPrint(
        'Successfully connected and subscribed to ${device.platformName}',
      );
    } catch (e) {
      debugPrint('Connection failed: $e');
      _updateConnectionStatus('Connection failed: ${e.toString()}');

      // Clean up on failure
      try {
        await device.disconnect();
      } catch (disconnectError) {
        debugPrint('Error during cleanup disconnect: $disconnectError');
      }
    } finally {
      _isConnecting = false;
    }
  }

  // Disconnect from current device
  Future<void> disconnect() async {
    try {
      // Cancel characteristic subscription
      await _characteristicSubscription?.cancel();
      _characteristicSubscription = null;

      // Disconnect device
      if (_connectedDevice != null) {
        await _connectedDevice!.disconnect();
        debugPrint('Disconnected from ${_connectedDevice!.platformName}');
      }
    } catch (e) {
      debugPrint('Disconnect error: $e');
    } finally {
      // Reset state
      _connectedDevice = null;
      _isConnected = false;
      _isConnecting = false;
      _updateConnectionStatus('Disconnected');
    }
  }

  // Handle incoming sensor data - PARSES CSV FORMAT
  void _handleSensorData(List<int> data) {
    try {
      // Convert bytes to string - ESP32 sends CSV, not JSON
      final dataString = String.fromCharCodes(data).trim();

      // Create raw data object for debugging
      final rawData = RawSensorData(
        timestamp: DateTime.now(),
        rawBytes: Uint8List.fromList(data),
        length: data.length,
      );
      _rawDataController.add(rawData);

      debugPrint('Received BLE data: $dataString');

      // Parse CSV format: Depth,Count,TiltX,TiltY
      final parts = dataString.split(',');

      if (parts.length >= 4) {
        try {
          final depth = double.parse(parts[0]);
          final count = int.parse(parts[1]);
          final tiltX = double.parse(parts[2]);
          final tiltY = double.parse(parts[3]);

          // Create sensor data object
          final sensorData = SensorData(
            timestamp: DateTime.now(),
            compressionDepth: depth,
            compressionCount: count,
            tiltX: tiltX,
            tiltY: tiltY,
          );

          _sensorDataController.add(sensorData);

          debugPrint(
            'Parsed: Depth=${depth}mm, Count=$count, TiltX=$tiltX°, TiltY=$tiltY°',
          );
        } catch (parseError) {
          debugPrint('Error parsing values: $parseError');
        }
      } else {
        debugPrint('Invalid data format: expected 4 values, got ${parts.length}');
      }
    } catch (e) {
      debugPrint('Error handling sensor data: $e');
    }
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
    if (_isConnected || _isConnecting) return;

    await startScan();

    final device = getFirstAvailableDevice();
    if (device != null) {
      await connectToDevice(device);
    } else {
      _updateConnectionStatus('No CPR devices found for auto-connect');
    }
  }

  // Dispose resources
  void dispose() {
    debugPrint('Disposing SensorService...');

    disconnect();
    _connectionStatusController.close();
    _sensorDataController.close();
    _rawDataController.close();
  }
}

// Data models for sensor information
class SensorData {
  final DateTime timestamp;
  final double compressionDepth; // Depth in mm
  final int compressionCount; // Compression count
  final double tiltX; // Tilt angle X
  final double tiltY; // Tilt angle Y

  const SensorData({
    required this.timestamp,
    required this.compressionDepth,
    required this.compressionCount,
    required this.tiltX,
    required this.tiltY,
  });

  @override
  String toString() {
    return 'SensorData(depth=${compressionDepth}mm, count=$compressionCount, tiltX=$tiltX°, tiltY=$tiltY°)';
  }
}

class RawSensorData {
  final DateTime timestamp;
  final Uint8List rawBytes;
  final int length;

  const RawSensorData({
    required this.timestamp,
    required this.rawBytes,
    required this.length,
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
    return 'RawSensorData(length=$length, ascii="$asciiString")';
  }
}