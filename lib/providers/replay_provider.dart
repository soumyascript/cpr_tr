//cpr_training_app/lib/providers/replay_provider.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/replay_service.dart';

class ReplayProvider with ChangeNotifier {
  final ReplayService _replayService;

  ReplayProvider({ReplayService? replayService})
      : _replayService = replayService ?? ReplayService.instance;

  CPRSession? _selectedSession;
  bool _isPlaying = false;
  bool _isPaused = false;
  double _playbackSpeed = 1.0;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  // Current replay state
  CPRMetrics _replayMetrics = const CPRMetrics();
  CPRAlert? _replayAlert;
  List<GraphDataPoint> _replaySensor1Data = [];
  List<GraphDataPoint> _replaySensor2Data = [];
  List<TimelineMarker> _timelineMarkers = [];

  Timer? _playbackTimer;
  bool _isLoading = false;
  String? _loadError;

  // Getters
  CPRSession? get selectedSession => _selectedSession;
  bool get isPlaying => _isPlaying;
  bool get isPaused => _isPaused;
  double get playbackSpeed => _playbackSpeed;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;
  String get formattedCurrentPosition => _formatDuration(_currentPosition);
  String get formattedTotalDuration => _formatDuration(_totalDuration);
  double get playbackProgress => _totalDuration.inMilliseconds > 0
      ? _currentPosition.inMilliseconds / _totalDuration.inMilliseconds
      : 0.0;

  CPRMetrics get replayMetrics => _replayMetrics;
  CPRAlert? get replayAlert => _replayAlert;
  List<GraphDataPoint> get replaySensor1Data => _replaySensor1Data;
  List<GraphDataPoint> get replaySensor2Data => _replaySensor2Data;
  List<TimelineMarker> get timelineMarkers => _timelineMarkers;

  bool get isLoading => _isLoading;
  String? get loadError => _loadError;
  bool get hasSession => _selectedSession != null;
  bool get canPlay => hasSession && !_isLoading && _loadError == null;
  bool get canSeek => hasSession && !_isLoading && _loadError == null;

  @override
  void dispose() {
    _playbackTimer?.cancel();
    super.dispose();
  }

  // Get available sessions for replay
  Future<List<CPRSession>> getAvailableSessions() async {
    try {
      return await _replayService.getAvailableSessions();
    } catch (e) {
      debugPrint('Error getting available sessions: $e');
      return [];
    }
  }

