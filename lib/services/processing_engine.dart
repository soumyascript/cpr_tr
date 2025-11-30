
// Dual BLE

//cpr_training_app/lib/services/processing_engine.dart
import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/sensor_service.dart'; // This imports SensorData

class ProcessingEngine {
  SystemConfig _config = const SystemConfig();

  // Enhanced buffer system for multiple devices
  final Map<String, Queue<SensorDataPoint>> _rawSensorBuffers = {};
  final Map<String, Queue<SensorDataPoint>> _filteredBuffers = {};

  // Compression tracking for multiple devices
  final Map<String, int> _lastDeviceCompressionCounts = {};
  final Map<String, double> _lastDeviceDepths = {};
  final Map<String, DateTime> _lastDeviceCompressionTimes = {};

  // Combined metrics from all devices
  int _totalCompressions = 0;
  int _totalRecoils = 0;
  int _goodCompressions = 0;
  int _goodRecoils = 0;
  int _cycleCount = 0;
  DateTime? _cycleStartTime;

  // Combined compression rate calculation
  final _compressionTimestamps = Queue<DateTime>();
  double? _currentCompressionRate;

  // Phase tracking
  CPRPhase _currentPhase = CPRPhase.quietude;
  DateTime _phaseStartTime = DateTime.now();
  int _consecutiveQuietSamples = 0;
  DateTime? _lastSignificantDepthChange;

  // CCF calculation state
  DateTime? _sessionStartTime;
  Duration _totalActiveTime = Duration.zero;
  DateTime? _activePhaseStartTime;
  double? _lastCalculatedCCF;
  bool _isSessionActive = false;

  // Pressure state
  bool _pressureActive = false;
  bool get isPressureActive => _pressureActive;

  // Stream controllers
  final _metricsController = StreamController<CPRMetrics>.broadcast();
  final _alertController = StreamController<CPRAlert>.broadcast();
  final _phaseChangeController = StreamController<PhaseChangeEvent>.broadcast();
  final _peakDetectionController = StreamController<PeakTroughEvent>.broadcast();
  final _multiDeviceController = StreamController<MultiDeviceData>.broadcast();

  Stream<CPRMetrics> get metricsStream => _metricsController.stream;
  Stream<CPRAlert> get alertStream => _alertController.stream;
  Stream<PhaseChangeEvent> get phaseChangeStream => _phaseChangeController.stream;
  Stream<PeakTroughEvent> get peakDetectionStream => _peakDetectionController.stream;
  Stream<MultiDeviceData> get multiDeviceStream => _multiDeviceController.stream;

  CPRPhase get currentPhase => _currentPhase;
  int get cycleCount => _cycleCount;
  double? get compressionRate => _currentCompressionRate;

  /// Update configuration
  void updateConfig(SystemConfig config) {
    _config = config;
    debugPrint('ProcessingEngine config updated');
  }

  /// Set session state for CCF calculation
  void setSessionState(bool isActive, {DateTime? sessionStartTime}) {
    _isSessionActive = isActive;
    if (isActive && sessionStartTime != null) {
      _sessionStartTime = sessionStartTime;
      _totalActiveTime = Duration.zero;
      _activePhaseStartTime = null;
      _lastCalculatedCCF = null;
    } else if (!isActive) {
      _finalizeActiveTime();
      _sessionStartTime = null;
      _isSessionActive = false;
    }
    debugPrint('Session state updated: active=$isActive');
  }

  /// Set pressure state - only process data when pressure is active
  void setPressureState(bool isActive) {
    final wasActive = _pressureActive;
    _pressureActive = isActive;

    if (!isActive && wasActive) {
      // Pressure became inactive - reset temporary metrics
      _resetTemporaryMetrics();
    }

    debugPrint('Pressure state updated: active=$isActive (was: $wasActive)');
  }

