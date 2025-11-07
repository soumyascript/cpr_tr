// //cpr_training_app/lib/services/processing_engine.dart
// import 'dart:async';
// import 'dart:collection';
// import 'dart:math' as math;
// import 'package:flutter/foundation.dart';
// import '../models/models.dart';
// import '../services/sensor_service.dart';
//
// class ProcessingEngine {
//   SystemConfig _config = const SystemConfig();
//
//   // Enhanced buffer system for high-frequency detection
//   final _rawSensorBuffer = Queue<SensorDataPoint>();
//   final _filteredBuffer = Queue<SensorDataPoint>();
//
//   // Peak detection state
//   final _peakDetectionBuffer = Queue<double>();
//   DateTime? _lastPeakTime;
//   DateTime? _lastTroughTime;
//   double? _lastPeakValue;
//
//   // Adaptive thresholds
//   double _adaptiveNoiseFloor = 0.0;
//   double _adaptivePeakThreshold = 50.0;
//   final _recentValues = Queue<double>();
//
//   // Phase tracking (simplified)
//   CPRPhase _currentPhase = CPRPhase.quietude;
//   DateTime _phaseStartTime = DateTime.now();
//   int _consecutiveQuietSamples = 0;
//
//   // Metrics tracking
//   int _totalCompressions = 0;
//   int _totalRecoils = 0;
//   int _goodCompressions = 0;
//   int _goodRecoils = 0;
//   int _cycleCount = 0;
//   DateTime? _cycleStartTime;
//
//   // Compression rate calculation
//   final _compressionTimestamps = Queue<DateTime>();
//   double? _currentCompressionRate;
//   final _rateCalculationWindow = 10; // Use last 10 compressions
//
//   // Breath detection
//   int _breathsInCurrentPause = 0;
//   DateTime? _lastBreathTime;
//
//   // CCF calculation state
//   DateTime? _sessionStartTime;
//   Duration _totalActiveTime = Duration.zero;
//   DateTime? _activePhaseStartTime;
//   double? _lastCalculatedCCF;
//   bool _isSessionActive = false;
//
//   // Stream controllers
//   final _metricsController = StreamController<CPRMetrics>.broadcast();
//   final _alertController = StreamController<CPRAlert>.broadcast();
//   final _phaseChangeController = StreamController<PhaseChangeEvent>.broadcast();
//   final _peakDetectionController =
//       StreamController<PeakTroughEvent>.broadcast();
//   final _breathController = StreamController<BreathEvent>.broadcast();
//
//   Stream<CPRMetrics> get metricsStream => _metricsController.stream;
//   Stream<CPRAlert> get alertStream => _alertController.stream;
//   Stream<PhaseChangeEvent> get phaseChangeStream =>
//       _phaseChangeController.stream;
//   Stream<PeakTroughEvent> get peakDetectionStream =>
//       _peakDetectionController.stream;
//   Stream<BreathEvent> get breathStream => _breathController.stream;
//
//   CPRPhase get currentPhase => _currentPhase;
//   int get cycleCount => _cycleCount;
//   double? get compressionRate => _currentCompressionRate;
//
//   /// Update configuration
//   void updateConfig(SystemConfig config) {
//     _config = config;
//     debugPrint('ProcessingEngine config updated');
//   }
//
//   /// Set session state for CCF calculation
//   void setSessionState(bool isActive, {DateTime? sessionStartTime}) {
//     _isSessionActive = isActive;
//     if (isActive && sessionStartTime != null) {
//       _sessionStartTime = sessionStartTime;
//       _totalActiveTime = Duration.zero;
//       _activePhaseStartTime = null;
//       _lastCalculatedCCF = null;
//     } else if (!isActive) {
//       // Session ended, finalize CCF calculation
//       _finalizeActiveTime();
//       _sessionStartTime = null;
//       _isSessionActive = false;
//     }
//     debugPrint('Session state updated: active=$isActive');
//   }
//
//   /// Process new sensor data point
//   void processSensorData(double sensor1Value, double sensor2Value) {
//     final timestamp = DateTime.now();
//
//     // Store raw data
//     _rawSensorBuffer.add(SensorDataPoint(timestamp, sensor1Value));
//     if (_rawSensorBuffer.length > 1000) {
//       _rawSensorBuffer.removeFirst();
//     }
//
//     // Apply filtering
//     final filtered = _applyFilter(sensor1Value);
//     _filteredBuffer.add(SensorDataPoint(timestamp, filtered));
//     if (_filteredBuffer.length > 500) {
//       _filteredBuffer.removeFirst();
//     }
//
//     // Update adaptive thresholds
//     _updateAdaptiveThresholds(filtered);
//
//     // Phase detection and transitions
//     _updatePhaseSimple(timestamp, filtered);
//
//     // Peak detection for compressions/recoils
//     _detectPeaksAndTroughs(timestamp, filtered);
//
//     // Breath detection during pause
//     if (_currentPhase == CPRPhase.pause) {
//       _detectBreath(timestamp, sensor2Value);
//     }
//
//     // Emit current metrics
//     _emitMetrics();
//   }
//
//   /// Apply simple moving average filter
//   double _applyFilter(double rawValue) {
//     _recentValues.add(rawValue);
//     if (_recentValues.length > 5) {
//       _recentValues.removeFirst();
//     }
//
//     return _recentValues.fold(0.0, (sum, value) => sum + value) /
//         _recentValues.length;
//   }
//
//   /// Update adaptive noise floor and peak threshold
//   void _updateAdaptiveThresholds(double value) {
//     const alpha = 0.95; // Smoothing factor
//     final absValue = value.abs();
//
//     if (absValue < 20) {
//       // Update noise floor with quiet values
//       _adaptiveNoiseFloor =
//           alpha * _adaptiveNoiseFloor + (1 - alpha) * absValue;
//     }
//
//     // Dynamic peak threshold
//     _adaptivePeakThreshold = math.max(30.0, _adaptiveNoiseFloor * 3);
//   }
//
//   /// Enhanced peak and trough detection
//   void _detectPeaksAndTroughs(DateTime timestamp, double value) {
//     _peakDetectionBuffer.add(value);
//     if (_peakDetectionBuffer.length > 10) {
//       _peakDetectionBuffer.removeFirst();
//     }
//
//     if (_peakDetectionBuffer.length < 5) return;
//
//     final buffer = _peakDetectionBuffer.toList();
//     final center = buffer[buffer.length ~/ 2];
//     final neighbors = [
//       ...buffer.take(buffer.length ~/ 2),
//       ...buffer.skip((buffer.length ~/ 2) + 1)
//     ];
//
//     final centerTime = timestamp.subtract(
//       Duration(milliseconds: (buffer.length ~/ 2) * 5),
//     ); // Assuming ~200Hz
//
//     // Peak detection (compression)
//     if (_isPeak(center, neighbors) &&
//         center > _adaptivePeakThreshold &&
//         _config.compressionDirection == CompressionDirection.increasing) {
//       _checkAndRecordPeak(centerTime, center);
//     }
//
//     // Trough detection (recoil)
//     if (_isTrough(center, neighbors) &&
//         center.abs() > _adaptivePeakThreshold &&
//         _config.compressionDirection == CompressionDirection.increasing) {
//       _checkAndRecordTrough(centerTime, center);
//     }
//
//     // Handle decreasing compression direction
//     if (_config.compressionDirection == CompressionDirection.decreasing) {
//       if (_isTrough(center, neighbors) &&
//           center.abs() > _adaptivePeakThreshold) {
//         _checkAndRecordPeak(centerTime, center.abs());
//       }
//       if (_isPeak(center, neighbors) && center > _adaptivePeakThreshold) {
//         _checkAndRecordTrough(centerTime, center);
//       }
//     }
//   }
//
//   /// Check and record compression peak
//   void _checkAndRecordPeak(DateTime peakTime, double peakValue) {
//     const minInterval = Duration(milliseconds: 200);
//
//     if (_lastPeakTime == null ||
//         peakTime.difference(_lastPeakTime!) > minInterval) {
//       _recordCompressionPeak(peakTime, peakValue);
//       _lastPeakTime = peakTime;
//       _lastPeakValue = peakValue;
//     }
//   }
//
//   /// Check and record recoil trough
//   void _checkAndRecordTrough(DateTime troughTime, double troughValue) {
//     const minInterval = Duration(milliseconds: 200);
//
//     if (_lastTroughTime == null ||
//         troughTime.difference(_lastTroughTime!) > minInterval) {
//       if (_lastPeakValue != null &&
//           (_lastPeakValue! - troughValue) > _adaptivePeakThreshold) {
//         _recordRecoilTrough(troughTime, troughValue);
//         _lastTroughTime = troughTime;
//       }
//     }
//   }
//
//   /// Check if a point is a local peak
//   bool _isPeak(double center, List<double> neighbors) {
//     for (final neighbor in neighbors) {
//       if (center <= neighbor) return false;
//     }
//     return true;
//   }
//
//   /// Check if a point is a local trough
//   bool _isTrough(double center, List<double> neighbors) {
//     for (final neighbor in neighbors) {
//       if (center >= neighbor) return false;
//     }
//     return true;
//   }
//
//   /// Check if compression depth/force is good
//   bool _isGoodCompression(double value) {
//     return value >= _config.compressionOk && value <= _config.compressionHi;
//   }
//
//   /// Check if recoil is complete
//   bool _isGoodRecoil(double value) {
//     return value >= _config.recoilOk;
//   }
//
//   /// Generate appropriate alert for compression rate
//   void _checkCompressionRateAlerts(double rate) {
//     if (rate < _config.minCompressionRate) {
//       _alertController.add(CPRAlert.goFaster());
//     } else if (rate > _config.maxCompressionRate) {
//       _alertController.add(CPRAlert.slowDown());
//     }
//   }
//
//   /// Generate appropriate alert for compression quality
//   void _checkCompressionAlerts(double value) {
//     if (value > _config.compressionHi) {
//       _alertController.add(CPRAlert.beGentle());
//     }
//   }
//
//   /// Generate appropriate alert for recoil quality
//   void _checkRecoilAlerts(double value) {
//     if (value < _config.recoilOk) {
//       _alertController.add(CPRAlert.releaseMore());
//     }
//   }
//
//   /// Record a compression peak
//   void _recordCompressionPeak(DateTime timestamp, double value) {
//     _totalCompressions++;
//
//     final isGood = _isGoodCompression(value);
//     if (isGood) {
//       _goodCompressions++;
//     }
//
//     // Add to compression timestamps for rate calculation
//     _compressionTimestamps.add(timestamp);
//     if (_compressionTimestamps.length > _rateCalculationWindow) {
//       _compressionTimestamps.removeFirst();
//     }
//
//     // Update compression rate
//     _updateCompressionRate();
//
//     final peak = PeakTrough(
//       timestamp: timestamp,
//       value: value,
//       type: PeakTroughType.compressionPeak,
//       isGood: isGood,
//     );
//
//     _peakDetectionController.add(PeakTroughEvent(peak: peak));
//     _checkCompressionAlerts(value);
//
//     debugPrint(
//         'Compression #$_totalCompressions: ${value.toStringAsFixed(1)} (${isGood ? "Good" : "Bad"}) - Rate: ${_currentCompressionRate?.toStringAsFixed(1) ?? "N/A"}/min');
//   }
//
//   /// Record a recoil trough
//   void _recordRecoilTrough(DateTime timestamp, double value) {
//     _totalRecoils++;
//
//     final isGood = _isGoodRecoil(value);
//     if (isGood) {
//       _goodRecoils++;
//     }
//
//     final trough = PeakTrough(
//       timestamp: timestamp,
//       value: value,
//       type: PeakTroughType.recoilTrough,
//       isGood: isGood,
//     );
//
//     _peakDetectionController.add(PeakTroughEvent(peak: trough));
//     _checkRecoilAlerts(value);
//
//     debugPrint(
//         'Recoil #$_totalRecoils: ${value.toStringAsFixed(1)} (${isGood ? "Good" : "Bad"})');
//   }
//
//   /// Calculate current compression rate based on recent compressions
//   void _updateCompressionRate() {
//     if (_compressionTimestamps.length >= 2) {
//       final timestamps = _compressionTimestamps.toList();
//       final timeSpan = timestamps.last.difference(timestamps.first);
//
//       if (timeSpan.inMilliseconds > 0) {
//         final compressions = timestamps.length - 1;
//         final minutes = timeSpan.inMilliseconds / 60000.0;
//         final instantRate = compressions / minutes;
//
//         // Smooth the rate calculation
//         const alpha = 0.3;
//         if (_currentCompressionRate != null) {
//           _currentCompressionRate =
//               alpha * instantRate + (1 - alpha) * _currentCompressionRate!;
//         } else {
//           _currentCompressionRate = instantRate;
//         }
//
//         _checkCompressionRateAlerts(_currentCompressionRate!);
//       }
//     }
//   }
//
//   /// Simplified phase detection based on activity level
//   void _updatePhaseSimple(DateTime timestamp, double value) {
//     final quietThreshold = _config.quietudePercent * 1023;
//     final isQuiet = value.abs() <= quietThreshold;
//
//     if (isQuiet) {
//       _consecutiveQuietSamples++;
//     } else {
//       _consecutiveQuietSamples = 0;
//     }
//
//     CPRPhase newPhase;
//
//     // Determine phase based on recent activity
//     if (_consecutiveQuietSamples > 20) {
//       // ~100ms of quiet at 200Hz
//       final timeSincePhaseStart = timestamp.difference(_phaseStartTime);
//       if (timeSincePhaseStart.inMilliseconds >
//           (_config.maxQuietudeTime * 1000)) {
//         newPhase = CPRPhase.pause;
//       } else {
//         newPhase = CPRPhase.quietude;
//       }
//     } else {
//       // Active phase - determine compression vs recoil based on recent trend
//       newPhase = _determineActivePhase();
//     }
//
//     // FIXED: Only transition if the phase actually changes
//     if (newPhase != _currentPhase) {
//       _transitionToPhase(newPhase, timestamp);
//     }
//   }
//
//   /// Determine if we're in compression or recoil phase
//   CPRPhase _determineActivePhase() {
//     if (_filteredBuffer.length < 10) return CPRPhase.compression;
//
//     final recent = _filteredBuffer.toList().takeLast(10).toList();
//     final trend = recent.last.value - recent.first.value;
//
//     if (_config.compressionDirection == CompressionDirection.increasing) {
//       return trend > 0 ? CPRPhase.compression : CPRPhase.recoil;
//     } else {
//       return trend < 0 ? CPRPhase.compression : CPRPhase.recoil;
//     }
//   }
//
//   /// Handle phase transitions
//   void _transitionToPhase(CPRPhase newPhase, DateTime timestamp) {
//     final previousPhase = _currentPhase;
//
//     // Update active time tracking before phase change
//     _updateActiveTimeTracking(previousPhase, newPhase, timestamp);
//
//     // Handle cycle transitions - ONLY increment when transitioning from quietude to pause
//     if (previousPhase == CPRPhase.quietude && newPhase == CPRPhase.pause) {
//       _endCycle(timestamp);
//     }
//
//     _currentPhase = newPhase;
//
//     // FIXED: Don't reset phase start time when transitioning from quietude to pause
//     // This prevents the pause→quietude→pause loop
//     if (!(previousPhase == CPRPhase.quietude && newPhase == CPRPhase.pause)) {
//       _phaseStartTime = timestamp;
//     }
//
//     // FIXED: Don't reset consecutive quiet samples when entering quietude or pause
//     if (newPhase != CPRPhase.quietude && newPhase != CPRPhase.pause) {
//       _consecutiveQuietSamples = 0;
//     }
//
//     if (newPhase == CPRPhase.pause) {
//       _breathsInCurrentPause = 0;
//     }
//
//     _phaseChangeController.add(PhaseChangeEvent(
//       timestamp: timestamp,
//       fromPhase: previousPhase,
//       toPhase: newPhase,
//       value: _filteredBuffer.isNotEmpty ? _filteredBuffer.last.value : 0.0,
//     ));
//
//     debugPrint('Phase: ${previousPhase.name} -> ${newPhase.name}');
//   }
//
//   /// Update active time tracking for CCF calculation
//   void _updateActiveTimeTracking(
//       CPRPhase fromPhase, CPRPhase toPhase, DateTime timestamp) {
//     if (!_isSessionActive || _sessionStartTime == null) return;
//
//     // If transitioning FROM an active phase (compression or recoil)
//     if ((fromPhase == CPRPhase.compression || fromPhase == CPRPhase.recoil) &&
//         _activePhaseStartTime != null) {
//       // Add the duration of the active phase to total active time
//       final activePhaseDuration = timestamp.difference(_activePhaseStartTime!);
//       _totalActiveTime += activePhaseDuration;
//       _activePhaseStartTime = null;
//     }
//
//     // If transitioning TO an active phase (compression or recoil)
//     if (toPhase == CPRPhase.compression || toPhase == CPRPhase.recoil) {
//       _activePhaseStartTime = timestamp;
//     }
//   }
//
//   /// Finalize active time calculation (for session end or current calculation)
//   void _finalizeActiveTime() {
//     if (!_isSessionActive || _sessionStartTime == null) return;
//
//     final now = DateTime.now();
//
//     // If currently in an active phase, add its duration
//     if ((_currentPhase == CPRPhase.compression ||
//             _currentPhase == CPRPhase.recoil) &&
//         _activePhaseStartTime != null) {
//       final currentActiveDuration = now.difference(_activePhaseStartTime!);
//       _totalActiveTime += currentActiveDuration;
//     }
//   }
//
//   /// Handle cycle completion and trigger CCF calculation
//   void _endCycle(DateTime timestamp) {
//     _cycleCount++;
//     _cycleStartTime = timestamp;
//
//     // Calculate CCF when entering pause state (cycle increment moment)
//     if (_isSessionActive && _sessionStartTime != null) {
//       _calculateAndStoreCCF(timestamp);
//     }
//
//     debugPrint('Cycle $_cycleCount completed');
//   }
//
//   /// Calculate CCF for the entire session duration
//   void _calculateAndStoreCCF(DateTime timestamp) {
//     if (!_isSessionActive || _sessionStartTime == null) {
//       _lastCalculatedCCF = null;
//       return;
//     }
//
//     // Finalize current active time
//     _finalizeActiveTime();
//
//     // Calculate total elapsed time since session start
//     final totalSessionTime = timestamp.difference(_sessionStartTime!);
//
//     if (totalSessionTime.inMilliseconds <= 0) {
//       _lastCalculatedCCF = null;
//       return;
//     }
//
//     // CCF = total active time / total session time
//     _lastCalculatedCCF =
//         _totalActiveTime.inMilliseconds / totalSessionTime.inMilliseconds;
//
//     // Reset active phase tracking for next phase
//     if (_currentPhase == CPRPhase.compression ||
//         _currentPhase == CPRPhase.recoil) {
//       _activePhaseStartTime = timestamp;
//     }
//
//     debugPrint(
//         'CCF calculated: ${(_lastCalculatedCCF! * 100).toStringAsFixed(1)}% (Active: ${_totalActiveTime.inSeconds}s / Total: ${totalSessionTime.inSeconds}s)');
//   }
//
//   /// Get current CCF (only calculated during pause state)
//   double? _getCurrentCCF() {
//     // Only return CCF if session is active and it has been calculated
//     if (!_isSessionActive || _sessionStartTime == null) {
//       return null;
//     }
//
//     return _lastCalculatedCCF;
//   }
//
//   /// Detect breaths during pause phase
//   void _detectBreath(DateTime timestamp, double sensor2Value) {
//     const breathThreshold = 100.0;
//     const minBreathInterval = Duration(milliseconds: 500);
//
//     if (sensor2Value > breathThreshold) {
//       if (_lastBreathTime == null ||
//           timestamp.difference(_lastBreathTime!) > minBreathInterval) {
//         _breathsInCurrentPause++;
//         _lastBreathTime = timestamp;
//
//         _breathController.add(BreathEvent(
//           timestamp: timestamp,
//           value: sensor2Value,
//           breathNumber: _breathsInCurrentPause,
//         ));
//
//         debugPrint(
//             'Breath #$_breathsInCurrentPause detected: ${sensor2Value.toStringAsFixed(1)}');
//       }
//     }
//   }
//
//   /// Emit current metrics
//   void _emitMetrics() {
//     final metrics = CPRMetrics(
//       compressionRate: _currentCompressionRate,
//       compressionCount: _totalCompressions,
//       recoilCount: _totalRecoils,
//       goodCompressions: _goodCompressions,
//       goodRecoils: _goodRecoils,
//       cycleNumber: _cycleCount,
//       ccf: _getCurrentCCF(),
//       currentPhase: _currentPhase,
//     );
//
//     _metricsController.add(metrics);
//   }
//
//   /// Reset all state
//   void reset() {
//     _rawSensorBuffer.clear();
//     _filteredBuffer.clear();
//     _peakDetectionBuffer.clear();
//     _recentValues.clear();
//     _compressionTimestamps.clear();
//
//     _lastPeakTime = null;
//     _lastTroughTime = null;
//     _lastPeakValue = null;
//     _lastBreathTime = null;
//
//     _adaptiveNoiseFloor = 0.0;
//     _adaptivePeakThreshold = 50.0;
//
//     _currentPhase = CPRPhase.quietude;
//     _phaseStartTime = DateTime.now();
//     _consecutiveQuietSamples = 0;
//
//     _totalCompressions = 0;
//     _totalRecoils = 0;
//     _goodCompressions = 0;
//     _goodRecoils = 0;
//     _cycleCount = 0;
//     _cycleStartTime = null;
//
//     _currentCompressionRate = null;
//     _breathsInCurrentPause = 0;
//
//     // Reset CCF tracking
//     _sessionStartTime = null;
//     _totalActiveTime = Duration.zero;
//     _activePhaseStartTime = null;
//     _lastCalculatedCCF = null;
//     _isSessionActive = false;
//
//     debugPrint('ProcessingEngine reset with enhanced detection');
//   }
//
//   /// Clean up resources
//   void dispose() {
//     _metricsController.close();
//     _alertController.close();
//     _phaseChangeController.close();
//     _peakDetectionController.close();
//     _breathController.close();
//   }
// }
//
// // Supporting classes
// class SensorDataPoint {
//   final DateTime timestamp;
//   final double value;
//
//   const SensorDataPoint(this.timestamp, this.value);
// }
//
// class PeakTrough {
//   final DateTime timestamp;
//   final double value;
//   final PeakTroughType type;
//   final bool isGood;
//
//   const PeakTrough({
//     required this.timestamp,
//     required this.value,
//     required this.type,
//     required this.isGood,
//   });
// }
//
// enum PeakTroughType { compressionPeak, recoilTrough }
//
// class PhaseChangeEvent {
//   final DateTime timestamp;
//   final CPRPhase fromPhase;
//   final CPRPhase toPhase;
//   final double value;
//
//   const PhaseChangeEvent({
//     required this.timestamp,
//     required this.fromPhase,
//     required this.toPhase,
//     required this.value,
//   });
// }
//
// class PeakTroughEvent {
//   final PeakTrough peak;
//
//   const PeakTroughEvent({required this.peak});
// }
//
// class BreathEvent {
//   final DateTime timestamp;
//   final double value;
//   final int breathNumber;
//
//   const BreathEvent({
//     required this.timestamp,
//     required this.value,
//     required this.breathNumber,
//   });
// }
//
// extension TakeLast<T> on Iterable<T> {
//   Iterable<T> takeLast(int count) {
//     if (count <= 0) return <T>[];
//     if (count >= length) return this;
//     return skip(length - count);
//   }
// }



