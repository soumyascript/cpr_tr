

// Dual BLE

// cpr_training_app/lib/providers/metrics_provider.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/sensor_service.dart' as sensor_service; // Use prefix to avoid conflict
import '../services/processing_engine.dart';

class MetricsProvider with ChangeNotifier {
  // FIXED: Remove the local instance and use dependency injection
  ProcessingEngine? _processingEngine;

  StreamSubscription? _metricsSubscription;
  StreamSubscription? _alertSubscription;
  StreamSubscription? _phaseChangeSubscription;
  StreamSubscription? _peakDetectionSubscription;
  StreamSubscription? _multiDeviceSubscription;

  CPRMetrics _currentMetrics = const CPRMetrics();

  // NEW: Store session metrics when session ends
  CPRMetrics? _lastSessionMetrics;

  // UPDATED: Getter that returns current or last session metrics
  CPRMetrics get currentMetrics => _currentMetrics.compressionCount > 0 ? _currentMetrics :
  (_lastSessionMetrics ?? const CPRMetrics());

  // UPDATED: All getters now use the display metrics
  double? get compressionRate => currentMetrics.compressionRate;
  int get compressionCount => currentMetrics.compressionCount;
  int get recoilCount => currentMetrics.recoilCount;
  int get goodCompressions => currentMetrics.goodCompressions;
  int get goodRecoils => currentMetrics.goodRecoils;
  int get cycleNumber => currentMetrics.cycleNumber;
  double? get ccf => currentMetrics.ccf;
  CPRPhase get currentPhase => currentMetrics.currentPhase;

  // NEW: Getter for last session metrics (for debrief screen)
  CPRMetrics? get lastSessionMetrics => _lastSessionMetrics;

  // FIXED: Handle null processing engine gracefully
  Stream<CPRAlert> get alertStream => _processingEngine?.alertStream ?? const Stream<CPRAlert>.empty();
  Stream<PhaseChangeEvent> get phaseChangeStream =>
      _processingEngine?.phaseChangeStream ?? const Stream<PhaseChangeEvent>.empty();
  Stream<PeakTroughEvent> get peakDetectionStream =>
      _processingEngine?.peakDetectionStream ?? const Stream<PeakTroughEvent>.empty();
  Stream<MultiDeviceData> get multiDeviceStream => _processingEngine?.multiDeviceStream ?? const Stream<MultiDeviceData>.empty();

  @override
  void dispose() {
    _metricsSubscription?.cancel();
    _alertSubscription?.cancel();
    _phaseChangeSubscription?.cancel();
    _peakDetectionSubscription?.cancel();
    _multiDeviceSubscription?.cancel();
    // FIXED: Don't dispose the processing engine here - it's managed by the provider
    super.dispose();
  }

  // NEW METHOD: Connect to shared ProcessingEngine instance
  void setProcessingEngine(ProcessingEngine processingEngine) {
    _processingEngine = processingEngine;

    // Listen to metrics stream from the shared ProcessingEngine
    _metricsSubscription = _processingEngine!.metricsStream.listen((metrics) {
      _currentMetrics = metrics;
      notifyListeners();
    });

    debugPrint('MetricsProvider connected to shared ProcessingEngine');
  }

  void initialize(SystemConfig config) {
    // FIXED: Only update config if processing engine is available
    _processingEngine?.updateConfig(config);
    debugPrint('MetricsProvider initialized');
  }

  void updateConfig(SystemConfig config) {
    _processingEngine?.updateConfig(config);
    debugPrint('MetricsProvider config updated');
  }

  void processSensorData(sensor_service.SensorData data) {
    // FIXED: Use the shared processing engine
    _processingEngine?.processSensorDataFromDevice(data);
  }

  void reset() {
    _processingEngine?.reset();
    _currentMetrics = const CPRMetrics();
    notifyListeners();
    debugPrint('MetricsProvider reset');
  }

  // NEW: Method to finalize session metrics (called when session ends)
  void finalizeSessionMetrics() {
    _lastSessionMetrics = _currentMetrics;
    debugPrint('Session metrics finalized: ${_lastSessionMetrics?.compressionCount} compressions, rate: ${_lastSessionMetrics?.compressionRate}');
  }

  // NEW: Method to clear last session metrics (called when starting new session)
  void clearSessionMetrics() {
    _lastSessionMetrics = null;
    debugPrint('Previous session metrics cleared');
  }

  void setSessionState(bool isActive, {DateTime? sessionStartTime}) {
    _processingEngine?.setSessionState(isActive,
        sessionStartTime: sessionStartTime);
    debugPrint('MetricsProvider session state updated: active=$isActive');
  }

  ProcessingEngine? get processingEngine => _processingEngine;

  Map<String, dynamic> getMetricsSummary() {
    return {
      'compressionRate': compressionRate?.toStringAsFixed(1) ?? '--',
      'compressionCount': compressionCount,
      'recoilCount': recoilCount,
      'goodCompressions': goodCompressions,
      'goodRecoils': goodRecoils,
      'compressionAccuracy': compressionCount > 0
          ? ((goodCompressions / compressionCount) * 100).toStringAsFixed(1)
          : '--',
      'recoilAccuracy': recoilCount > 0
          ? ((goodRecoils / recoilCount) * 100).toStringAsFixed(1)
          : '--',
      'cycleNumber': cycleNumber,
      'ccf': ccf != null ? (ccf! * 100).toStringAsFixed(1) : '--',
      'currentPhase': currentPhase.name,
    };
  }

  // NEW: Get multi-device data for UI
  Map<String, Map<String, dynamic>> getAllDevicesData() {
    return _processingEngine?.getAllDevicesData() ?? {};
  }

  // NEW: Get specific device data
  Map<String, dynamic> getDeviceData(String deviceId) {
    return _processingEngine?.getDeviceData(deviceId) ?? {};
  }

  // NEW: Get number of active devices
  int get activeDevicesCount => _processingEngine?.activeDevicesCount ?? 0;
}