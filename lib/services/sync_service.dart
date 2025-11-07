//cpr_training_app/lib/services/sync_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';
import '../models/models.dart';
import 'db_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  static SyncService get instance => _instance;

  late final Dio _dio;
  CloudConfig? _cloudConfig;
  DateTime? _lastSyncAttempt;

  SyncService._internal();

  // Initialize sync service
  void initialize(CloudConfig cloudConfig) {
    _cloudConfig = cloudConfig;

    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 60),
      ),
    );

    // Add interceptors for logging
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(requestBody: false, responseBody: false),
      );
    }

    debugPrint('SyncService initialized');
  }

  // Update cloud configuration
  void updateConfig(CloudConfig cloudConfig) {
    initialize(cloudConfig);
  }

  // Check if auto sync should run
  Future<bool> shouldAutoSync() async {
    if (_cloudConfig == null || !_cloudConfig!.isConfigured) {
      return false;
    }

    final unsyncedSessions = await DBService.instance.getUnsyncedSessions();
    if (unsyncedSessions.isEmpty) {
      return false;
    }

    // Check if enough time has passed since last sync attempt
    if (_lastSyncAttempt != null) {
      final timeSinceLastAttempt = DateTime.now().difference(_lastSyncAttempt!);
      final minInterval = Duration(minutes: _cloudConfig!.minTimeElapsed);
      if (timeSinceLastAttempt < minInterval) {
        return false;
      }
    }

    return true;
  }

  // Sync all pending sessions
  Future<void> syncAllPendingSessions({
    Function(double progress, String status)? onProgress,
  }) async {
    if (_cloudConfig == null || !_cloudConfig!.isConfigured) {
      throw Exception('Cloud configuration not set');
    }

    _lastSyncAttempt = DateTime.now();

    try {
      final unsyncedSessions = await DBService.instance.getUnsyncedSessions();

      if (unsyncedSessions.isEmpty) {
        onProgress?.call(1.0, 'No sessions to sync');
        return;
      }

      onProgress?.call(
        0.0,
        'Starting sync of ${unsyncedSessions.length} sessions...',
      );

      for (int i = 0; i < unsyncedSessions.length; i++) {
        final session = unsyncedSessions[i];
        final progress = (i + 1) / unsyncedSessions.length;

        onProgress?.call(
          progress,
          'Syncing session ${session.sessionNumber}...',
        );

        await _syncSession(session);
        await DBService.instance.markSessionAsSynced(session.id);

        // Small delay to prevent overwhelming the server
        await Future.delayed(const Duration(milliseconds: 100));
      }

      onProgress?.call(1.0, 'Sync completed successfully');
      debugPrint('Successfully synced ${unsyncedSessions.length} sessions');
    } catch (e) {
      debugPrint('Error syncing sessions: $e');
      rethrow;
    }
  }

  // Sync individual session
  Future<void> _syncSession(CPRSession session) async {
    if (_cloudConfig == null) return;

    try {
      // Export session data
      final sessionData = await DBService.instance.exportSessionData(
        session.id,
      );

      // Create upload path
      final startedAt = session.startedAt;
      final year = startedAt.year.toString();
      final month = startedAt.month.toString().padLeft(2, '0');
      final day = startedAt.day.toString().padLeft(2, '0');

      final basePath = _cloudConfig!.folderPrefix?.isNotEmpty == true
          ? '${_cloudConfig!.folderPrefix}/sessions/$year/$month/$day'
          : 'sessions/$year/$month/$day';

      final sessionFolder = '${session.sessionNumber}_${session.id}';

      // Upload files
      await _uploadToS3(
        '$basePath/$sessionFolder/session_data.json',
        jsonEncode(sessionData),
      );

      debugPrint('Uploaded session ${session.sessionNumber} to cloud');
    } catch (e) {
      debugPrint('Error syncing session ${session.sessionNumber}: $e');
      rethrow;
    }
  }

  // Upload data to S3-compatible storage - CORRECTED BASED ON ARDUINO CODE
  Future<void> _uploadToS3(String key, String data) async {
    if (_cloudConfig == null) return;

    try {
      final timestamp = DateTime.now().toUtc();
      final host = _getS3Host();
      final url = 'https://$host/$key';

      // Calculate payload hash (required for AWS signature v4)
      final payloadHash = sha256.convert(utf8.encode(data)).toString();

      // For signature calculation - these headers MUST be signed
      final headersForSigning = <String, String>{
        'host': host,
        'x-amz-content-sha256': payloadHash,
        'x-amz-date': _formatDateForS3(timestamp),
      };

      // Create authorization header
      final authHeader =
          _createS3AuthHeader('PUT', key, timestamp, data, headersForSigning);

      // Headers to actually send (don't include Host - let Dio handle it)
      final actualHeaders = <String, String>{
        'x-amz-date': _formatDateForS3(timestamp),
        'x-amz-content-sha256': payloadHash,
        'Authorization': authHeader,
        'Content-Type': 'application/json',
      };

      debugPrint('Uploading to: $url');
      debugPrint('Payload hash: $payloadHash');
      debugPrint('Actual headers: $actualHeaders');

      final response = await _dio.put(
        url,
        data: data,
        options: Options(
          headers: actualHeaders,
          contentType: 'application/json',
        ),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Upload failed with status: ${response.statusCode}');
      }

      debugPrint('Successfully uploaded: $key');
    } catch (e) {
      debugPrint('Error uploading to S3: $e');
      rethrow;
    }
  }

  // Get S3 host
  String _getS3Host() {
    if (_cloudConfig == null) return '';

    if (_cloudConfig!.provider.toLowerCase().contains('digitalocean')) {
      return '${_cloudConfig!.bucketName}.${_cloudConfig!.region}.digitaloceanspaces.com';
    } else {
      // AWS S3
      return '${_cloudConfig!.bucketName}.s3.${_cloudConfig!.region}.amazonaws.com';
    }
  }

  // Create S3 authorization header - CORRECTED BASED ON ARDUINO CODE
  String _createS3AuthHeader(
    String method,
    String key,
    DateTime timestamp,
    String body,
    Map<String, String> headers,
  ) {
    if (_cloudConfig == null) return '';

    final dateString = _formatDateForS3(timestamp);
    final dateOnly = _formatDateShort(timestamp);
    final bodyHash = sha256.convert(utf8.encode(body)).toString();

    // Create canonical headers (must be sorted alphabetically)
    final sortedHeaders = <String>[];
    final signedHeaders = <String>[];

    // Sort headers alphabetically for canonical request
    final sortedKeys = headers.keys.toList()..sort();

    for (final key in sortedKeys) {
      sortedHeaders.add('$key:${headers[key]}');
      signedHeaders.add(key);
    }

    final canonicalHeaders = '${sortedHeaders.join('\n')}\n';
    final signedHeadersString = signedHeaders.join(';');

    // Create canonical request (exactly like Arduino version)
    final canonicalRequest = [
      method,
      '/$key',
      '', // No query parameters
      canonicalHeaders,
      signedHeadersString,
      bodyHash,
    ].join('\n');

    debugPrint('Canonical request:\n$canonicalRequest');

    // Create string to sign
    const algorithm = 'AWS4-HMAC-SHA256';
    final credentialScope = '$dateOnly/${_cloudConfig!.region}/s3/aws4_request';

    final stringToSign = [
      algorithm,
      dateString,
      credentialScope,
      sha256.convert(utf8.encode(canonicalRequest)).toString(),
    ].join('\n');

    debugPrint('String to sign:\n$stringToSign');

    // Calculate signature
    final signingKey = _getSigningKey(timestamp);
    final signature =
        Hmac(sha256, signingKey).convert(utf8.encode(stringToSign)).toString();

    return '$algorithm Credential=${_cloudConfig!.accessKeyId}/$credentialScope, SignedHeaders=$signedHeadersString, Signature=$signature';
  }

  // Get signing key for S3 authentication - FIXED VERSION
  List<int> _getSigningKey(DateTime timestamp) {
    if (_cloudConfig == null) return [];

    final dateString = _formatDateShort(timestamp);

    // AWS4 signing key derivation
    final kDate = Hmac(sha256, utf8.encode('AWS4${_cloudConfig!.secretKey}'))
        .convert(utf8.encode(dateString));

    final kRegion =
        Hmac(sha256, kDate.bytes).convert(utf8.encode(_cloudConfig!.region));

    final kService = Hmac(sha256, kRegion.bytes).convert(utf8.encode('s3'));

    final kSigning =
        Hmac(sha256, kService.bytes).convert(utf8.encode('aws4_request'));

    return kSigning.bytes;
  }

  // Format date for S3 (ISO 8601 basic format) - FIXED VERSION
  String _formatDateForS3(DateTime date) {
    final utc = date.toUtc();
    return '${utc.year}'
        '${utc.month.toString().padLeft(2, '0')}'
        '${utc.day.toString().padLeft(2, '0')}'
        'T'
        '${utc.hour.toString().padLeft(2, '0')}'
        '${utc.minute.toString().padLeft(2, '0')}'
        '${utc.second.toString().padLeft(2, '0')}'
        'Z';
  }

  // Format date short (YYYYMMDD)
  String _formatDateShort(DateTime date) {
    final utc = date.toUtc();
    return '${utc.year}${utc.month.toString().padLeft(2, '0')}${utc.day.toString().padLeft(2, '0')}';
  }

  // Test cloud connection
  Future<bool> testConnection() async {
    if (_cloudConfig == null || !_cloudConfig!.isConfigured) {
      return false;
    }

    try {
      // Try to upload a small test file
      final testData = jsonEncode({
        'test': true,
        'timestamp': DateTime.now().toIso8601String(),
        'app_version': '1.0.0',
      });

      final testKey =
          'test/connection_test_${DateTime.now().millisecondsSinceEpoch}.json';
      await _uploadToS3(testKey, testData);

      debugPrint('Cloud connection test successful');
      return true;
    } catch (e) {
      debugPrint('Cloud connection test failed: $e');
      return false;
    }
  }

  // Get pending sessions count
  Future<int> getPendingSessionsCount() async {
    final unsyncedSessions = await DBService.instance.getUnsyncedSessions();
    return unsyncedSessions.length;
  }

  // Manual sync trigger
  Future<void> triggerManualSync({
    Function(double progress, String status)? onProgress,
  }) async {
    if (_cloudConfig == null || !_cloudConfig!.isConfigured) {
      throw Exception('Cloud configuration not available');
    }

    await syncAllPendingSessions(onProgress: onProgress);
  }

  // Check sync eligibility
  bool get canSync => _cloudConfig != null && _cloudConfig!.isConfigured;

  // Get last sync attempt time
  DateTime? get lastSyncAttempt => _lastSyncAttempt;
}