// 2nd part
//
// //cpr_training_app/lib/services/processing_engine.dart
// import 'dart:async';
// import 'dart:collection';
// import 'dart:math' as math;
// import 'package:flutter/foundation.dart';
// import '../models/models.dart';
// import '../services/sensor_service.dart';
//
// class ProcessingEngine {
//   SystemConfig _config = const SystemConfig();
//
//   // Enhanced buffer system
//   final _rawSensorBuffer = Queue<SensorDataPoint>();
//   final _filteredBuffer = Queue<SensorDataPoint>();
//
//   // Compression tracking
//   int _lastCompressionCount = 0;
//   double _lastCompressionDepth = 0.0;
//
//   // Phase tracking
//   CPRPhase _currentPhase = CPRPhase.quietude;
//   DateTime _phaseStartTime = DateTime.now();
//   int _consecutiveQuietSamples = 0;
//
//   // Metrics tracking
//   int _totalCompressions = 0;
//   int _totalRecoils = 0;
//   int _goodCompressions = 0;
//   int _goodRecoils = 0;
//   int _cycleCount = 0;
//   DateTime? _cycleStartTime;
//
//   // Compression rate calculation
//   final _compressionTimestamps = Queue<DateTime>();
//   double? _currentCompressionRate;
//
//   // CCF calculation state
//   DateTime? _sessionStartTime;
//   Duration _totalActiveTime = Duration.zero;
//   DateTime? _activePhaseStartTime;
//   double? _lastCalculatedCCF;
//   bool _isSessionActive = false;
//
//   // Stream controllers
//   final _metricsController = StreamController<CPRMetrics>.broadcast();
//   final _alertController = StreamController<CPRAlert>.broadcast();
//   final _phaseChangeController = StreamController<PhaseChangeEvent>.broadcast();
//   final _peakDetectionController = StreamController<PeakTroughEvent>.broadcast();
//
//   Stream<CPRMetrics> get metricsStream => _metricsController.stream;
//   Stream<CPRAlert> get alertStream => _alertController.stream;
//   Stream<PhaseChangeEvent> get phaseChangeStream => _phaseChangeController.stream;
//   Stream<PeakTroughEvent> get peakDetectionStream => _peakDetectionController.stream;
//
//   CPRPhase get currentPhase => _currentPhase;
//   int get cycleCount => _cycleCount;
//   double? get compressionRate => _currentCompressionRate;
//
//   /// Update configuration
//   void updateConfig(SystemConfig config) {
//     _config = config;
//     debugPrint('ProcessingEngine config updated');
//   }
//
//   /// Set session state for CCF calculation
//   void setSessionState(bool isActive, {DateTime? sessionStartTime}) {
//     _isSessionActive = isActive;
//     if (isActive && sessionStartTime != null) {
//       _sessionStartTime = sessionStartTime;
//       _totalActiveTime = Duration.zero;
//       _activePhaseStartTime = null;
//       _lastCalculatedCCF = null;
//     } else if (!isActive) {
//       _finalizeActiveTime();
//       _sessionStartTime = null;
//       _isSessionActive = false;
//     }
//     debugPrint('Session state updated: active=$isActive');
//   }
//
//   /// Process new sensor data from ESP32 - UPDATED
//   void processSensorData(double depth, int count, double tiltX, double tiltY) {
//     final timestamp = DateTime.now();
//
//     // Store raw data
//     _rawSensorBuffer.add(SensorDataPoint(timestamp, depth));
//     if (_rawSensorBuffer.length > 1000) {
//       _rawSensorBuffer.removeFirst();
//     }
//
//     // Detect new compression
//     if (count > _lastCompressionCount) {
//       _recordNewCompression(timestamp, _lastCompressionDepth);
//       _lastCompressionCount = count;
//     }
//
//     // Update last depth
//     _lastCompressionDepth = depth;
//
//     // Update phase based on depth
//     _updatePhaseFromDepth(timestamp, depth);
//
//     // Emit current metrics
//     _emitMetrics();
//   }
//
//   /// Record a new compression
//   void _recordNewCompression(DateTime timestamp, double depth) {
//     _totalCompressions++;
//
//     final isGood = _isGoodCompression(depth);
//     if (isGood) {
//       _goodCompressions++;
//     }
//
//     // Add to compression timestamps for rate calculation
//     _compressionTimestamps.add(timestamp);
//     if (_compressionTimestamps.length > 10) {
//       _compressionTimestamps.removeFirst();
//     }
//
//     // Update compression rate
//     _updateCompressionRate();
//
//     final peak = PeakTrough(
//       timestamp: timestamp,
//       value: depth,
//       type: PeakTroughType.compressionPeak,
//       isGood: isGood,
//     );
//
//     _peakDetectionController.add(PeakTroughEvent(peak: peak));
//     _checkCompressionAlerts(depth);
//
//     debugPrint(
//         'Compression #$_totalCompressions: ${depth.toStringAsFixed(1)}mm (${isGood ? "Good" : "Bad"}) - Rate: ${_currentCompressionRate?.toStringAsFixed(1) ?? "N/A"}/min');
//   }
//
//   /// Check if compression depth is good (50-60mm typically)
//   bool _isGoodCompression(double depth) {
//     return depth >= 50.0 && depth <= 60.0;
//   }
//
//   /// Update phase based on compression depth
//   void _updatePhaseFromDepth(DateTime timestamp, double depth) {
//     CPRPhase newPhase;
//
//     if (depth < 5.0) {
//       // No significant compression
//       _consecutiveQuietSamples++;
//       if (_consecutiveQuietSamples > 50) {
//         newPhase = CPRPhase.pause;
//       } else {
//         newPhase = CPRPhase.quietude;
//       }
//     } else {
//       _consecutiveQuietSamples = 0;
//       if (depth > _lastCompressionDepth) {
//         newPhase = CPRPhase.compression;
//       } else {
//         newPhase = CPRPhase.recoil;
//       }
//     }
//
//     if (newPhase != _currentPhase) {
//       _transitionToPhase(newPhase, timestamp);
//     }
//   }
//
//   /// Handle phase transitions
//   void _transitionToPhase(CPRPhase newPhase, DateTime timestamp) {
//     final previousPhase = _currentPhase;
//
//     _updateActiveTimeTracking(previousPhase, newPhase, timestamp);
//
//     if (previousPhase == CPRPhase.quietude && newPhase == CPRPhase.pause) {
//       _endCycle(timestamp);
//     }
//
//     _currentPhase = newPhase;
//
//     if (!(previousPhase == CPRPhase.quietude && newPhase == CPRPhase.pause)) {
//       _phaseStartTime = timestamp;
//     }
//
//     _phaseChangeController.add(PhaseChangeEvent(
//       timestamp: timestamp,
//       fromPhase: previousPhase,
//       toPhase: newPhase,
//       value: _lastCompressionDepth,
//     ));
//
//     debugPrint('Phase: ${previousPhase.name} -> ${newPhase.name}');
//   }
//
//   /// Update active time tracking for CCF calculation
//   void _updateActiveTimeTracking(
//       CPRPhase fromPhase, CPRPhase toPhase, DateTime timestamp) {
//     if (!_isSessionActive || _sessionStartTime == null) return;
//
//     if ((fromPhase == CPRPhase.compression || fromPhase == CPRPhase.recoil) &&
//         _activePhaseStartTime != null) {
//       final activePhaseDuration = timestamp.difference(_activePhaseStartTime!);
//       _totalActiveTime += activePhaseDuration;
//       _activePhaseStartTime = null;
//     }
//
//     if (toPhase == CPRPhase.compression || toPhase == CPRPhase.recoil) {
//       _activePhaseStartTime = timestamp;
//     }
//   }
//
//   /// Finalize active time calculation
//   void _finalizeActiveTime() {
//     if (!_isSessionActive || _sessionStartTime == null) return;
//
//     final now = DateTime.now();
//
//     if ((_currentPhase == CPRPhase.compression ||
//         _currentPhase == CPRPhase.recoil) &&
//         _activePhaseStartTime != null) {
//       final currentActiveDuration = now.difference(_activePhaseStartTime!);
//       _totalActiveTime += currentActiveDuration;
//     }
//   }
//
//   /// Handle cycle completion
//   void _endCycle(DateTime timestamp) {
//     _cycleCount++;
//     _cycleStartTime = timestamp;
//
//     if (_isSessionActive && _sessionStartTime != null) {
//       _calculateAndStoreCCF(timestamp);
//     }
//
//     debugPrint('Cycle $_cycleCount completed');
//   }
//
//   /// Calculate CCF
//   void _calculateAndStoreCCF(DateTime timestamp) {
//     if (!_isSessionActive || _sessionStartTime == null) {
//       _lastCalculatedCCF = null;
//       return;
//     }
//
//     _finalizeActiveTime();
//
//     final totalSessionTime = timestamp.difference(_sessionStartTime!);
//
//     if (totalSessionTime.inMilliseconds <= 0) {
//       _lastCalculatedCCF = null;
//       return;
//     }
//
//     _lastCalculatedCCF =
//         _totalActiveTime.inMilliseconds / totalSessionTime.inMilliseconds;
//
//     if (_currentPhase == CPRPhase.compression ||
//         _currentPhase == CPRPhase.recoil) {
//       _activePhaseStartTime = timestamp;
//     }
//
//     debugPrint(
//         'CCF calculated: ${(_lastCalculatedCCF! * 100).toStringAsFixed(1)}% (Active: ${_totalActiveTime.inSeconds}s / Total: ${totalSessionTime.inSeconds}s)');
//   }
//
//   /// Get current CCF
//   double? _getCurrentCCF() {
//     if (!_isSessionActive || _sessionStartTime == null) {
//       return null;
//     }
//     return _lastCalculatedCCF;
//   }
//
//   /// Calculate compression rate
//   void _updateCompressionRate() {
//     if (_compressionTimestamps.length >= 2) {
//       final timestamps = _compressionTimestamps.toList();
//       final timeSpan = timestamps.last.difference(timestamps.first);
//
//       if (timeSpan.inMilliseconds > 0) {
//         final compressions = timestamps.length - 1;
//         final minutes = timeSpan.inMilliseconds / 60000.0;
//         final instantRate = compressions / minutes;
//
//         const alpha = 0.3;
//         if (_currentCompressionRate != null) {
//           _currentCompressionRate =
//               alpha * instantRate + (1 - alpha) * _currentCompressionRate!;
//         } else {
//           _currentCompressionRate = instantRate;
//         }
//
//         _checkCompressionRateAlerts(_currentCompressionRate!);
//       }
//     }
//   }
//
//   /// Check compression rate alerts
//   void _checkCompressionRateAlerts(double rate) {
//     if (rate < _config.minCompressionRate) {
//       _alertController.add(CPRAlert.goFaster());
//     } else if (rate > _config.maxCompressionRate) {
//       _alertController.add(CPRAlert.slowDown());
//     }
//   }
//
//   /// Check compression alerts
//   void _checkCompressionAlerts(double depth) {
//     if (depth > 60.0) {
//       _alertController.add(CPRAlert.beGentle());
//     } else if (depth < 50.0 && depth > 5.0) {
//       // Only alert if actively compressing but too shallow
//       _alertController.add(CPRAlert.releaseMore());
//     }
//   }
//
//   /// Emit current metrics
//   void _emitMetrics() {
//     final metrics = CPRMetrics(
//       compressionRate: _currentCompressionRate,
//       compressionCount: _totalCompressions,
//       recoilCount: _totalRecoils,
//       goodCompressions: _goodCompressions,
//       goodRecoils: _goodRecoils,
//       cycleNumber: _cycleCount,
//       ccf: _getCurrentCCF(),
//       currentPhase: _currentPhase,
//     );
//
//     _metricsController.add(metrics);
//   }
//
//   /// Reset all state
//   void reset() {
//     _rawSensorBuffer.clear();
//     _filteredBuffer.clear();
//     _compressionTimestamps.clear();
//
//     _lastCompressionCount = 0;
//     _lastCompressionDepth = 0.0;
//
//     _currentPhase = CPRPhase.quietude;
//     _phaseStartTime = DateTime.now();
//     _consecutiveQuietSamples = 0;
//
//     _totalCompressions = 0;
//     _totalRecoils = 0;
//     _goodCompressions = 0;
//     _goodRecoils = 0;
//     _cycleCount = 0;
//     _cycleStartTime = null;
//
//     _currentCompressionRate = null;
//
//     _sessionStartTime = null;
//     _totalActiveTime = Duration.zero;
//     _activePhaseStartTime = null;
//     _lastCalculatedCCF = null;
//     _isSessionActive = false;
//
//     debugPrint('ProcessingEngine reset');
//   }
//
//   /// Clean up resources
//   void dispose() {
//     _metricsController.close();
//     _alertController.close();
//     _phaseChangeController.close();
//     _peakDetectionController.close();
//   }
// }
//
// // Supporting classes
// class SensorDataPoint {
//   final DateTime timestamp;
//   final double value;
//
//   const SensorDataPoint(this.timestamp, this.value);
// }
//
// class PeakTrough {
//   final DateTime timestamp;
//   final double value;
//   final PeakTroughType type;
//   final bool isGood;
//
//   const PeakTrough({
//     required this.timestamp,
//     required this.value,
//     required this.type,
//     required this.isGood,
//   });
// }
//
// enum PeakTroughType { compressionPeak, recoilTrough }
//
// class PhaseChangeEvent {
//   final DateTime timestamp;
//   final CPRPhase fromPhase;
//   final CPRPhase toPhase;
//   final double value;
//
//   const PhaseChangeEvent({
//     required this.timestamp,
//     required this.fromPhase,
//     required this.toPhase,
//     required this.value,
//   });
// }
//
// class PeakTroughEvent {
//   final PeakTrough peak;
//
//   const PeakTroughEvent({required this.peak});
// }


