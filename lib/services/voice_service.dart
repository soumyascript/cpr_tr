//cpr_training_app/lib/services/voice_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  static VoiceService get instance => _instance;

  final SpeechToText _speechToText = SpeechToText();
  bool _isListening = false;
  bool _isAvailable = false;
  String _lastWords = '';
  Timer? _restartTimer;
  bool _continuousListening = false;
  int _errorBackoffDelay = 500;
  int _consecutiveNoMatchCount = 0;

  // Callbacks
  Function(String)? _onResult;
  Function(String)? _onError;

  // Voice command patterns with variations
  static const List<String> _startCommands = [
    'drish start cpr',
    'start cpr',
    'begin cpr',
    'start session',
    'begin session',
    'commence cpr',
    'initiate cpr',
    'cpr start',
    'start compression',
    'begin compression',
    'drish begin cpr',
  ];

  static const List<String> _stopCommands = [
    'drish stop cpr',
    'stop cpr',
    'end cpr',
    'stop session',
    'end session',
    'halt cpr',
    'cease cpr',
    'finish cpr',
    'cpr stop',
    'stop compression',
    'end compression',
    'drish end cpr',
  ];

  VoiceService._internal();

  // Initialize speech recognition
  Future<void> initialize() async {
    try {
      _isAvailable = await _speechToText.initialize(
        onError: (error) => _handleError(error.errorMsg),
        onStatus: (status) => _handleStatus(status),
      );

      debugPrint('VoiceService initialized. Available: $_isAvailable');
    } catch (e) {
      debugPrint('Error initializing VoiceService: $e');
      _isAvailable = false;
    }
  }

  // Start listening for voice commands
  Future<void> startListening({
    required Function(String) onResult,
    Function(String)? onError,
  }) async {
    if (!_isAvailable) {
      onError?.call('Speech recognition not available');
      return;
    }

    _onResult = onResult;
    _onError = onError;
    _continuousListening = true;
    _errorBackoffDelay = 500;
    _consecutiveNoMatchCount = 0;

    // Start the listening cycle
    _startListeningCycle();
  }

  // Internal method to handle continuous listening cycles
  Future<void> _startListeningCycle() async {
    if (!_continuousListening || !_isAvailable) {
      return;
    }

    // Add safety check for already listening
    if (_speechToText.isListening) {
      debugPrint('SpeechToText is already listening, skipping restart');
      return;
    }

    // Cancel any existing restart timer
    _restartTimer?.cancel();

    if (_isListening) {
      debugPrint('Already listening, skipping cycle start');
      return;
    }

    // Add small safety delay
    await Future.delayed(const Duration(milliseconds: 100));

    try {
      await _speechToText.listen(
        onResult: _handleResult,
        listenFor: const Duration(seconds: 20), // Balanced listening period
        pauseFor: const Duration(seconds: 2), // Balanced pause
        partialResults: true,
        localeId: 'en_US',
        onSoundLevelChange: _handleSoundLevel,
        cancelOnError: false,
        listenMode: ListenMode.dictation,
      );

      _isListening = true;
      _errorBackoffDelay = 500;
      debugPrint('Started listening cycle (20 second window) - Dictation mode');
    } catch (e) {
      debugPrint('Error starting listening cycle: $e');
      _isListening = false;

      // Schedule restart after error with backoff
      if (_continuousListening) {
        _scheduleRestart(_errorBackoffDelay);
        // Increase backoff for next error (max 8 seconds)
        _errorBackoffDelay = (_errorBackoffDelay * 2).clamp(500, 8000);
      }
    }
  }

  // Handle sound level changes for better debugging
  void _handleSoundLevel(double level) {
    // You can use this to detect if there's actually audio input
    if (level > 0.1) {
      debugPrint('Audio detected - level: $level');
    }
  }

  // Stop listening
  Future<void> stopListening() async {
    debugPrint('Stopping voice listening');
    _continuousListening = false;
    _restartTimer?.cancel();

    if (_isListening) {
      try {
        await _speechToText.stop();
      } catch (e) {
        debugPrint('Error stopping speech recognition: $e');
      }
    }

    _isListening = false;
    _onResult = null;
    _onError = null;
    _errorBackoffDelay = 500;
    _consecutiveNoMatchCount = 0;

    debugPrint('Voice listening stopped completely');
  }

  // Handle speech recognition result
  void _handleResult(result) {
    final words = result.recognizedWords.toLowerCase().trim();
    _lastWords = words;

    debugPrint('Speech result: "$words" (final: ${result.finalResult})');

    // Only process meaningful input (not empty or very short)
    if (words.length < 3) {
      debugPrint('Ignoring short/unclear input');
      if (result.finalResult && _continuousListening) {
        _scheduleRestart(300);
      }
      return;
    }

    // Check for command matches
    final command = _identifyCommand(words);
    if (command != null) {
      debugPrint('Command identified: $command');
      _consecutiveNoMatchCount = 0; // Reset counter on successful match
      _onResult?.call(command);

      if (result.finalResult && _continuousListening) {
        _scheduleRestart(300);
      }
    } else {
      // No command found
      _consecutiveNoMatchCount++;
      debugPrint('No command match found (count: $_consecutiveNoMatchCount)');

      // If too many consecutive no-matches, adjust strategy
      if (_consecutiveNoMatchCount > 5) {
        debugPrint(
            'Many consecutive no-matches, considering environmental factors');
        // Could adjust sensitivity or provide feedback here
      }

      if (result.finalResult && _continuousListening) {
        _scheduleRestart(300);
      }
    }
  }

  // Handle speech recognition error
  void _handleError(String error) {
    debugPrint('Speech recognition error: $error');
    _isListening = false;

    // Handle "no match" errors specifically
    if (error.toLowerCase().contains('no match') ||
        error.toLowerCase().contains('no_match')) {
      debugPrint('No speech detected - this is normal in quiet environments');
      _consecutiveNoMatchCount++;
      _errorBackoffDelay = 500; // Reset backoff for no-match errors
      if (_continuousListening) {
        _scheduleRestart(300); // Quick restart for no-match
      }
      return;
    }

    // Handle other error types
    if (error.toLowerCase().contains('timeout')) {
      debugPrint('Timeout occurred - normal behavior');
      _errorBackoffDelay = 500;
      if (_continuousListening) {
        _scheduleRestart(500);
      }
    } else if (error.toLowerCase().contains('busy') ||
        error.toLowerCase().contains('client')) {
      debugPrint(
          'Busy/Client error - applying backoff: $_errorBackoffDelay ms');
      if (_continuousListening) {
        _scheduleRestart(_errorBackoffDelay);
        _errorBackoffDelay = (_errorBackoffDelay * 2).clamp(500, 8000);
      }
    } else {
      // Report other errors to the UI
      _onError?.call(error);
      _errorBackoffDelay = 500;
      if (_continuousListening) {
        _scheduleRestart(1000);
      }
    }
  }

  // Handle speech recognition status
  void _handleStatus(String status) {
    debugPrint('Speech status: $status');

    switch (status) {
      case 'notListening':
        _isListening = false;
        if (_continuousListening) {
          _scheduleRestart(300);
        }
        break;
      case 'listening':
        _isListening = true;
        _consecutiveNoMatchCount = 0; // Reset on new listening session
        break;
      case 'done':
        _isListening = false;
        if (_continuousListening) {
          _scheduleRestart(300);
        }
        break;
      case 'noSound':
        debugPrint('No sound detected - environment may be quiet');
        _consecutiveNoMatchCount++;
        break;
      case 'sound':
        debugPrint('Sound detected - processing audio');
        break;
    }
  }

  // Schedule restart of listening
  void _scheduleRestart(int delayMs) {
    if (!_continuousListening) return;

    _restartTimer?.cancel();
    _restartTimer = Timer(Duration(milliseconds: delayMs), () {
      if (_continuousListening) {
        debugPrint('Restarting listening cycle after ${delayMs}ms delay');
        _startListeningCycle();
      }
    });
  }

  // Enhanced command identification
  String? _identifyCommand(String words) {
    // Clean up the input
    final cleanedWords = words.replaceAll(RegExp(r'[^\w\s]'), '').toLowerCase();

    debugPrint('Checking for commands in: "$cleanedWords"');

    // Check for exact matches first
    for (final command in _startCommands) {
      if (cleanedWords.contains(command)) {
        return 'drish start cpr';
      }
    }

    for (final command in _stopCommands) {
      if (cleanedWords.contains(command)) {
        return 'drish stop cpr';
      }
    }

    // Check for partial matches with word boundaries
    if (_containsCommandPattern(cleanedWords, ['drish', 'start', 'cpr']) ||
        _containsCommandPattern(cleanedWords, ['start', 'cpr']) ||
        _containsCommandPattern(cleanedWords, ['begin', 'cpr']) ||
        _containsCommandPattern(cleanedWords, ['commence', 'cpr'])) {
      return 'drish start cpr';
    }

    if (_containsCommandPattern(cleanedWords, ['drish', 'stop', 'cpr']) ||
        _containsCommandPattern(cleanedWords, ['stop', 'cpr']) ||
        _containsCommandPattern(cleanedWords, ['end', 'cpr']) ||
        _containsCommandPattern(cleanedWords, ['halt', 'cpr']) ||
        _containsCommandPattern(cleanedWords, ['cease', 'cpr'])) {
      return 'drish stop cpr';
    }

    // Check for fuzzy matches as last resort
    if (_fuzzyMatchScore(cleanedWords, 'start cpr') >= 0.7 ||
        _fuzzyMatchScore(cleanedWords, 'begin cpr') >= 0.7) {
      return 'drish start cpr';
    }

    if (_fuzzyMatchScore(cleanedWords, 'stop cpr') >= 0.7 ||
        _fuzzyMatchScore(cleanedWords, 'end cpr') >= 0.7) {
      return 'drish stop cpr';
    }

    return null;
  }

  // Improved pattern matching
  bool _containsCommandPattern(String text, List<String> keywords) {
    int matchCount = 0;
    final words = text.split(' ');

    for (final keyword in keywords) {
      if (text.contains(keyword)) {
        matchCount++;
      }
    }

    // More flexible matching - require at least half the keywords
    return matchCount >= (keywords.length / 2).ceil();
  }

  // Better fuzzy matching with similarity score
  double _fuzzyMatchScore(String s1, String s2) {
    if (s1.isEmpty || s2.isEmpty) return 0.0;

    final distance = _levenshteinDistance(s1, s2);
    final maxLength = s1.length > s2.length ? s1.length : s2.length;

    if (maxLength == 0) return 1.0;

    return 1.0 - (distance / maxLength);
  }

  // Calculate Levenshtein distance
  int _levenshteinDistance(String s1, String s2) {
    if (s1.length < s2.length) return _levenshteinDistance(s2, s1);
    if (s2.isEmpty) return s1.length;

    List<int> previousRow = List.generate(s2.length + 1, (i) => i);

    for (int i = 0; i < s1.length; i++) {
      List<int> currentRow = [i + 1];

      for (int j = 0; j < s2.length; j++) {
        int insertions = previousRow[j + 1] + 1;
        int deletions = currentRow[j] + 1;
        int substitutions = previousRow[j] + (s1[i] != s2[j] ? 1 : 0);

        currentRow.add([insertions, deletions, substitutions]
            .reduce((a, b) => a < b ? a : b));
      }

      previousRow = currentRow;
    }

    return previousRow.last;
  }

  // Get available locales
  Future<List<LocaleName>> getLocales() async {
    if (!_isAvailable) return [];

    try {
      return await _speechToText.locales();
    } catch (e) {
      debugPrint('Error getting locales: $e');
      return [];
    }
  }

  // Check if speech recognition is available
  bool get isAvailable => _isAvailable;

  // Check if currently listening
  bool get isListening => _isListening;

  // Check if continuous listening is active
  bool get isContinuousListening => _continuousListening;

  // Get last recognized words
  String get lastWords => _lastWords;

  // Get consecutive no-match count
  int get consecutiveNoMatchCount => _consecutiveNoMatchCount;

  // Test speech recognition
  Future<bool> testSpeechRecognition() async {
    try {
      final isAvailable = await _speechToText.initialize();
      return isAvailable;
    } catch (e) {
      debugPrint('Speech recognition test failed: $e');
      return false;
    }
  }

  // Add method to manually reset no-match counter
  void resetNoMatchCounter() {
    _consecutiveNoMatchCount = 0;
  }

  // Dispose resources
  void dispose() {
    _continuousListening = false;
    _restartTimer?.cancel();
    stopListening();
  }
}