  /// Process sensor data from multiple ESP32 devices SIMULTANEOUSLY
  void processSensorDataFromDevice(SensorData sensorData) {
    // Only process data when pressure is active
    if (!_pressureActive) {
      debugPrint('Pressure not active - ignoring sensor data from ${sensorData.deviceName}');
      return;
    }

    final deviceId = sensorData.deviceId;
    final deviceName = sensorData.deviceName;
    final depth = sensorData.compressionDepth;
    final count = sensorData.compressionCount;
    final tiltX = sensorData.tiltX;
    final tiltY = sensorData.tiltY;
    final timestamp = sensorData.timestamp;

    // Initialize buffers for new devices
    if (!_rawSensorBuffers.containsKey(deviceId)) {
      _rawSensorBuffers[deviceId] = Queue<SensorDataPoint>();
      _filteredBuffers[deviceId] = Queue<SensorDataPoint>();
      _lastDeviceCompressionCounts[deviceId] = 0;
      _lastDeviceDepths[deviceId] = 0.0;
      _lastDeviceCompressionTimes[deviceId] = timestamp;
      debugPrint('Initialized processing for device: $deviceName');
    }

    // Store device data
    _rawSensorBuffers[deviceId]!.add(SensorDataPoint(timestamp, depth));
    if (_rawSensorBuffers[deviceId]!.length > 500) {
      _rawSensorBuffers[deviceId]!.removeFirst();
    }

    // Apply filtering
    final filtered = _applyFilter(depth, deviceId);
    _filteredBuffers[deviceId]!.add(SensorDataPoint(timestamp, filtered));
    if (_filteredBuffers[deviceId]!.length > 250) {
      _filteredBuffers[deviceId]!.removeFirst();
    }

    // Detect new compression from ANY device
    final lastCount = _lastDeviceCompressionCounts[deviceId] ?? 0;
    if (count > lastCount) {
      _recordNewCompression(timestamp, depth, deviceId, deviceName);
      _lastDeviceCompressionCounts[deviceId] = count;
      _lastDeviceCompressionTimes[deviceId] = timestamp;
    }

    // Update device depth
    _lastDeviceDepths[deviceId] = depth;

    // Calculate combined depth from all active devices
    final combinedDepth = _calculateCombinedDepth();

    // Update phase based on combined activity
    _updatePhaseFromDepth(timestamp, combinedDepth);

    // Emit multi-device data
    _emitMultiDeviceData();

    // Emit current metrics
    _emitMetrics();

    debugPrint('Processed data from $deviceName: depth=$depth, count=$count, combinedDepth=$combinedDepth');
  }

  /// Calculate combined depth from all active devices
  double _calculateCombinedDepth() {
    if (_lastDeviceDepths.isEmpty) return 0.0;

    // Use the maximum depth from any device (most active compression)
    double maxDepth = 0.0;
    for (final depth in _lastDeviceDepths.values) {
      if (depth > maxDepth) {
        maxDepth = depth;
      }
    }
    return maxDepth;
  }

  /// Apply simple moving average filter per device
  double _applyFilter(double rawValue, String deviceId) {
    final buffer = _rawSensorBuffers[deviceId]!;
    if (buffer.length < 3) return rawValue;

    // Simple moving average of last 3 values
    final recentValues = buffer.toList().reversed.take(3).toList();
    return recentValues.map((point) => point.value).reduce((a, b) => a + b) / recentValues.length;
  }

  /// Record a new compression from any device
  void _recordNewCompression(DateTime timestamp, double depth, String deviceId, String deviceName) {
    _totalCompressions++;

    final isGood = _isGoodCompression(depth);
    if (isGood) {
      _goodCompressions++;
    }

    // Add to combined compression timestamps for rate calculation
    _compressionTimestamps.add(timestamp);
    if (_compressionTimestamps.length > 10) {
      _compressionTimestamps.removeFirst();
    }

    // Update combined compression rate
    _updateCompressionRate();

    final peak = PeakTrough(
      timestamp: timestamp,
      value: depth,
      type: PeakTroughType.compressionPeak,
      isGood: isGood,
      deviceId: deviceId,
      deviceName: deviceName,
    );

    _peakDetectionController.add(PeakTroughEvent(peak: peak));
    _checkCompressionAlerts(depth);

    debugPrint(
        'Compression #$_totalCompressions from $deviceName: ${depth.toStringAsFixed(1)}mm (${isGood ? "Good" : "Bad"}) - Combined Rate: ${_currentCompressionRate?.toStringAsFixed(1) ?? "N/A"}/min');
  }