  // Load session for replay
  Future<void> loadSession(CPRSession session) async {
    await stopReplay();

    _isLoading = true;
    _loadError = null;
    notifyListeners();

    try {
      _selectedSession = session;
      _totalDuration = session.duration;
      _currentPosition = Duration.zero;

      // Load session data through replay service
      await _replayService.loadSession(session);

      // Load timeline markers
      _timelineMarkers =
          await _replayService.getSessionTimelineMarkers(session);

      // Initialize with starting state
      await _updateReplayState();

      debugPrint('Session ${session.sessionNumber} loaded for replay');
    } catch (e) {
      _loadError = 'Failed to load session: ${e.toString()}';
      debugPrint('Error loading session: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Start replay
  Future<void> startReplay() async {
    if (!canPlay) return;

    _isPlaying = true;
    _isPaused = false;

    _startPlaybackTimer();
    debugPrint('Replay started');
    notifyListeners();
  }

  // Pause replay
  void pauseReplay() {
    if (!_isPlaying) return;

    _isPlaying = false;
    _isPaused = true;
    _playbackTimer?.cancel();

    debugPrint('Replay paused at ${_formatDuration(_currentPosition)}');
    notifyListeners();
  }

  // Resume replay
  void resumeReplay() {
    if (!_isPaused) return;

    _isPlaying = true;
    _isPaused = false;
    _startPlaybackTimer();

    debugPrint('Replay resumed from ${_formatDuration(_currentPosition)}');
    notifyListeners();
  }

  // Stop replay
  Future<void> stopReplay() async {
    _isPlaying = false;
    _isPaused = false;
    _currentPosition = Duration.zero;
    _playbackTimer?.cancel();

    // Clear replay data
    _replayMetrics = const CPRMetrics();
    _replayAlert = null;
    _replaySensor1Data.clear();
    _replaySensor2Data.clear();

    debugPrint('Replay stopped');
    notifyListeners();
  }

  // Toggle play/pause
  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      pauseReplay();
    } else if (_isPaused) {
      resumeReplay();
    } else {
      await startReplay();
    }
  }

  // Reset to beginning
  Future<void> resetToBeginning() async {
    await seekTo(Duration.zero);
    if (_isPlaying) {
      await startReplay();
    }
  }

  // Jump to end
  Future<void> jumpToEnd() async {
    await seekTo(_totalDuration);
    if (_isPlaying) {
      pauseReplay();
    }
  }

  // Step forward (small increment)
  Future<void> stepForward() async {
    final newPosition = _currentPosition + const Duration(seconds: 1);
    await seekTo(newPosition);
  }

  // Step backward (small increment)
  Future<void> stepBackward() async {
    final newPosition = _currentPosition - const Duration(seconds: 1);
    await seekTo(newPosition);
  }

  // Seek to position
  Future<void> seekTo(Duration position) async {
    if (!canSeek) return;

    _currentPosition = _clampDuration(position, Duration.zero, _totalDuration);

    // Update replay state for new position
    await _updateReplayState();

    debugPrint('Seeked to ${_formatDuration(_currentPosition)}');
    notifyListeners();
  }

  // Helper method to clamp Duration
  Duration _clampDuration(Duration value, Duration min, Duration max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }

  // Seek to percentage (0.0 to 1.0)
  Future<void> seekToPercentage(double percentage) async {
    final position = Duration(
      milliseconds:
          (_totalDuration.inMilliseconds * percentage.clamp(0.0, 1.0)).round(),
    );
    await seekTo(position);
  }

  // Jump to next marker
  Future<void> jumpToNextMarker() async {
    final nextMarker = _timelineMarkers
        .where((marker) => marker.position > _currentPosition)
        .firstOrNull;

    if (nextMarker != null) {
      await seekTo(nextMarker.position);
      debugPrint('Jumped to next marker: ${nextMarker.label}');
    }
  }

  // Jump to previous marker
  Future<void> jumpToPreviousMarker() async {
    final previousMarker = _timelineMarkers
        .where((marker) => marker.position < _currentPosition)
        .lastOrNull;

    if (previousMarker != null) {
      await seekTo(previousMarker.position);
      debugPrint('Jumped to previous marker: ${previousMarker.label}');
    }
  }

  // Set playback speed
  void setPlaybackSpeed(double speed) {
    _playbackSpeed = speed.clamp(0.25, 4.0);

    // Restart timer with new speed if playing
    if (_isPlaying) {
      _startPlaybackTimer();
    }

    debugPrint('Playback speed set to ${_playbackSpeed}x');
    notifyListeners();
  }

  // Start playback timer
  void _startPlaybackTimer() {
    _playbackTimer?.cancel();

    final intervalMs = (100 / _playbackSpeed).round(); // 100ms base interval

    _playbackTimer =
        Timer.periodic(Duration(milliseconds: intervalMs), (timer) {
      if (!_isPlaying) {
        timer.cancel();
        return;
      }

      _currentPosition +=
          Duration(milliseconds: (100 * _playbackSpeed).round());

      if (_currentPosition >= _totalDuration) {
        _currentPosition = _totalDuration;
        stopReplay();
        return;
      }

      _updateReplayState();
    });
  }

  // Update replay state for current position - THIS WAS THE MAIN ISSUE
  Future<void> _updateReplayState() async {
    if (_selectedSession == null) return;

    try {
      final replayData = await _replayService.getDataAtPosition(
        _selectedSession!,
        _currentPosition,
      );

      if (replayData != null) {
        _replayMetrics = replayData.metrics;
        _replayAlert = replayData.alert;
        _replaySensor1Data = List.from(replayData.sensor1Data);
        _replaySensor2Data = List.from(replayData.sensor2Data);

        // Notify listeners when data is updated during playback
        if (_isPlaying) {
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error updating replay state: $e');
      _loadError = 'Error updating replay state: ${e.toString()}';
      notifyListeners();
    }
  }

  // Format duration as string
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