//
// //3rd part
//cpr_training_app/lib/services/processing_engine.dart
import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/sensor_service.dart';

class ProcessingEngine {
  SystemConfig _config = const SystemConfig();

  // Enhanced buffer system
  final _rawSensorBuffer = Queue<SensorDataPoint>();
  final _filteredBuffer = Queue<SensorDataPoint>();

  // Compression tracking
  int _lastCompressionCount = 0;
  double _lastCompressionDepth = 0.0;

  // Phase tracking - FIXED
  CPRPhase _currentPhase = CPRPhase.quietude;
  DateTime _phaseStartTime = DateTime.now();
  int _consecutiveQuietSamples = 0;
  DateTime? _lastSignificantDepthChange; // NEW: Track when depth last changed significantly

  // Metrics tracking
  int _totalCompressions = 0;
  int _totalRecoils = 0;
  int _goodCompressions = 0;
  int _goodRecoils = 0;
  int _cycleCount = 0;
  DateTime? _cycleStartTime;

  // Compression rate calculation
  final _compressionTimestamps = Queue<DateTime>();
  double? _currentCompressionRate;

  // CCF calculation state
  DateTime? _sessionStartTime;
  Duration _totalActiveTime = Duration.zero;
  DateTime? _activePhaseStartTime;
  double? _lastCalculatedCCF;
  bool _isSessionActive = false;