  /// Check if compression depth is good (50-60mm typically)
  bool _isGoodCompression(double depth) {
    return depth >= 50.0 && depth <= 60.0;
  }

  /// Update phase based on combined depth from all devices
  void _updatePhaseFromDepth(DateTime timestamp, double combinedDepth) {
    CPRPhase newPhase;

    // FIXED: Better phase detection logic using combined data
    if (combinedDepth < 5.0) {
      // No significant compression from any device - quietude or pause
      _consecutiveQuietSamples++;
      if (_consecutiveQuietSamples > 50) { // ~500ms at 100Hz
        newPhase = CPRPhase.pause;
      } else {
        newPhase = CPRPhase.quietude;
      }
    } else {
      // Active compression detected from at least one device
      _consecutiveQuietSamples = 0;

      // Detect phase based on depth change
      final lastCombinedDepth = _getLastCombinedDepth();
      final depthChange = combinedDepth - lastCombinedDepth;

      if (depthChange.abs() > 2.0) { // 2mm threshold for detecting movement
        if (depthChange > 0) {
          newPhase = CPRPhase.compression;
        } else {
          newPhase = CPRPhase.recoil;
        }
      } else {
        // Keep current phase if no significant change
        newPhase = _currentPhase;

        // But default to compression if we have significant depth
        if (combinedDepth > 20.0 && (_currentPhase == CPRPhase.quietude || _currentPhase == CPRPhase.pause)) {
          newPhase = CPRPhase.compression;
        }
      }
    }

    if (newPhase != _currentPhase) {
      _transitionToPhase(newPhase, timestamp, combinedDepth);
    }
  }

  /// Get last combined depth for change detection
  double _getLastCombinedDepth() {
    if (_filteredBuffers.isEmpty) return 0.0;

    double lastDepth = 0.0;
    for (final buffer in _filteredBuffers.values) {
      if (buffer.isNotEmpty) {
        final deviceDepth = buffer.last.value;
        if (deviceDepth > lastDepth) {
          lastDepth = deviceDepth;
        }
      }
    }
    return lastDepth;
  }

  /// Handle phase transitions
  void _transitionToPhase(CPRPhase newPhase, DateTime timestamp, double depth) {
    final previousPhase = _currentPhase;

    _updateActiveTimeTracking(previousPhase, newPhase, timestamp);

    if (previousPhase == CPRPhase.quietude && newPhase == CPRPhase.pause) {
      _endCycle(timestamp);
    }

    _currentPhase = newPhase;

    if (!(previousPhase == CPRPhase.quietude && newPhase == CPRPhase.pause)) {
      _phaseStartTime = timestamp;
    }

    _phaseChangeController.add(PhaseChangeEvent(
      timestamp: timestamp,
      fromPhase: previousPhase,
      toPhase: newPhase,
      value: depth,
    ));

    debugPrint('Phase: ${previousPhase.name} -> ${newPhase.name} (combined depth: ${depth.toStringAsFixed(1)}mm)');
  }

  /// Update active time tracking for CCF calculation
  void _updateActiveTimeTracking(CPRPhase fromPhase, CPRPhase toPhase, DateTime timestamp) {
    if (!_isSessionActive || _sessionStartTime == null) return;

    if ((fromPhase == CPRPhase.compression || fromPhase == CPRPhase.recoil) &&
        _activePhaseStartTime != null) {
      final activePhaseDuration = timestamp.difference(_activePhaseStartTime!);
      _totalActiveTime += activePhaseDuration;
      _activePhaseStartTime = null;
    }

    if (toPhase == CPRPhase.compression || toPhase == CPRPhase.recoil) {
      _activePhaseStartTime = timestamp;
    }
  }

  /// Finalize active time calculation
  void _finalizeActiveTime() {
    if (!_isSessionActive || _sessionStartTime == null) return;

    final now = DateTime.now();

    if ((_currentPhase == CPRPhase.compression || _currentPhase == CPRPhase.recoil) &&
        _activePhaseStartTime != null) {
      final currentActiveDuration = now.difference(_activePhaseStartTime!);
      _totalActiveTime += currentActiveDuration;
    }
  }

