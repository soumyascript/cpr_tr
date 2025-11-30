// dual ble2
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/db_service.dart';

class SessionProvider with ChangeNotifier {
  CPRSession? _currentSession;
  Timer? _sessionTimer;
  Duration _sessionDuration = Duration.zero;
  bool _isSessionActive = false;
  int _nextSessionNumber = 1;

  // PRESSURE STATE TRACKING - ADDED
  bool _isPressureActive = false;
  double _currentPressure = 0.0;

  // Getters
  CPRSession? get currentSession => _currentSession;
  bool get isSessionActive => _isSessionActive;
  Duration get sessionDuration => _sessionDuration;
  int get nextSessionNumber => _nextSessionNumber;
  String get formattedDuration => _formatDuration(_sessionDuration);

  // PRESSURE GETTERS - ADDED
  bool get isPressureActive => _isPressureActive;
  double get currentPressure => _currentPressure;

  // Initialize provider
  Future<void> initialize() async {
    await _loadNextSessionNumber();
    debugPrint(
      'SessionProvider initialized. Next session number: $_nextSessionNumber',
    );
  }

  // PRESSURE STATE MANAGEMENT - ADDED
  void updatePressureState(bool isActive, double pressure) {
    _isPressureActive = isActive;
    _currentPressure = pressure;
    notifyListeners();
  }

  // Start a new session - MODIFIED: No pressure check for starting session
  Future<CPRSession> startSession({String? notes}) async {
    if (_isSessionActive) {
      throw Exception('A session is already active');
    }

    try {
      // Create new session
      final session = CPRSession(
        id: 0, // Will be set by database
        sessionNumber: _nextSessionNumber,
        startedAt: DateTime.now(),
        notes: notes,
        appVersion: '1.0.0',
      );

      // Save to database
      final sessionId = await DBService.instance.insertSession(session);
      _currentSession = session.copyWith(id: sessionId);

      // Update state
      _isSessionActive = true;
      _sessionDuration = Duration.zero;
      _nextSessionNumber++;

      // Save next session number
      await _saveNextSessionNumber();

      // Start session timer
      _startSessionTimer();

      notifyListeners();
      debugPrint(
        'Session ${session.sessionNumber} started with ID: $sessionId',
      );

      return _currentSession!;
    } catch (e) {
      debugPrint('Error starting session: $e');
      rethrow;
    }
  }

  // UPDATED: End current session with metrics finalization
  Future<CPRSession?> endSession() async {
    if (!_isSessionActive || _currentSession == null) {
      throw Exception('No active session to end');
    }

    try {
      // Stop timer
      _stopSessionTimer();

      // Update session with end time
      final endedAt = DateTime.now();
      final duration = endedAt.difference(_currentSession!.startedAt);

      final updatedSession = _currentSession!.copyWith(
        endedAt: endedAt,
        durationMs: duration.inMilliseconds,
      );

      // Update in database
      await DBService.instance.updateSession(updatedSession);

      // NEW: Finalize metrics before updating state (this preserves the data)
      // Note: We'll call this from dashboard where we have context access

      // Update state
      _currentSession = updatedSession;
      _isSessionActive = false;

      notifyListeners();
      debugPrint(
        'Session ${updatedSession.sessionNumber} ended. Duration: ${_formatDuration(duration)}',
      );

      return _currentSession;
    } catch (e) {
      debugPrint('Error ending session: $e');
      rethrow;
    }
  }

  // Cancel current session (delete from database)
  Future<void> cancelSession() async {
    if (!_isSessionActive || _currentSession == null) {
      throw Exception('No active session to cancel');
    }

    try {
      // Stop timer
      _stopSessionTimer();

      // Delete from database
      await DBService.instance.deleteSession(_currentSession!.id);

      // Reset state
      _currentSession = null;
      _isSessionActive = false;
      _sessionDuration = Duration.zero;
      _nextSessionNumber--; // Revert session number

      // Save reverted session number
      await _saveNextSessionNumber();

      notifyListeners();
      debugPrint('Session cancelled');
    } catch (e) {
      debugPrint('Error cancelling session: $e');
      rethrow;
    }
  }

  // Update session notes
  Future<void> updateSessionNotes(String notes) async {
    if (_currentSession == null) {
      throw Exception('No active session');
    }

    try {
      final updatedSession = _currentSession!.copyWith(notes: notes);
      await DBService.instance.updateSession(updatedSession);

      _currentSession = updatedSession;
      notifyListeners();
      debugPrint('Session notes updated');
    } catch (e) {
      debugPrint('Error updating session notes: $e');
      rethrow;
    }
  }

  // Get session statistics
  Future<SessionStatistics> getSessionStatistics() async {
    try {
      final totalSessions = await DBService.instance.getTotalSessionsCount();
      final syncedSessions = await DBService.instance.getSyncedSessionsCount();
      final unsyncedSessions = totalSessions - syncedSessions;
      final averageDuration = await DBService.instance
          .getAverageSessionDuration();

      return SessionStatistics(
        totalSessions: totalSessions,
        syncedSessions: syncedSessions,
        unsyncedSessions: unsyncedSessions,
        averageDuration: Duration(milliseconds: averageDuration?.toInt() ?? 0),
        currentSessionNumber: _nextSessionNumber - 1,
      );
    } catch (e) {
      debugPrint('Error getting session statistics: $e');
      return const SessionStatistics(
        totalSessions: 0,
        syncedSessions: 0,
        unsyncedSessions: 0,
        averageDuration: Duration.zero,
        currentSessionNumber: 0,
      );
    }
  }

