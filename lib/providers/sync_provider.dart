//cpr_training_app/lib/providers/sync_provider.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/sync_service.dart';
import '../services/db_service.dart';
import '../models/models.dart';

class SyncProvider with ChangeNotifier {
  final SyncService _syncService = SyncService.instance;

  bool _isSyncing = false;
  double _syncProgress = 0.0;
  String _syncStatus = 'Idle';
  DateTime? _lastSyncTime;
  int _pendingSessions = 0;
  String? _syncError;

  Timer? _autoSyncTimer;
  Timer? _statusCheckTimer;

  // Getters
  bool get isSyncing => _isSyncing;
  double get syncProgress => _syncProgress;
  String get syncStatus => _syncStatus;
  DateTime? get lastSyncTime => _lastSyncTime;
  int get pendingSessions => _pendingSessions;
  String? get syncError => _syncError;
  bool get canSync => _syncService.canSync;
  bool get hasError => _syncError != null;

  @override
  void dispose() {
    _autoSyncTimer?.cancel();
    _statusCheckTimer?.cancel();
    super.dispose();
  }

  // Initialize sync provider
  Future<void> initialize(CloudConfig? cloudConfig) async {
    if (cloudConfig != null) {
      _syncService.initialize(cloudConfig);
    }

    await _loadSyncStatus();
    await _updatePendingSessions();
    _startAutoSyncTimer();
    _startStatusCheckTimer();

    debugPrint('SyncProvider initialized');
  }

  // Update cloud configuration
  void updateCloudConfig(CloudConfig cloudConfig) {
    _syncService.updateConfig(cloudConfig);
    debugPrint('Sync provider config updated');
  }

  // Start manual sync
  Future<void> startManualSync() async {
    if (_isSyncing) {
      debugPrint('Sync already in progress');
      return;
    }

    _clearError();

    try {
      _setSyncStatus(true, 'Starting manual sync...', 0.0);

      await _syncService.syncAllPendingSessions(
        onProgress: (progress, status) {
          _syncProgress = progress;
          _syncStatus = status;
          notifyListeners();
        },
      );

      _lastSyncTime = DateTime.now();
      await _saveSyncStatus();
      await _updatePendingSessions();
      _setSyncStatus(false, 'Manual sync completed', 1.0);

      debugPrint('Manual sync completed successfully');
    } catch (e) {
      _syncError = e.toString();
      _setSyncStatus(false, 'Sync failed', 0.0);
      debugPrint('Manual sync failed: $e');
      rethrow;
    }
  }

  // Check and start auto sync if conditions are met
  Future<void> checkAutoSync() async {
    if (_isSyncing) return;

    try {
      final shouldAutoSync = await _syncService.shouldAutoSync();
      if (shouldAutoSync) {
        await _startAutoSync();
      }
    } catch (e) {
      debugPrint('Error checking auto sync: $e');
    }
  }

  // Test cloud connection
  Future<bool> testCloudConnection() async {
    try {
      _clearError();
      _setSyncStatus(true, 'Testing connection...', 0.0);

      final result = await _syncService.testConnection();

      _setSyncStatus(
          false, result ? 'Connection successful' : 'Connection failed', 1.0);

      if (!result) {
        _syncError = 'Cloud connection test failed';
      }

      return result;
    } catch (e) {
      _syncError = 'Connection test error: ${e.toString()}';
      _setSyncStatus(false, 'Connection test failed', 0.0);
      debugPrint('Connection test failed: $e');
      return false;
    }
  }

  // Start auto sync
  Future<void> _startAutoSync() async {
    if (_isSyncing) return;

    _clearError();

    try {
      _setSyncStatus(true, 'Auto-syncing data...', 0.0);

      await _syncService.syncAllPendingSessions(
        onProgress: (progress, status) {
          _syncProgress = progress;
          _syncStatus = status;
          notifyListeners();
        },
      );

      _lastSyncTime = DateTime.now();
      await _saveSyncStatus();
      await _updatePendingSessions();
      _setSyncStatus(false, 'Auto-sync completed', 1.0);

      debugPrint('Auto-sync completed successfully');
    } catch (e) {
      _syncError = 'Auto-sync failed: ${e.toString()}';
      _setSyncStatus(false, 'Auto-sync failed', 0.0);
      debugPrint('Auto-sync error: $e');
    }
  }

