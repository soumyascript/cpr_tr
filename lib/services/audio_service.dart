//cpr_training_app/lib/services/audio_service.dart
import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

class AudioService {
  static AudioService? _instance;
  static AudioService get instance => _instance ??= AudioService._internal();

  late AudioPlayer _audioPlayer;
  final Queue<String> _audioQueue = Queue<String>();
  bool _isPlaying = false;
  DateTime? _lastAudioEndTime;
  Timer? _playbackTimer;
  bool _isInitialized = false;

  static const Duration _minimumGapBetweenAudio = Duration(seconds: 1);

  AudioService._internal();

  // Initialize audio service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _audioPlayer = AudioPlayer();

      // Listen to player state changes
      _audioPlayer.playerStateStream.listen((playerState) {
        debugPrint('Player state changed: ${playerState.processingState}');
        if (playerState.processingState == ProcessingState.completed) {
          _onAudioCompleted();
        }
      });

      // Listen to position stream for debugging
      _audioPlayer.positionStream.listen((position) {
        if (position.inMilliseconds > 0) {
          debugPrint('Audio position: ${position.inSeconds}s');
        }
      });

      _isInitialized = true;
      debugPrint('AudioService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing AudioService: $e');
      _isInitialized = false;
    }
  }

  // Play alert audio with cooldown
  Future<void> playAlert(String audioFilePath) async {
    if (!_isInitialized) {
      debugPrint('AudioService not initialized, attempting to initialize...');
      await initialize();
      if (!_isInitialized) {
        debugPrint('Failed to initialize AudioService');
        return;
      }
    }

    try {
      debugPrint('Attempting to play audio: $audioFilePath');

      // Check if we need to respect the minimum gap
      if (_lastAudioEndTime != null) {
        final timeSinceLastAudio =
            DateTime.now().difference(_lastAudioEndTime!);
        if (timeSinceLastAudio < _minimumGapBetweenAudio) {
          debugPrint('Queueing audio due to minimum gap restriction');
          _audioQueue.add(audioFilePath);
          _scheduleNextAudio();
          return;
        }
      }

      await _playAudioFile(audioFilePath);
    } catch (e) {
      debugPrint('Error playing alert audio: $e');
    }
  }

  // Play audio file immediately
  Future<void> _playAudioFile(String audioFilePath) async {
    if (_isPlaying) {
      debugPrint('Audio already playing, queueing: $audioFilePath');
      _audioQueue.add(audioFilePath);
      return;
    }

    try {
      _isPlaying = true;
      debugPrint('Starting playback: $audioFilePath');

      // Load and play the audio file
      await _audioPlayer.setAsset(audioFilePath);
      await _audioPlayer.setVolume(1.0); // Ensure volume is at maximum
      await _audioPlayer.play();

      debugPrint('Audio playback started successfully: $audioFilePath');
    } catch (e) {
      debugPrint('Error playing audio file $audioFilePath: $e');
      _isPlaying = false;
      _processNextInQueue();
    }
  }

  // Handle audio completion
  void _onAudioCompleted() {
    debugPrint('Audio playback completed');
    _isPlaying = false;
    _lastAudioEndTime = DateTime.now();

    // Small delay before processing next to ensure proper cleanup
    Timer(const Duration(milliseconds: 100), () {
      _processNextInQueue();
    });
  }

  // Process next audio in queue
  void _processNextInQueue() {
    if (_audioQueue.isNotEmpty && !_isPlaying) {
      final nextAudio = _audioQueue.removeFirst();
      debugPrint('Processing next audio in queue: $nextAudio');

      // Check if we need to wait for minimum gap
      if (_lastAudioEndTime != null) {
        final timeSinceLastAudio =
            DateTime.now().difference(_lastAudioEndTime!);
        if (timeSinceLastAudio < _minimumGapBetweenAudio) {
          final waitTime = _minimumGapBetweenAudio - timeSinceLastAudio;
          debugPrint(
              'Scheduling audio playback with delay: ${waitTime.inMilliseconds}ms');
          _scheduleAudioPlayback(nextAudio, waitTime);
          return;
        }
      }

      _playAudioFile(nextAudio);
    }
  }

  // Schedule next audio playback
  void _scheduleNextAudio() {
    if (_playbackTimer != null || _audioQueue.isEmpty) return;

    final nextAudio = _audioQueue.first;
    final waitTime = _lastAudioEndTime != null
        ? _minimumGapBetweenAudio -
            DateTime.now().difference(_lastAudioEndTime!)
        : Duration.zero;

    if (waitTime > Duration.zero) {
      _scheduleAudioPlayback(nextAudio, waitTime);
    } else {
      _processNextInQueue();
    }
  }

  // Schedule audio playback with delay
  void _scheduleAudioPlayback(String audioFilePath, Duration delay) {
    _playbackTimer?.cancel();
    _playbackTimer = Timer(delay, () {
      _playbackTimer = null;
      if (_audioQueue.isNotEmpty && _audioQueue.first == audioFilePath) {
        _audioQueue.removeFirst();
        _playAudioFile(audioFilePath);
      }
    });
  }

  // Stop current playback
  Future<void> stopPlayback() async {
    try {
      await _audioPlayer.stop();
      _audioQueue.clear();
      _playbackTimer?.cancel();
      _playbackTimer = null;
      _isPlaying = false;

      debugPrint('Audio playback stopped');
    } catch (e) {
      debugPrint('Error stopping audio playback: $e');
    }
  }

  // Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    try {
      final clampedVolume = volume.clamp(0.0, 1.0);
      await _audioPlayer.setVolume(clampedVolume);
      debugPrint('Audio volume set to: $clampedVolume');
    } catch (e) {
      debugPrint('Error setting volume: $e');
    }
  }

  // Get current volume
  double get volume {
    try {
      return _audioPlayer.volume;
    } catch (e) {
      debugPrint('Error getting volume: $e');
      return 1.0;
    }
  }

  // Check if audio is currently playing
  bool get isPlaying => _isPlaying;

  // Get queue length
  int get queueLength => _audioQueue.length;

  // Clear audio queue
  void clearQueue() {
    _audioQueue.clear();
    _playbackTimer?.cancel();
    _playbackTimer = null;
    debugPrint('Audio queue cleared');
  }

  // Test audio playback (for debugging)
  Future<bool> testAudioPlayback(String audioFilePath) async {
    try {
      debugPrint('Testing audio playback: $audioFilePath');
      await _audioPlayer.setAsset(audioFilePath);
      await _audioPlayer.play();

      // Wait a bit to see if it starts playing
      await Future.delayed(const Duration(seconds: 1));

      final isPlaying = _audioPlayer.playing;
      debugPrint('Audio test result - Is playing: $isPlaying');

      if (isPlaying) {
        await _audioPlayer.stop();
      }

      return isPlaying;
    } catch (e) {
      debugPrint('Audio test failed: $e');
      return false;
    }
  }

  // Dispose resources
  void dispose() {
    _playbackTimer?.cancel();
    _audioQueue.clear();
    _audioPlayer.dispose();
    _isInitialized = false;
    debugPrint('AudioService disposed');
  }
}
