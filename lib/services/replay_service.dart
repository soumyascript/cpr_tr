//cpr_training_app/lib/services/replay_service.dart
import 'dart:async';
import '../models/models.dart';
import 'db_service.dart';
import 'package:flutter/material.dart';

class ReplayService {
  static final ReplayService _instance = ReplayService._internal();
  static ReplayService get instance => _instance;

  CPRSession? _loadedSession;
  List<SensorSample>? _loadedSamples;
  List<CPREvent>? _loadedEvents;

  ReplayService._internal();

  // Load session data for replay
  Future<void> loadSession(CPRSession session) async {
    try {
      debugPrint('Loading session ${session.sessionNumber} for replay');

      _loadedSession = session;
      _loadedSamples =
          await DBService.instance.getSamplesForSession(session.id);
      _loadedEvents = await DBService.instance.getEventsForSession(session.id);

      debugPrint(
        'Loaded ${_loadedSamples?.length ?? 0} samples and ${_loadedEvents?.length ?? 0} events',
      );

      if (_loadedSamples?.isEmpty == true) {
        debugPrint(
            'Warning: No samples found for session ${session.sessionNumber}');
      }
      if (_loadedEvents?.isEmpty == true) {
        debugPrint(
            'Warning: No events found for session ${session.sessionNumber}');
      }
    } catch (e) {
      debugPrint('Error loading session for replay: $e');
      rethrow;
    }
  }

  // Get available sessions for replay
  Future<List<CPRSession>> getAvailableSessions() async {
    try {
      final sessions = await DBService.instance.getAllSessions();
      // Only return completed sessions with data
      return sessions
          .where((s) => s.endedAt != null && s.duration.inSeconds > 0)
          .toList();
    } catch (e) {
      debugPrint('Error getting available sessions: $e');
      return [];
    }
  }

  // Get replay data at specific position
  Future<ReplayData?> getDataAtPosition(
    CPRSession session,
    Duration position,
  ) async {
    if (_loadedSession?.id != session.id) {
      await loadSession(session);
    }

    if (_loadedSamples == null || _loadedEvents == null) {
      return null;
    }

    try {
      final sessionStartTime = session.startedAt;
      final absoluteTime = sessionStartTime.add(position);

      // Get samples within a reasonable window around this time
      final windowDuration = const Duration(milliseconds: 500);
      final windowStart = absoluteTime.subtract(windowDuration);
      final windowEnd = absoluteTime.add(windowDuration);

      final samplesInWindow = _loadedSamples!
          .where((sample) =>
              sample.timestamp.isAfter(windowStart) &&
              sample.timestamp.isBefore(windowEnd))
          .toList();

      // Sort samples by timestamp
      samplesInWindow.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      // Get events up to this time
      final eventsUpToNow = _loadedEvents!
          .where((event) =>
              event.timestamp.isBefore(absoluteTime) ||
              event.timestamp.isAtSameMomentAs(absoluteTime))
          .toList();

      // Sort events by timestamp
      eventsUpToNow.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      // Calculate metrics from events
      final metrics = _calculateMetricsFromEvents(eventsUpToNow, position);

      // Get current alert (most recent alert event)
      CPRAlert? currentAlert;
      try {
        final alertEvents =
            eventsUpToNow.where((event) => event.type == 'alert').toList();

        if (alertEvents.isNotEmpty) {
          final lastAlert = alertEvents.last;
          currentAlert = _parseAlertFromEvent(lastAlert);
        }
      } catch (e) {
        debugPrint('Error parsing alert: $e');
      }

      // Convert samples to graph data points with DateTime timestamps
      final sensor1Data = samplesInWindow
          .map((sample) => GraphDataPoint(
                timestamp: sample.timestamp,
                value: sample.sensor1Avg, // Use sensor1Avg
                color: Colors.blue, // Default color
              ))
          .toList();

      final sensor2Data = samplesInWindow
          .map((sample) => GraphDataPoint(
                timestamp: sample.timestamp,
                value: sample.sensor2Avg, // Use sensor2Avg
                color: Colors.red, // Default color
              ))
          .toList();

      return ReplayData(
        metrics: metrics,
        alert: currentAlert,
        sensor1Data: sensor1Data,
        sensor2Data: sensor2Data,
      );
    } catch (e) {
      debugPrint('Error getting replay data at position: $e');
      return null;
    }
  }

