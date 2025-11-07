//cpr_training_app/lib/services/db_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/models.dart';

class DBService {
  static final DBService _instance = DBService._internal();
  static DBService get instance => _instance;

  Database? _database;

  DBService._internal();

  // Database configuration
  static const String _databaseName = 'cpr_training.db';
  static const int _databaseVersion = 1;

  // Table names
  static const String _sessionsTable = 'sessions';
  static const String _samplesTable = 'samples';
  static const String _eventsTable = 'events';
  static const String _configsTable = 'configs';
  static const String _kvTable = 'kv';

  // Initialize database
  Future<void> initialize() async {
    if (_database != null) return;

    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final path = join(documentsDirectory.path, _databaseName);

      debugPrint('Opening database at: $path');

      _database = await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: _createDatabase,
        onUpgrade: _upgradeDatabase,
        onOpen: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
      );

      debugPrint('Database initialized successfully');
    } catch (e) {
      debugPrint('Error initializing database: $e');
      rethrow;
    }
  }

  // Create database tables
  Future<void> _createDatabase(Database db, int version) async {
    debugPrint('Creating database tables...');

    // Sessions table
    await db.execute('''
      CREATE TABLE $_sessionsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_number INTEGER UNIQUE NOT NULL,
        started_at INTEGER NOT NULL,
        ended_at INTEGER,
        duration_ms INTEGER,
        synced INTEGER DEFAULT 0,
        notes TEXT,
        app_version TEXT NOT NULL
      )
    ''');

    // Samples table
    await db.execute('''
      CREATE TABLE $_samplesTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL,
        ts_ms INTEGER NOT NULL,
        s1_raw INTEGER NOT NULL,
        s2_raw INTEGER NOT NULL,
        s1_avg REAL NOT NULL,
        s2_avg REAL NOT NULL,
        FOREIGN KEY (session_id) REFERENCES $_sessionsTable (id) ON DELETE CASCADE
      )
    ''');

    // Events table
    await db.execute('''
      CREATE TABLE $_eventsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL,
        ts_ms INTEGER NOT NULL,
        type TEXT NOT NULL,
        payload TEXT NOT NULL,
        FOREIGN KEY (session_id) REFERENCES $_sessionsTable (id) ON DELETE CASCADE
      )
    ''');

    // Configs table
    await db.execute('''
      CREATE TABLE $_configsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        kind TEXT NOT NULL,
        json TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    // Key-value table
    await db.execute('''
      CREATE TABLE $_kvTable (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // Create indexes
    await db.execute(
      'CREATE INDEX idx_samples_session_ts ON $_samplesTable (session_id, ts_ms)',
    );
    await db.execute(
      'CREATE INDEX idx_events_session_ts ON $_eventsTable (session_id, ts_ms)',
    );
    await db.execute(
      'CREATE INDEX idx_sessions_number ON $_sessionsTable (session_number)',
    );
    await db.execute(
      'CREATE INDEX idx_sessions_synced ON $_sessionsTable (synced)',
    );

    debugPrint('Database tables created successfully');
  }

  // Upgrade database
  Future<void> _upgradeDatabase(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    debugPrint('Upgrading database from version $oldVersion to $newVersion');
    // Add migration logic here when needed
  }

  // Get database instance
  Database get database {
    if (_database == null) {
      throw Exception('Database not initialized. Call initialize() first.');
    }
    return _database!;
  }

  // SESSION OPERATIONS

  // Check if session number exists
  Future<bool> doesSessionNumberExist(int sessionNumber) async {
    final db = database;

    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_sessionsTable WHERE session_number = ?',
      [sessionNumber],
    );

    return Sqflite.firstIntValue(result) != 0;
  }

  // Insert new session
  Future<int> insertSession(CPRSession session) async {
    final db = database;

    // Auto-generate session number if not provided or if it conflicts
    int sessionNumber = session.sessionNumber;
    if (sessionNumber <= 0 || await doesSessionNumberExist(sessionNumber)) {
      final lastSessionNumber = await getLastSessionNumber();
      sessionNumber = (lastSessionNumber ?? 0) + 1;
    }

    final sessionId = await db.insert(_sessionsTable, {
      'session_number': sessionNumber,
      'started_at': session.startedAt.millisecondsSinceEpoch,
      'ended_at': session.endedAt?.millisecondsSinceEpoch,
      'duration_ms': session.durationMs,
      'synced': session.synced ? 1 : 0,
      'notes': session.notes,
      'app_version': session.appVersion,
    });

    debugPrint('Inserted session $sessionNumber with ID: $sessionId');
    return sessionId;
  }

  // Update session
  Future<void> updateSession(CPRSession session) async {
    final db = database;

    await db.update(
      _sessionsTable,
      {
        //'session_number': session.sessionNumber,
        'started_at': session.startedAt.millisecondsSinceEpoch,
        'ended_at': session.endedAt?.millisecondsSinceEpoch,
        'duration_ms': session.durationMs,
        'synced': session.synced ? 1 : 0,
        'notes': session.notes,
        'app_version': session.appVersion,
      },
      where: 'id = ?',
      whereArgs: [session.id],
    );

    debugPrint('Updated session ${session.id}');
  }

  // Get session by ID
  Future<CPRSession?> getSessionById(int id) async {
    final db = database;

    final results = await db.query(
      _sessionsTable,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (results.isEmpty) return null;

    return _mapToSession(results.first);
  }

  // Get session by session number
  Future<CPRSession?> getSessionByNumber(int sessionNumber) async {
    final db = database;

    final results = await db.query(
      _sessionsTable,
      where: 'session_number = ?',
      whereArgs: [sessionNumber],
    );

    if (results.isEmpty) return null;

    return _mapToSession(results.first);
  }

  // Get recent sessions
  Future<List<CPRSession>> getRecentSessions({int limit = 10}) async {
    final db = database;

    final results = await db.query(
      _sessionsTable,
      orderBy: 'started_at DESC',
      limit: limit,
    );

    return results.map(_mapToSession).toList();
  }

  // Get all sessions
  Future<List<CPRSession>> getAllSessions() async {
    final db = database;

    final results = await db.query(
      _sessionsTable,
      orderBy: 'session_number ASC',
    );

    return results.map(_mapToSession).toList();
  }

  // Delete session
  Future<void> deleteSession(int sessionId) async {
    final db = database;

    await db.delete(_sessionsTable, where: 'id = ?', whereArgs: [sessionId]);

    debugPrint('Deleted session $sessionId');
  }

  // Get sessions count
  Future<int> getTotalSessionsCount() async {
    final db = database;

    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_sessionsTable',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Get synced sessions count
  Future<int> getSyncedSessionsCount() async {
    final db = database;

    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_sessionsTable WHERE synced = 1',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Get average session duration
  Future<double?> getAverageSessionDuration() async {
    final db = database;

    final result = await db.rawQuery(
      'SELECT AVG(duration_ms) as avg_duration FROM $_sessionsTable WHERE duration_ms IS NOT NULL',
    );

    return result.first['avg_duration'] as double?;
  }

  // Get last session number
  Future<int?> getLastSessionNumber() async {
    final db = database;

    final result = await db.rawQuery(
      'SELECT MAX(session_number) as max_number FROM $_sessionsTable',
    );
    return Sqflite.firstIntValue(result);
  }

  // Get available session numbers
  Future<List<int>> getAvailableSessionNumbers() async {
    final db = database;

    final results = await db.query(
      _sessionsTable,
      columns: ['session_number'],
      orderBy: 'session_number DESC',
    );

    return results.map((row) => row['session_number'] as int).toList();
  }

  // Mark session as synced
  Future<void> markSessionAsSynced(int sessionId) async {
    final db = database;

    await db.update(
      _sessionsTable,
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [sessionId],
    );

    debugPrint('Marked session $sessionId as synced');
  }

  // Get unsynced sessions
  Future<List<CPRSession>> getUnsyncedSessions() async {
    final db = database;

    final results = await db.query(
      _sessionsTable,
      where: 'synced = 0 AND ended_at IS NOT NULL',
      orderBy: 'started_at ASC',
    );

    return results.map(_mapToSession).toList();
  }

  // SAMPLE OPERATIONS

  // Insert sensor sample
  Future<void> insertSample(SensorSample sample) async {
    final db = database;

    await db.insert(_samplesTable, {
      'session_id': sample.sessionId,
      'ts_ms': sample.timestamp.millisecondsSinceEpoch,
      's1_raw': sample.sensor1Raw, // Make sure this is being saved
      's2_raw': sample.sensor2Raw, // Make sure this is being saved
      's1_avg': sample.sensor1Avg,
      's2_avg': sample.sensor2Avg,
    });

    debugPrint(
        'Sample saved: S1Raw=${sample.sensor1Raw}, S2Raw=${sample.sensor2Raw}');
  }

  // Insert multiple samples (batch)
  Future<void> insertSamplesBatch(List<SensorSample> samples) async {
    final db = database;

    final batch = db.batch();

    for (final sample in samples) {
      batch.insert(_samplesTable, {
        'session_id': sample.sessionId,
        'ts_ms': sample.timestamp.millisecondsSinceEpoch,
        's1_raw': sample.sensor1Raw,
        's2_raw': sample.sensor2Raw,
        's1_avg': sample.sensor1Avg,
        's2_avg': sample.sensor2Avg,
      });
    }

    await batch.commit(noResult: true);
  }

  // Get samples for session
  Future<List<SensorSample>> getSamplesForSession(
    int sessionId, {
    int? limit,
  }) async {
    final db = database;

    final results = await db.query(
      _samplesTable,
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'ts_ms ASC',
      limit: limit,
    );

    return results.map(_mapToSample).toList();
  }

  // Get samples in time range
  Future<List<SensorSample>> getSamplesInRange(
    int sessionId,
    DateTime startTime,
    DateTime endTime,
  ) async {
    final db = database;

    final results = await db.query(
      _samplesTable,
      where: 'session_id = ? AND ts_ms >= ? AND ts_ms <= ?',
      whereArgs: [
        sessionId,
        startTime.millisecondsSinceEpoch,
        endTime.millisecondsSinceEpoch,
      ],
      orderBy: 'ts_ms ASC',
    );

    return results.map(_mapToSample).toList();
  }

  // EVENT OPERATIONS

  // Insert event
  Future<void> insertEvent(CPREvent event) async {
    final db = database;

    await db.insert(_eventsTable, {
      'session_id': event.sessionId,
      'ts_ms': event.timestamp.millisecondsSinceEpoch,
      'type': event.type,
      'payload': jsonEncode(event.payload),
    });
  }

  // Get events for session
  Future<List<CPREvent>> getEventsForSession(int sessionId) async {
    final db = database;

    final results = await db.query(
      _eventsTable,
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'ts_ms ASC',
    );

    return results.map(_mapToEvent).toList();
  }

  // CONFIG OPERATIONS

  // Save configuration
  Future<void> saveConfig(
    String name,
    String kind,
    Map<String, dynamic> config,
  ) async {
    final db = database;

    await db.insert(_configsTable, {
      'name': name,
      'kind': kind,
      'json': jsonEncode(config),
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // Get configuration
  Future<Map<String, dynamic>?> getConfig(String name, String kind) async {
    final db = database;

    final results = await db.query(
      _configsTable,
      where: 'name = ? AND kind = ?',
      whereArgs: [name, kind],
      orderBy: 'created_at DESC',
      limit: 1,
    );

    if (results.isEmpty) return null;

    final jsonString = results.first['json'] as String;
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

  // KEY-VALUE OPERATIONS

  // Save key-value pair
  Future<void> saveKeyValue(String key, String value) async {
    final db = database;

    await db.insert(
      _kvTable,
      {
        'key': key,
        'value': value,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get key-value pair
  Future<String?> getKeyValue(String key) async {
    final db = database;

    final results = await db.query(
      _kvTable,
      where: 'key = ?',
      whereArgs: [key],
    );

    if (results.isEmpty) return null;
    return results.first['value'] as String;
  }

  // Delete key-value pair
  Future<void> deleteKeyValue(String key) async {
    final db = database;

    await db.delete(_kvTable, where: 'key = ?', whereArgs: [key]);
  }

  // UTILITY OPERATIONS

  // Get database size in bytes
  Future<int> getDatabaseSize() async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final path = join(documentsDirectory.path, _databaseName);
      final file = File(path);

      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      debugPrint('Error getting database size: $e');
      return 0;
    }
  }

  // Clear all data (for testing/reset)
  Future<void> clearAllData() async {
    final db = database;

    await db.delete(_samplesTable);
    await db.delete(_eventsTable);
    await db.delete(_sessionsTable);
    await db.delete(_configsTable);
    await db.delete(_kvTable);

    debugPrint('All database data cleared');
  }

  // Export session data as JSON
  Future<Map<String, dynamic>> exportSessionData(int sessionId) async {
    final session = await getSessionById(sessionId);
    if (session == null) {
      throw Exception('Session not found');
    }

    final samples = await getSamplesForSession(sessionId);
    final events = await getEventsForSession(sessionId);

    return {
      'session': session.toJson(),
      'samples': samples.map((s) => s.toJson()).toList(),
      'events': events.map((e) => e.toJson()).toList(),
      'exported_at': DateTime.now().toIso8601String(),
    };
  }

  // Get database statistics
  Future<DatabaseStatistics> getDatabaseStatistics() async {
    final db = database;

    final sessionCount = await getTotalSessionsCount();
    final syncedSessions = await getSyncedSessionsCount();

    final sampleResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_samplesTable',
    );
    final sampleCount = Sqflite.firstIntValue(sampleResult) ?? 0;

    final eventResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_eventsTable',
    );
    final eventCount = Sqflite.firstIntValue(eventResult) ?? 0;

    final configResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_configsTable',
    );
    final configCount = Sqflite.firstIntValue(configResult) ?? 0;

    final size = await getDatabaseSize();

    return DatabaseStatistics(
      totalSessions: sessionCount,
      syncedSessions: syncedSessions,
      unsyncedSessions: sessionCount - syncedSessions,
      totalSamples: sampleCount,
      totalEvents: eventCount,
      totalConfigs: configCount,
      databaseSizeBytes: size,
    );
  }

  // Purge old sessions (FIFO)
  Future<int> purgeOldSessions(int keepCount) async {
    final db = database;

    // Get session IDs to delete (oldest first, excluding synced sessions)
    final results = await db.rawQuery(
      '''
      SELECT id FROM $_sessionsTable 
      WHERE synced = 0 
      ORDER BY started_at ASC 
      LIMIT ?
    ''',
      [keepCount],
    );

    if (results.isEmpty) return 0;

    final sessionIdsToDelete = results.map((r) => r['id'] as int).toList();

    // Delete sessions and cascade delete samples/events
    int deletedCount = 0;
    for (final sessionId in sessionIdsToDelete) {
      await deleteSession(sessionId);
      deletedCount++;
    }

    debugPrint('Purged $deletedCount old sessions');
    return deletedCount;
  }

  // Vacuum database to reclaim space
  Future<void> vacuumDatabase() async {
    final db = database;
    await db.execute('VACUUM');
    debugPrint('Database vacuumed');
  }

  // MAPPING FUNCTIONS

  // Map database row to CPRSession
  CPRSession _mapToSession(Map<String, dynamic> row) {
    return CPRSession(
      id: row['id'] as int,
      sessionNumber: row['session_number'] as int,
      startedAt: DateTime.fromMillisecondsSinceEpoch(row['started_at'] as int),
      endedAt: row['ended_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(row['ended_at'] as int)
          : null,
      durationMs: row['duration_ms'] as int?,
      synced: (row['synced'] as int) == 1,
      notes: row['notes'] as String?,
      appVersion: row['app_version'] as String,
    );
  }

  // Map database row to SensorSample
  SensorSample _mapToSample(Map<String, dynamic> row) {
    return SensorSample(
      id: row['id'] as int,
      sessionId: row['session_id'] as int,
      timestamp: DateTime.fromMillisecondsSinceEpoch(row['ts_ms'] as int),
      sensor1Raw: row['s1_raw'] as int,
      sensor2Raw: row['s2_raw'] as int,
      sensor1Avg: row['s1_avg'] as double,
      sensor2Avg: row['s2_avg'] as double,
    );
  }

  // Map database row to CPREvent
  CPREvent _mapToEvent(Map<String, dynamic> row) {
    return CPREvent(
      id: row['id'] as int,
      sessionId: row['session_id'] as int,
      timestamp: DateTime.fromMillisecondsSinceEpoch(row['ts_ms'] as int),
      type: row['type'] as String,
      payload: jsonDecode(row['payload'] as String) as Map<String, dynamic>,
    );
  }

  // Close database
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      debugPrint('Database closed');
    }
  }
}

// Database statistics model
class DatabaseStatistics {
  final int totalSessions;
  final int syncedSessions;
  final int unsyncedSessions;
  final int totalSamples;
  final int totalEvents;
  final int totalConfigs;
  final int databaseSizeBytes;

  const DatabaseStatistics({
    required this.totalSessions,
    required this.syncedSessions,
    required this.unsyncedSessions,
    required this.totalSamples,
    required this.totalEvents,
    required this.totalConfigs,
    required this.databaseSizeBytes,
  });

  double get databaseSizeMB => databaseSizeBytes / (1024 * 1024);
  double get syncPercentage =>
      totalSessions > 0 ? (syncedSessions / totalSessions) * 100 : 0.0;

  @override
  String toString() {
    return 'DatabaseStatistics('
        'sessions: $totalSessions, '
        'synced: $syncedSessions, '
        'size: ${databaseSizeMB.toStringAsFixed(2)}MB'
        ')';
  }
}