  /// Handle cycle completion
  void _endCycle(DateTime timestamp) {
    _cycleCount++;
    _cycleStartTime = timestamp;

    if (_isSessionActive && _sessionStartTime != null) {
      _calculateAndStoreCCF(timestamp);
    }

    debugPrint('Cycle $_cycleCount completed with ${_lastDeviceDepths.length} active devices');
  }

  /// Calculate CCF
  void _calculateAndStoreCCF(DateTime timestamp) {
    if (!_isSessionActive || _sessionStartTime == null) {
      _lastCalculatedCCF = null;
      return;
    }

    _finalizeActiveTime();

    final totalSessionTime = timestamp.difference(_sessionStartTime!);

    if (totalSessionTime.inMilliseconds <= 0) {
      _lastCalculatedCCF = null;
      return;
    }

    _lastCalculatedCCF = _totalActiveTime.inMilliseconds / totalSessionTime.inMilliseconds;

    if (_currentPhase == CPRPhase.compression || _currentPhase == CPRPhase.recoil) {
      _activePhaseStartTime = timestamp;
    }

    debugPrint(
        'CCF calculated: ${(_lastCalculatedCCF! * 100).toStringAsFixed(1)}% (Active: ${_totalActiveTime.inSeconds}s / Total: ${totalSessionTime.inSeconds}s)');
  }

  /// Get current CCF
  double? _getCurrentCCF() {
    if (!_isSessionActive || _sessionStartTime == null) {
      return null;
    }
    return _lastCalculatedCCF;
  }

  /// Calculate combined compression rate from all devices
  void _updateCompressionRate() {
    if (_compressionTimestamps.length >= 2) {
      final timestamps = _compressionTimestamps.toList();
      final timeSpan = timestamps.last.difference(timestamps.first);

      if (timeSpan.inMilliseconds > 0) {
        final compressions = timestamps.length - 1;
        final minutes = timeSpan.inMilliseconds / 60000.0;
        final instantRate = compressions / minutes;

        const alpha = 0.3;
        if (_currentCompressionRate != null) {
          _currentCompressionRate = alpha * instantRate + (1 - alpha) * _currentCompressionRate!;
        } else {
          _currentCompressionRate = instantRate;
        }

        _checkCompressionRateAlerts(_currentCompressionRate!);
      }
    }
  }

  /// Check compression rate alerts
  void _checkCompressionRateAlerts(double rate) {
    if (rate < _config.minCompressionRate) {
      _alertController.add(CPRAlert.goFaster());
    } else if (rate > _config.maxCompressionRate) {
      _alertController.add(CPRAlert.slowDown());
    }
  }

  /// Check compression alerts
  void _checkCompressionAlerts(double depth) {
    if (depth > 60.0) {
      _alertController.add(CPRAlert.beGentle());
    } else if (depth < 50.0 && depth > 5.0) {
      _alertController.add(CPRAlert.releaseMore());
    }
  }

  /// Reset temporary metrics when pressure becomes inactive
  void _resetTemporaryMetrics() {
    // Reset phase tracking
    _currentPhase = CPRPhase.quietude;
    _phaseStartTime = DateTime.now();
    _consecutiveQuietSamples = 0;
    _lastSignificantDepthChange = null;

    // Reset compression rate
    _currentCompressionRate = null;
    _compressionTimestamps.clear();

    // Clear device buffers but keep counts
    for (final buffer in _rawSensorBuffers.values) {
      buffer.clear();
    }
    for (final buffer in _filteredBuffers.values) {
      buffer.clear();
    }

    // Emit reset metrics
    _emitMetrics();

    debugPrint('Temporary metrics reset due to pressure inactivity');
  }

  /// Emit multi-device data for UI display
  void _emitMultiDeviceData() {
    final deviceData = <String, Map<String, dynamic>>{};

    for (final deviceId in _lastDeviceDepths.keys) {
      final depth = _lastDeviceDepths[deviceId] ?? 0.0;
      final count = _lastDeviceCompressionCounts[deviceId] ?? 0;
      final lastTime = _lastDeviceCompressionTimes[deviceId];

      deviceData[deviceId] = {
        'depth': depth,
        'count': count,
        'lastUpdate': lastTime,
        'isActive': depth > 5.0, // Device is active if depth > 5mm
      };
    }

    _multiDeviceController.add(MultiDeviceData(
      timestamp: DateTime.now(),
      deviceData: deviceData,
      activeDevices: _lastDeviceDepths.length,
      combinedDepth: _calculateCombinedDepth(),
    ));
  }