  // Stream controllers
  final _metricsController = StreamController<CPRMetrics>.broadcast();
  final _alertController = StreamController<CPRAlert>.broadcast();
  final _phaseChangeController = StreamController<PhaseChangeEvent>.broadcast();
  final _peakDetectionController = StreamController<PeakTroughEvent>.broadcast();

  Stream<CPRMetrics> get metricsStream => _metricsController.stream;
  Stream<CPRAlert> get alertStream => _alertController.stream;
  Stream<PhaseChangeEvent> get phaseChangeStream => _phaseChangeController.stream;
  Stream<PeakTroughEvent> get peakDetectionStream => _peakDetectionController.stream;

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

  /// Process new sensor data from ESP32
  void processSensorData(double depth, int count, double tiltX, double tiltY) {
    final timestamp = DateTime.now();

    // Store raw data
    _rawSensorBuffer.add(SensorDataPoint(timestamp, depth));
    if (_rawSensorBuffer.length > 1000) {
      _rawSensorBuffer.removeFirst();
    }

    // Detect new compression
    if (count > _lastCompressionCount) {
      _recordNewCompression(timestamp, _lastCompressionDepth);
      _lastCompressionCount = count;
    }

    // Update phase based on depth - FIXED VERSION
    _updatePhaseFromDepth(timestamp, depth);

    // Update last depth
    _lastCompressionDepth = depth;

    // Emit current metrics
    _emitMetrics();
  }

