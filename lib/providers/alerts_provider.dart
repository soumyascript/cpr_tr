//cpr_training_app/lib/providers/alerts_provider.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/audio_service.dart';

class AlertsProvider with ChangeNotifier {
  final AudioService _audioService =
      AudioService.instance; // Use the singleton instance

  CPRAlert? _currentAlert;
  final List<CPRAlert> _alertHistory = [];
  Timer? _alertDisplayTimer;
  StreamSubscription? _alertStreamSubscription;

  // Getters
  CPRAlert? get currentAlert => _currentAlert;
  List<CPRAlert> get alertHistory => List.unmodifiable(_alertHistory);
  bool get hasActiveAlert => _currentAlert != null;
  int get totalAlerts => _alertHistory.length;

  @override
  void dispose() {
    _alertDisplayTimer?.cancel();
    _alertStreamSubscription?.cancel();
    _audioService.dispose();
    super.dispose();
  }

  // Initialize alerts system
  Future<void> initialize() async {
    try {
      await _audioService.initialize();
      debugPrint('AlertsProvider initialized successfully');
    } catch (e) {
      debugPrint('Error initializing AlertsProvider: $e');
      // Try to reinitialize on next alert if needed
    }
  }

  // Listen to alerts from metrics provider
  void listenToAlerts(Stream<CPRAlert> alertStream) {
    _alertStreamSubscription?.cancel();
    _alertStreamSubscription = alertStream.listen((alert) {
      showAlert(alert);
    });
  }

  // Show alert
  void showAlert(CPRAlert alert) {
    _currentAlert = alert;
    _alertHistory.add(alert);

    // Keep alert history manageable
    if (_alertHistory.length > 100) {
      _alertHistory.removeRange(0, _alertHistory.length - 100);
    }

    // Play audio if available
    if (alert.audioFile != null) {
      _audioService.playAlert(alert.audioFile!);
    }

    // Clear alert after 3 seconds
    _alertDisplayTimer?.cancel();
    _alertDisplayTimer = Timer(const Duration(seconds: 3), () {
      _currentAlert = null;
      notifyListeners();
    });

    debugPrint('Alert shown: ${alert.message}');
    notifyListeners();
  }

  // Show custom alert
  void showCustomAlert(String message, AlertType type, {String? audioFile}) {
    final alert = CPRAlert(
      type: type,
      message: message,
      timestamp: DateTime.now(),
      audioFile: audioFile,
    );
    showAlert(alert);
  }

  // Clear current alert
  void clearCurrentAlert() {
    _currentAlert = null;
    _alertDisplayTimer?.cancel();
    notifyListeners();
    debugPrint('Current alert cleared');
  }

  // Clear all alerts
  void clearAlerts() {
    _currentAlert = null;
    _alertHistory.clear();
    _alertDisplayTimer?.cancel();
    notifyListeners();
    debugPrint('All alerts cleared');
  }

  // Get alert count by type
  int getAlertCountByType(AlertType type) {
    return _alertHistory.where((alert) => alert.type == type).length;
  }

  // Get recent alerts (last N)
  List<CPRAlert> getRecentAlerts({int count = 10}) {
    return _alertHistory.reversed.take(count).toList();
  }

  // Get alert statistics
  Map<AlertType, int> getAlertStatistics() {
    final stats = <AlertType, int>{};
    for (final type in AlertType.values) {
      stats[type] = getAlertCountByType(type);
    }
    return stats;
  }

  // Get alert frequency (alerts per minute)
  double getAlertFrequency({Duration? timeWindow}) {
    timeWindow ??= const Duration(minutes: 5);

    final cutoffTime = DateTime.now().subtract(timeWindow);
    final recentAlerts = _alertHistory
        .where((alert) => alert.timestamp.isAfter(cutoffTime))
        .length;

    return recentAlerts / timeWindow.inMinutes;
  }

  // Check if specific alert type was recent
  bool wasRecentAlert(AlertType type, {Duration? within}) {
    within ??= const Duration(seconds: 10);

    final cutoffTime = DateTime.now().subtract(within);
    return _alertHistory.any(
        (alert) => alert.type == type && alert.timestamp.isAfter(cutoffTime));
  }

  // Set audio volume
  Future<void> setAudioVolume(double volume) async {
    await _audioService.setVolume(volume);
  }

  // Get current audio volume
  double get audioVolume => _audioService.volume;

  // Check if audio is playing
  bool get isAudioPlaying => _audioService.isPlaying;

  // Stop current audio
  Future<void> stopAudio() async {
    await _audioService.stopPlayback();
  }

  // Get audio queue length
  int get audioQueueLength => _audioService.queueLength;

  // Clear audio queue
  void clearAudioQueue() {
    _audioService.clearQueue();
  }

  // Force play alert audio (ignoring cooldown)
  Future<void> forcePlayAlert(String audioFile) async {
    await _audioService.playAlert(audioFile);
  }

  // Export alert history as CSV
  String exportAlertHistoryAsCSV() {
    final buffer = StringBuffer();
    buffer.writeln('Timestamp,Type,Message');

    for (final alert in _alertHistory) {
      buffer.writeln(
          '${alert.timestamp.toIso8601String()},${alert.type.name},${alert.message}');
    }

    return buffer.toString();
  }

  // Get alert summary for debriefing
  Map<String, dynamic> getAlertSummaryForDebrief() {
    final stats = getAlertStatistics();

    return {
      'totalAlerts': totalAlerts,
      'goFasterCount': stats[AlertType.goFaster] ?? 0,
      'slowDownCount': stats[AlertType.slowDown] ?? 0,
      'beGentleCount': stats[AlertType.beGentle] ?? 0,
      'releaseMoreCount': stats[AlertType.releaseMore] ?? 0,
      'alertFrequency': getAlertFrequency(),
      'alertTypes': stats.entries
          .where((e) => e.value > 0)
          .map((e) => e.key.name)
          .toList(),
    };
  }
}