  /// Emit current combined metrics
  void _emitMetrics() {
    final metrics = CPRMetrics(
      compressionRate: _currentCompressionRate,
      compressionCount: _totalCompressions,
      recoilCount: _totalRecoils,
      goodCompressions: _goodCompressions,
      goodRecoils: _goodRecoils,
      cycleNumber: _cycleCount,
      ccf: _getCurrentCCF(),
      currentPhase: _currentPhase,
    );

    _metricsController.add(metrics);
  }

  /// Get data from specific device for display
  Map<String, dynamic> getDeviceData(String deviceId) {
    return {
      'depth': _lastDeviceDepths[deviceId] ?? 0.0,
      'count': _lastDeviceCompressionCounts[deviceId] ?? 0,
      'lastUpdate': _lastDeviceCompressionTimes[deviceId],
      'isActive': _lastDeviceDepths.containsKey(deviceId) && (_lastDeviceDepths[deviceId] ?? 0) > 5.0,
      'bufferSize': _rawSensorBuffers[deviceId]?.length ?? 0,
    };
  }

  /// Get all connected devices data
  Map<String, Map<String, dynamic>> getAllDevicesData() {
    final data = <String, Map<String, dynamic>>{};
    for (final deviceId in _lastDeviceDepths.keys) {
      data[deviceId] = getDeviceData(deviceId);
    }
    return data;
  }

  /// Get number of active devices
  int get activeDevicesCount => _lastDeviceDepths.length;

  /// Reset all state
  void reset() {
    _rawSensorBuffers.clear();
    _filteredBuffers.clear();
    _compressionTimestamps.clear();

    _lastDeviceCompressionCounts.clear();
    _lastDeviceDepths.clear();
    _lastDeviceCompressionTimes.clear();

    _currentPhase = CPRPhase.quietude;
    _phaseStartTime = DateTime.now();
    _consecutiveQuietSamples = 0;
    _lastSignificantDepthChange = null;

    _totalCompressions = 0;
    _totalRecoils = 0;
    _goodCompressions = 0;
    _goodRecoils = 0;
    _cycleCount = 0;
    _cycleStartTime = null;

    _currentCompressionRate = null;

    _sessionStartTime = null;
    _totalActiveTime = Duration.zero;
    _activePhaseStartTime = null;
    _lastCalculatedCCF = null;
    _isSessionActive = false;
    _pressureActive = false;

    debugPrint('ProcessingEngine reset for multi-device operation');
  }

  /// Clean up resources
  void dispose() {
    _metricsController.close();
    _alertController.close();
    _phaseChangeController.close();
    _peakDetectionController.close();
    _multiDeviceController.close();
  }
}

// New class for multi-device data
class MultiDeviceData {
  final DateTime timestamp;
  final Map<String, Map<String, dynamic>> deviceData;
  final int activeDevices;
  final double combinedDepth;

  const MultiDeviceData({
    required this.timestamp,
    required this.deviceData,
    required this.activeDevices,
    required this.combinedDepth,
  });
}

// Update existing classes to include device info
class PeakTrough {
  final DateTime timestamp;
  final double value;
  final PeakTroughType type;
  final bool isGood;
  final String deviceId;
  final String deviceName;

  const PeakTrough({
    required this.timestamp,
    required this.value,
    required this.type,
    required this.isGood,
    required this.deviceId,
    required this.deviceName,
  });
}

// Supporting classes
class SensorDataPoint {
  final DateTime timestamp;
  final double value;

  const SensorDataPoint(this.timestamp, this.value);
}

enum PeakTroughType { compressionPeak, recoilTrough }

class PhaseChangeEvent {
  final DateTime timestamp;
  final CPRPhase fromPhase;
  final CPRPhase toPhase;
  final double value;

  const PhaseChangeEvent({
    required this.timestamp,
    required this.fromPhase,
    required this.toPhase,
    required this.value,
  });
}

class PeakTroughEvent {
  final PeakTrough peak;

  const PeakTroughEvent({required this.peak});
}