  /// Record a new compression
  void _recordNewCompression(DateTime timestamp, double depth) {
    _totalCompressions++;

    final isGood = _isGoodCompression(depth);
    if (isGood) {
      _goodCompressions++;
    }

    // Add to compression timestamps for rate calculation
    _compressionTimestamps.add(timestamp);
    if (_compressionTimestamps.length > 10) {
      _compressionTimestamps.removeFirst();
    }

    // Update compression rate
    _updateCompressionRate();

    final peak = PeakTrough(
      timestamp: timestamp,
      value: depth,
      type: PeakTroughType.compressionPeak,
      isGood: isGood,
    );

    _peakDetectionController.add(PeakTroughEvent(peak: peak));
    _checkCompressionAlerts(depth);

    debugPrint(
        'Compression #$_totalCompressions: ${depth.toStringAsFixed(1)}mm (${isGood ? "Good" : "Bad"}) - Rate: ${_currentCompressionRate?.toStringAsFixed(1) ?? "N/A"}/min');
  }

  /// Check if compression depth is good (50-60mm typically)
  bool _isGoodCompression(double depth) {
    return depth >= 50.0 && depth <= 60.0;
  }

  /// Update phase based on compression depth - FIXED VERSION
  void _updatePhaseFromDepth(DateTime timestamp, double depth) {
    CPRPhase newPhase;

    // FIXED: Better phase detection logic
    if (depth < 5.0) {
      // No significant compression - quietude or pause
      _consecutiveQuietSamples++;
      if (_consecutiveQuietSamples > 50) { // ~500ms at 100Hz
        newPhase = CPRPhase.pause;
      } else {
        newPhase = CPRPhase.quietude;
      }
    } else {
      // Active compression detected
      _consecutiveQuietSamples = 0;

      // FIXED: Detect phase based on depth change
      if (_lastSignificantDepthChange == null ||
          timestamp.difference(_lastSignificantDepthChange!).inMilliseconds > 100) {
        // Sample depth change over 100ms window
        _lastSignificantDepthChange = timestamp;
      }

      // If depth is increasing significantly, we're compressing
      // If depth is decreasing significantly, we're in recoil
      final depthChange = depth - _lastCompressionDepth;

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
        if (depth > 20.0 && (_currentPhase == CPRPhase.quietude || _currentPhase == CPRPhase.pause)) {
          newPhase = CPRPhase.compression;
        }
      }
    }