  // Get recent sessions
  Future<List<CPRSession>> getRecentSessions({int limit = 10}) async {
    try {
      return await DBService.instance.getRecentSessions(limit: limit);
    } catch (e) {
      debugPrint('Error getting recent sessions: $e');
      return [];
    }
  }

  // Get session by ID
  Future<CPRSession?> getSessionById(int id) async {
    try {
      return await DBService.instance.getSessionById(id);
    } catch (e) {
      debugPrint('Error getting session by ID: $e');
      return null;
    }
  }

  // Get session by session number
  Future<CPRSession?> getSessionByNumber(int sessionNumber) async {
    try {
      return await DBService.instance.getSessionByNumber(sessionNumber);
    } catch (e) {
      debugPrint('Error getting session by number: $e');
      return null;
    }
  }

  // Delete session
  Future<void> deleteSession(int sessionId) async {
    try {
      await DBService.instance.deleteSession(sessionId);
      debugPrint('Session $sessionId deleted');
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting session: $e');
      rethrow;
    }
  }

  // Check if session number exists
  Future<bool> sessionNumberExists(int sessionNumber) async {
    try {
      final session = await getSessionByNumber(sessionNumber);
      return session != null;
    } catch (e) {
      debugPrint('Error checking session number existence: $e');
      return false;
    }
  }

  // Get available session numbers for replay
  Future<List<int>> getAvailableSessionNumbers() async {
    try {
      return await DBService.instance.getAvailableSessionNumbers();
    } catch (e) {
      debugPrint('Error getting available session numbers: $e');
      return [];
    }
  }

  // Start session timer (updates duration every second)
  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentSession != null && _isSessionActive) {
        _sessionDuration = DateTime.now().difference(
          _currentSession!.startedAt,
        );
        notifyListeners();
      } else {
        timer.cancel();
      }
    });
  }

  // Stop session timer
  void _stopSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = null;
  }

  // Load next session number from storage
  Future<void> _loadNextSessionNumber() async {
    try {
      final lastSessionNumber = await DBService.instance.getLastSessionNumber();
      _nextSessionNumber = (lastSessionNumber ?? 0) + 1;
    } catch (e) {
      debugPrint('Error loading next session number: $e');
      _nextSessionNumber = 1;
    }
  }

  // Save next session number to storage
  Future<void> _saveNextSessionNumber() async {
    try {
      await DBService.instance.saveKeyValue(
        'next_session_number',
        _nextSessionNumber.toString(),
      );
    } catch (e) {
      debugPrint('Error saving next session number: $e');
    }
  }

  // Format duration as string
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  // Get session time for display (MM:SS format)
  String getSessionTimeDisplay() {
    final minutes = _sessionDuration.inMinutes;
    final seconds = _sessionDuration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // Get session elapsed time in milliseconds
  int getSessionElapsedMs() {
    if (!_isSessionActive || _currentSession == null) {
      return 0;
    }
    return DateTime.now().difference(_currentSession!.startedAt).inMilliseconds;
  }

  // Check if we can start a new session
  bool canStartSession() {
    return !_isSessionActive;
  }

  // Check if we can end current session
  bool canEndSession() {
    return _isSessionActive && _currentSession != null;
  }

  // Get session progress (for sessions with target duration)
  double getSessionProgress({Duration? targetDuration}) {
    if (!_isSessionActive || targetDuration == null) {
      return 0.0;
    }
    return (_sessionDuration.inMilliseconds / targetDuration.inMilliseconds)
        .clamp(0.0, 1.0);
  }

  // Reset session state (for testing or emergency reset)
  Future<void> resetSessionState() async {
    try {
      _stopSessionTimer();
      _currentSession = null;
      _isSessionActive = false;
      _sessionDuration = Duration.zero;

      await _loadNextSessionNumber(); // Reload from database

      notifyListeners();
      debugPrint('Session state reset');
    } catch (e) {
      debugPrint('Error resetting session state: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _stopSessionTimer();
    super.dispose();
  }
}

// Session statistics model
class SessionStatistics {
  final int totalSessions;
  final int syncedSessions;
  final int unsyncedSessions;
  final Duration averageDuration;
  final int currentSessionNumber;

  const SessionStatistics({
    required this.totalSessions,
    required this.syncedSessions,
    required this.unsyncedSessions,
    required this.averageDuration,
    required this.currentSessionNumber,
  });

  double get syncPercentage {
    if (totalSessions == 0) return 0.0;
    return (syncedSessions / totalSessions) * 100;
  }

  String get formattedAverageDuration {
    final minutes = averageDuration.inMinutes;
    final seconds = averageDuration.inSeconds.remainder(60);
    return '${minutes}m ${seconds}s';
  }

  bool get hasPendingSync => unsyncedSessions > 0;
}