  // Update pending sessions count
  Future<void> _updatePendingSessions() async {
    try {
      final count = await _syncService.getPendingSessionsCount();
      if (_pendingSessions != count) {
        _pendingSessions = count;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating pending sessions count: $e');
    }
  }

  // Set sync status
  void _setSyncStatus(bool syncing, String status, double progress) {
    _isSyncing = syncing;
    _syncStatus = status;
    _syncProgress = progress;

    if (!syncing) {
      _syncProgress = 0.0;
    }

    notifyListeners();
  }

  // Clear error state
  void _clearError() {
    if (_syncError != null) {
      _syncError = null;
      notifyListeners();
    }
  }

  // Start auto-sync timer
  void _startAutoSyncTimer() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (!_isSyncing) {
        checkAutoSync();
      }
    });
  }

  // Start status check timer
  void _startStatusCheckTimer() {
    _statusCheckTimer?.cancel();
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _updatePendingSessions();
    });
  }

  // Load sync status from storage
  Future<void> _loadSyncStatus() async {
    try {
      final lastSyncString =
          await DBService.instance.getKeyValue('last_sync_time');
      if (lastSyncString != null) {
        _lastSyncTime = DateTime.tryParse(lastSyncString);
      }

      debugPrint('Loaded sync status: last sync = $_lastSyncTime');
    } catch (e) {
      debugPrint('Error loading sync status: $e');
    }
  }

  // Save sync status to storage
  Future<void> _saveSyncStatus() async {
    try {
      if (_lastSyncTime != null) {
        await DBService.instance.saveKeyValue(
          'last_sync_time',
          _lastSyncTime!.toIso8601String(),
        );
      }
    } catch (e) {
      debugPrint('Error saving sync status: $e');
    }
  }

  // Get sync statistics
  Map<String, dynamic> getSyncStatistics() {
    return {
      'isSyncing': _isSyncing,
      'pendingSessions': _pendingSessions,
      'lastSyncTime': _lastSyncTime?.toIso8601String(),
      'syncProgress': _syncProgress,
      'syncStatus': _syncStatus,
      'hasError': hasError,
      'syncError': _syncError,
      'canSync': canSync,
    };
  }

  // Get time since last sync
  Duration? get timeSinceLastSync {
    if (_lastSyncTime == null) return null;
    return DateTime.now().difference(_lastSyncTime!);
  }

  // Get formatted time since last sync
  String get formattedTimeSinceLastSync {
    final duration = timeSinceLastSync;
    if (duration == null) return 'Never';

    if (duration.inDays > 0) {
      return '${duration.inDays} day${duration.inDays > 1 ? 's' : ''} ago';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} hour${duration.inHours > 1 ? 's' : ''} ago';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes} minute${duration.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  // Check if sync is needed
  bool get isSyncNeeded => _pendingSessions > 0;

  // Check if sync is overdue (more than configured interval)
  bool get isSyncOverdue {
    if (_lastSyncTime == null) return _pendingSessions > 0;

    final duration = timeSinceLastSync;
    if (duration == null) return false;

    // Consider overdue if more than 1 hour since last sync and have pending sessions
    return duration.inHours > 1 && _pendingSessions > 0;
  }

  // Force refresh of sync status
  Future<void> refreshSyncStatus() async {
    await _updatePendingSessions();
    notifyListeners();
  }

  // Retry last failed sync
  Future<void> retrySync() async {
    _clearError();
    await startManualSync();
  }

  // Cancel current sync (if possible)
  void cancelSync() {
    if (_isSyncing) {
      _setSyncStatus(false, 'Sync cancelled', 0.0);
      debugPrint('Sync cancelled by user');
    }
  }

  // Get sync health status
  SyncHealthStatus get syncHealthStatus {
    if (hasError) {
      return SyncHealthStatus.error;
    } else if (isSyncOverdue) {
      return SyncHealthStatus.warning;
    } else if (_pendingSessions == 0) {
      return SyncHealthStatus.healthy;
    } else {
      return SyncHealthStatus.pending;
    }
  }

  // Get sync health message
  String get syncHealthMessage {
    switch (syncHealthStatus) {
      case SyncHealthStatus.healthy:
        return 'All sessions synced';
      case SyncHealthStatus.pending:
        return '$_pendingSessions session${_pendingSessions > 1 ? 's' : ''} pending';
      case SyncHealthStatus.warning:
        return 'Sync overdue - $_pendingSessions pending';
      case SyncHealthStatus.error:
        return 'Sync error occurred';
    }
  }

  // Schedule sync for later (when network available)
  void scheduleSync() {
    debugPrint('Sync scheduled for when network becomes available');
    // In a real implementation, you might use connectivity_plus to listen for network changes
    _setSyncStatus(false, 'Sync scheduled for later', 0.0);
  }

  // Enable/disable auto sync
  void setAutoSyncEnabled(bool enabled) {
    if (enabled) {
      _startAutoSyncTimer();
      debugPrint('Auto sync enabled');
    } else {
      _autoSyncTimer?.cancel();
      debugPrint('Auto sync disabled');
    }
  }

  // Get next auto sync time (estimated)
  DateTime? get nextAutoSyncTime {
    if (_lastSyncTime == null) return null;
    // Assume 5 minute interval for auto sync checks
    return _lastSyncTime!.add(const Duration(minutes: 5));
  }
}

// Sync health status enum
enum SyncHealthStatus {
  healthy, // All sessions synced
  pending, // Sessions waiting to sync
  warning, // Sync is overdue
  error, // Sync error occurred
}