    if (newPhase != _currentPhase) {
      _transitionToPhase(newPhase, timestamp);
    }
  }

  /// Handle phase transitions
  void _transitionToPhase(CPRPhase newPhase, DateTime timestamp) {
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
      value: _lastCompressionDepth,
    ));

    debugPrint('Phase: ${previousPhase.name} -> ${newPhase.name} (depth: ${_lastCompressionDepth.toStringAsFixed(1)}mm)');
  }

  /// Update active time tracking for CCF calculation
  void _updateActiveTimeTracking(
      CPRPhase fromPhase, CPRPhase toPhase, DateTime timestamp) {
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

    if ((_currentPhase == CPRPhase.compression ||
        _currentPhase == CPRPhase.recoil) &&
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

    debugPrint('Cycle $_cycleCount completed');
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

    _lastCalculatedCCF =
        _totalActiveTime.inMilliseconds / totalSessionTime.inMilliseconds;

    if (_currentPhase == CPRPhase.compression ||
        _currentPhase == CPRPhase.recoil) {
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

  /// Calculate compression rate
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
          _currentCompressionRate =
              alpha * instantRate + (1 - alpha) * _currentCompressionRate!;
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

  /// Emit current metrics
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

  /// Reset all state
  void reset() {
    _rawSensorBuffer.clear();
    _filteredBuffer.clear();
    _compressionTimestamps.clear();

    _lastCompressionCount = 0;
    _lastCompressionDepth = 0.0;

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

    debugPrint('ProcessingEngine reset');
  }

  /// Clean up resources
  void dispose() {
    _metricsController.close();
    _alertController.close();
    _phaseChangeController.close();
    _peakDetectionController.close();
  }
}

// Supporting classes
class SensorDataPoint {
  final DateTime timestamp;
  final double value;

  const SensorDataPoint(this.timestamp, this.value);
}

class PeakTrough {
  final DateTime timestamp;
  final double value;
  final PeakTroughType type;
  final bool isGood;

  const PeakTrough({
    required this.timestamp,
    required this.value,
    required this.type,
    required this.isGood,
  });
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
