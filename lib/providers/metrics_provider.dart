// //cpr_training_app/lib/providers/metrics_provider.dart
// import 'dart:async';
// import 'package:flutter/foundation.dart';
// import '../models/models.dart';
// import '../services/sensor_service.dart';
// import '../services/processing_engine.dart';
//
// class MetricsProvider with ChangeNotifier {
//   final ProcessingEngine _processingEngine = ProcessingEngine();
//
//   StreamSubscription? _metricsSubscription;
//   StreamSubscription? _alertSubscription;
//   StreamSubscription? _phaseChangeSubscription;
//   StreamSubscription? _peakDetectionSubscription;
//   StreamSubscription? _breathSubscription;
//
//   CPRMetrics _currentMetrics = const CPRMetrics();
//
//   CPRMetrics get currentMetrics => _currentMetrics;
//   double? get compressionRate => _currentMetrics.compressionRate;
//   int get compressionCount => _currentMetrics.compressionCount;
//   int get recoilCount => _currentMetrics.recoilCount;
//   int get goodCompressions => _currentMetrics.goodCompressions;
//   int get goodRecoils => _currentMetrics.goodRecoils;
//   int get cycleNumber => _currentMetrics.cycleNumber;
//   double? get ccf => _currentMetrics.ccf;
//   CPRPhase get currentPhase => _currentMetrics.currentPhase;
//
//   Stream<CPRAlert> get alertStream => _processingEngine.alertStream;
//   Stream<PhaseChangeEvent> get phaseChangeStream =>
//       _processingEngine.phaseChangeStream;
//   Stream<PeakTroughEvent> get peakDetectionStream =>
//       _processingEngine.peakDetectionStream;
//   Stream<BreathEvent> get breathStream => _processingEngine.breathStream;
//
//   @override
//   void dispose() {
//     _metricsSubscription?.cancel();
//     _alertSubscription?.cancel();
//     _phaseChangeSubscription?.cancel();
//     _peakDetectionSubscription?.cancel();
//     _breathSubscription?.cancel();
//     _processingEngine.dispose();
//     super.dispose();
//   }
//
//   void initialize(SystemConfig config) {
//     _processingEngine.updateConfig(config);
//
//     _metricsSubscription = _processingEngine.metricsStream.listen((metrics) {
//       _currentMetrics = metrics;
//       notifyListeners();
//     });
//
//     debugPrint('MetricsProvider initialized with enhanced peak detection');
//   }
//
//   void updateConfig(SystemConfig config) {
//     _processingEngine.updateConfig(config);
//     debugPrint('MetricsProvider config updated');
//   }
//
//   void processSensorData(SensorData data) {
//     // REMOVED THROTTLING - let ProcessingEngine handle high-frequency data
//     _processingEngine.processSensorData(
//         data.sensor1Raw.toDouble(), data.sensor2Raw.toDouble());
//   }
//
//   void reset() {
//     _processingEngine.reset();
//     _currentMetrics = const CPRMetrics();
//     notifyListeners();
//     debugPrint('MetricsProvider reset');
//   }
//
//   // NEW: Set session state for CCF calculation
//   void setSessionState(bool isActive, {DateTime? sessionStartTime}) {
//     _processingEngine.setSessionState(isActive,
//         sessionStartTime: sessionStartTime);
//     debugPrint('MetricsProvider session state updated: active=$isActive');
//   }
//
//   ProcessingEngine get processingEngine => _processingEngine;
//
//   Map<String, dynamic> getMetricsSummary() {
//     return {
//       'compressionRate': compressionRate?.toStringAsFixed(1) ?? '--',
//       'compressionCount': compressionCount,
//       'recoilCount': recoilCount,
//       'goodCompressions': goodCompressions,
//       'goodRecoils': goodRecoils,
//       'compressionAccuracy': compressionCount > 0
//           ? ((goodCompressions / compressionCount) * 100).toStringAsFixed(1)
//           : '--',
//       'recoilAccuracy': recoilCount > 0
//           ? ((goodRecoils / recoilCount) * 100).toStringAsFixed(1)
//           : '--',
//       'cycleNumber': cycleNumber,
//       'ccf': ccf != null ? (ccf! * 100).toStringAsFixed(1) : '--',
//       'currentPhase': currentPhase.name,
//     };
//   }
// }


//cpr_training_app/lib/providers/metrics_provider.dart
//cpr_training_app/lib/providers/metrics_provider.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/sensor_service.dart' as sensor; // Use prefix to avoid conflict
import '../services/processing_engine.dart';

class MetricsProvider with ChangeNotifier {
  final ProcessingEngine _processingEngine = ProcessingEngine();

  StreamSubscription? _metricsSubscription;
  StreamSubscription? _alertSubscription;
  StreamSubscription? _phaseChangeSubscription;
  StreamSubscription? _peakDetectionSubscription;

  CPRMetrics _currentMetrics = const CPRMetrics();

  CPRMetrics get currentMetrics => _currentMetrics;
  double? get compressionRate => _currentMetrics.compressionRate;
  int get compressionCount => _currentMetrics.compressionCount;
  int get recoilCount => _currentMetrics.recoilCount;
  int get goodCompressions => _currentMetrics.goodCompressions;
  int get goodRecoils => _currentMetrics.goodRecoils;
  int get cycleNumber => _currentMetrics.cycleNumber;
  double? get ccf => _currentMetrics.ccf;
  CPRPhase get currentPhase => _currentMetrics.currentPhase;

  Stream<CPRAlert> get alertStream => _processingEngine.alertStream;
  Stream<PhaseChangeEvent> get phaseChangeStream =>
      _processingEngine.phaseChangeStream;
  Stream<PeakTroughEvent> get peakDetectionStream =>
      _processingEngine.peakDetectionStream;

  @override
  void dispose() {
    _metricsSubscription?.cancel();
    _alertSubscription?.cancel();
    _phaseChangeSubscription?.cancel();
    _peakDetectionSubscription?.cancel();
    _processingEngine.dispose();
    super.dispose();
  }

  void initialize(SystemConfig config) {
    _processingEngine.updateConfig(config);

    _metricsSubscription = _processingEngine.metricsStream.listen((metrics) {
      _currentMetrics = metrics;
      notifyListeners();
    });

    debugPrint('MetricsProvider initialized');
  }

  void updateConfig(SystemConfig config) {
    _processingEngine.updateConfig(config);
    debugPrint('MetricsProvider config updated');
  }

  void processSensorData(sensor.SensorData data) {
    // Process ESP32 CSV data: Depth,Count,TiltX,TiltY
    _processingEngine.processSensorData(
      data.compressionDepth,  // Depth (double)
      data.compressionCount,  // Count (int)
      data.tiltX,             // TiltX (double)
      data.tiltY,             // TiltY (double)
    );
  }

  void reset() {
    _processingEngine.reset();
    _currentMetrics = const CPRMetrics();
    notifyListeners();
    debugPrint('MetricsProvider reset');
  }

  void setSessionState(bool isActive, {DateTime? sessionStartTime}) {
    _processingEngine.setSessionState(isActive,
        sessionStartTime: sessionStartTime);
    debugPrint('MetricsProvider session state updated: active=$isActive');
  }

  ProcessingEngine get processingEngine => _processingEngine;

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
}