  // Calculate metrics from events up to current position
  CPRMetrics _calculateMetricsFromEvents(
      List<CPREvent> events, Duration position) {
    try {
      int compressionCount = 0;
      int goodCompressions = 0;
      int goodRecoils = 0;
      int recoilCount = 0;
      double totalRate = 0;
      int rateCalculations = 0;
      CPRPhase currentPhase = CPRPhase.quietude;
      double? ccf;
      int cycleNumber = 0;

      for (final event in events) {
        final payload = event.payload;

        switch (event.type) {
          case 'compression_detected':
            compressionCount++;
            if (payload['quality'] == 'good') {
              goodCompressions++;
            }
            break;

          case 'recoil_detected':
            recoilCount++;
            if (payload['quality'] == 'good') {
              goodRecoils++;
            }
            break;

          case 'rate_calculated':
            final rate = payload['rate']?.toDouble() ?? 0.0;
            if (rate > 0) {
              totalRate += rate;
              rateCalculations++;
            }
            break;

          case 'phase_change':
            final phaseName = payload['to_phase'] as String?;
            if (phaseName != null) {
              currentPhase = _parsePhase(phaseName);
            }
            break;

          case 'ccf_calculated':
            ccf = payload['ccf']?.toDouble();
            break;

          case 'cycle_end':
            cycleNumber = payload['cycle_number'] ?? cycleNumber;
            break;
        }
      }

      final averageRate =
          rateCalculations > 0 ? totalRate / rateCalculations : null;

      return CPRMetrics(
        compressionRate: averageRate,
        compressionCount: compressionCount,
        recoilCount: recoilCount,
        goodCompressions: goodCompressions,
        goodRecoils: goodRecoils,
        cycleNumber: cycleNumber,
        ccf: ccf,
        currentPhase: currentPhase,
      );
    } catch (e) {
      debugPrint('Error calculating metrics: $e');
      return const CPRMetrics();
    }
  }

  // Parse phase from string
  CPRPhase _parsePhase(String phaseName) {
    switch (phaseName.toLowerCase()) {
      case 'compression':
        return CPRPhase.compression;
      case 'recoil':
        return CPRPhase.recoil;
      case 'pause':
        return CPRPhase.pause;
      default:
        return CPRPhase.quietude;
    }
  }

  // Parse alert from event
  CPRAlert _parseAlertFromEvent(CPREvent event) {
    final payload = event.payload;
    final message = payload['message'] as String? ?? 'Alert';
    final typeString = payload['type'] as String? ?? 'go_faster';

    AlertType alertType;
    switch (typeString.toLowerCase()) {
      case 'slow_down':
        alertType = AlertType.slowDown;
        break;
      case 'be_gentle':
        alertType = AlertType.beGentle;
        break;
      case 'release_more':
        alertType = AlertType.releaseMore;
        break;
      default:
        alertType = AlertType.goFaster;
    }

    return CPRAlert(
      type: alertType,
      message: message,
      timestamp: event.timestamp,
    );
  }

  // Get session timeline markers
  Future<List<TimelineMarker>> getSessionTimelineMarkers(
      CPRSession session) async {
    if (_loadedSession?.id != session.id) {
      await loadSession(session);
    }

    if (_loadedEvents == null) return [];

    final markers = <TimelineMarker>[];

    try {
      for (final event in _loadedEvents!) {
        final position = event.timestamp.difference(session.startedAt);

        switch (event.type) {
          case 'alert':
            final message = event.payload['message'] as String? ?? 'Alert';
            markers.add(
              TimelineMarker(
                position: position,
                type: TimelineMarkerType.alert,
                label: message,
              ),
            );
            break;

          case 'cycle_end':
            final cycleNumber = event.payload['cycle_number'] ?? 0;
            markers.add(
              TimelineMarker(
                position: position,
                type: TimelineMarkerType.cycle,
                label: 'Cycle $cycleNumber',
              ),
            );
            break;

          case 'phase_change':
            if (event.payload['to_phase'] == 'pause') {
              markers.add(
                TimelineMarker(
                  position: position,
                  type: TimelineMarkerType.pause,
                  label: 'Pause',
                ),
              );
            }
            break;
        }
      }
    } catch (e) {
      debugPrint('Error creating timeline markers: $e');
    }

    // Sort markers by position
    markers.sort((a, b) => a.position.compareTo(b.position));
    return markers;
  }

  // Clear loaded session data
  void clearLoadedSession() {
    _loadedSession = null;
    _loadedSamples = null;
    _loadedEvents = null;
  }

  // Get loaded session
  CPRSession? get loadedSession => _loadedSession;

  // Check if session is loaded
  bool isSessionLoaded(CPRSession session) {
    return _loadedSession?.id == session.id;
  }
}

// Supporting classes for replay
class ReplayData {
  final CPRMetrics metrics;
  final CPRAlert? alert;
  final List<GraphDataPoint> sensor1Data;
  final List<GraphDataPoint> sensor2Data;

  const ReplayData({
    required this.metrics,
    this.alert,
    required this.sensor1Data,
    required this.sensor2Data,
  });
}

class TimelineMarker {
  final Duration position;
  final TimelineMarkerType type;
  final String label;

  const TimelineMarker({
    required this.position,
    required this.type,
    required this.label,
  });
}

enum TimelineMarkerType { alert, cycle, pause }
