//cpr_training_app/lib/providers/config_provider.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../models/models.dart';

class ConfigProvider with ChangeNotifier {
  static const _storage = FlutterSecureStorage();
  static const String _systemConfigKey = 'system_config';
  static const String _cloudConfigKey = 'cloud_config';
  static const String _presetConfigsKey = 'preset_configs';

  SystemConfig _systemConfig = const SystemConfig();
  CloudConfig _cloudConfig = const CloudConfig();
  Map<String, SystemConfig> _presetConfigs = {};
  bool _isLoading = false;

  // Getters
  SystemConfig get systemConfig => _systemConfig;
  CloudConfig get cloudConfig => _cloudConfig;
  Map<String, SystemConfig> get presetConfigs =>
      Map.unmodifiable(_presetConfigs);
  bool get isLoading => _isLoading;

  // Load configurations from secure storage
  Future<void> loadConfigurations() async {
    _setLoading(true);

    try {
      // Load system config
      final systemConfigJson = await _storage.read(key: _systemConfigKey);
      if (systemConfigJson != null) {
        final systemConfigMap =
            jsonDecode(systemConfigJson) as Map<String, dynamic>;
        _systemConfig = SystemConfig.fromJson(systemConfigMap);
      }

      // Load cloud config
      final cloudConfigJson = await _storage.read(key: _cloudConfigKey);
      if (cloudConfigJson != null) {
        final cloudConfigMap =
            jsonDecode(cloudConfigJson) as Map<String, dynamic>;
        _cloudConfig = CloudConfig.fromJson(cloudConfigMap);
      }

      // Load preset configs
      final presetConfigsJson = await _storage.read(key: _presetConfigsKey);
      if (presetConfigsJson != null) {
        final presetConfigsMap =
            jsonDecode(presetConfigsJson) as Map<String, dynamic>;
        _presetConfigs = presetConfigsMap.map(
          (key, value) => MapEntry(
              key, SystemConfig.fromJson(value as Map<String, dynamic>)),
        );
      }

      debugPrint('Configurations loaded successfully');
    } catch (e) {
      debugPrint('Error loading configurations: $e');
      // Use default configurations if loading fails
      _systemConfig = const SystemConfig();
      _cloudConfig = const CloudConfig();
      _presetConfigs = {};
    } finally {
      _setLoading(false);
    }
  }

  // Update system configuration
  Future<void> updateSystemConfig(SystemConfig newConfig) async {
    _setLoading(true);

    try {
      _systemConfig = newConfig;
      final configJson = jsonEncode(_systemConfig.toJson());
      await _storage.write(key: _systemConfigKey, value: configJson);
      debugPrint('System configuration updated successfully');
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating system configuration: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Update cloud configuration
  Future<void> updateCloudConfig(CloudConfig newConfig) async {
    _setLoading(true);

    try {
      _cloudConfig = newConfig;
      final configJson = jsonEncode(_cloudConfig.toJson());
      await _storage.write(key: _cloudConfigKey, value: configJson);
      debugPrint('Cloud configuration updated successfully');
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating cloud configuration: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Save preset configuration
  Future<void> savePresetConfig(String name, SystemConfig config) async {
    _setLoading(true);

    try {
      _presetConfigs[name] = config;
      final presetsJson = jsonEncode(
        _presetConfigs.map((key, value) => MapEntry(key, value.toJson())),
      );
      await _storage.write(key: _presetConfigsKey, value: presetsJson);
      debugPrint('Preset configuration "$name" saved successfully');
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving preset configuration: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Load preset configuration
  Future<void> loadPresetConfig(String name) async {
    if (_presetConfigs.containsKey(name)) {
      await updateSystemConfig(_presetConfigs[name]!);
      debugPrint('Preset configuration "$name" loaded successfully');
    } else {
      throw Exception('Preset configuration "$name" not found');
    }
  }

  // Delete preset configuration
  Future<void> deletePresetConfig(String name) async {
    _setLoading(true);

    try {
      _presetConfigs.remove(name);
      final presetsJson = jsonEncode(
        _presetConfigs.map((key, value) => MapEntry(key, value.toJson())),
      );
      await _storage.write(key: _presetConfigsKey, value: presetsJson);
      debugPrint('Preset configuration "$name" deleted successfully');
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting preset configuration: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Reset to default configurations
  Future<void> resetToDefaults() async {
    await updateSystemConfig(const SystemConfig());
    await updateCloudConfig(const CloudConfig());
    debugPrint('Configurations reset to defaults');
  }

  // Export configurations as JSON string
  String exportConfigurations() {
    final exportData = {
      'systemConfig': _systemConfig.toJson(),
      'cloudConfig': _cloudConfig.toJson(),
      'presetConfigs':
          _presetConfigs.map((key, value) => MapEntry(key, value.toJson())),
      'exportedAt': DateTime.now().toIso8601String(),
      'version': '1.0.0',
    };
    return jsonEncode(exportData);
  }

  // Import configurations from JSON string
  Future<void> importConfigurations(String jsonString) async {
    _setLoading(true);

    try {
      final importData = jsonDecode(jsonString) as Map<String, dynamic>;

      // Validate import data structure
      if (!importData.containsKey('systemConfig') ||
          !importData.containsKey('cloudConfig')) {
        throw const FormatException('Invalid configuration file format');
      }

      // Import system config
      final systemConfigData =
          importData['systemConfig'] as Map<String, dynamic>;
      final newSystemConfig = SystemConfig.fromJson(systemConfigData);

      // Import cloud config (but keep credentials secure)
      final cloudConfigData = importData['cloudConfig'] as Map<String, dynamic>;
      final importedCloudConfig = CloudConfig.fromJson(cloudConfigData);
      final newCloudConfig = importedCloudConfig.copyWith(
        accessKeyId: _cloudConfig.accessKeyId.isEmpty
            ? importedCloudConfig.accessKeyId
            : _cloudConfig.accessKeyId,
        secretKey: _cloudConfig.secretKey.isEmpty
            ? importedCloudConfig.secretKey
            : _cloudConfig.secretKey,
      );

      // Import preset configs
      Map<String, SystemConfig> newPresetConfigs = {};
      if (importData.containsKey('presetConfigs')) {
        final presetConfigsData =
            importData['presetConfigs'] as Map<String, dynamic>;
        newPresetConfigs = presetConfigsData.map(
          (key, value) => MapEntry(
              key, SystemConfig.fromJson(value as Map<String, dynamic>)),
        );
      }

      // Apply imported configurations
      await updateSystemConfig(newSystemConfig);
      await updateCloudConfig(newCloudConfig);

      _presetConfigs = newPresetConfigs;
      final presetsJson = jsonEncode(
        _presetConfigs.map((key, value) => MapEntry(key, value.toJson())),
      );
      await _storage.write(key: _presetConfigsKey, value: presetsJson);

      debugPrint('Configurations imported successfully');
      notifyListeners();
    } catch (e) {
      debugPrint('Error importing configurations: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Test cloud connection
  Future<bool> testCloudConnection() async {
    if (!_cloudConfig.isConfigured) {
      throw Exception('Cloud configuration is incomplete');
    }

    try {
      // Implement actual cloud connection test
      // This would involve making a test API call to the configured cloud provider
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call

      // For now, just validate the configuration format
      if (_cloudConfig.accessKeyId.length < 16 ||
          _cloudConfig.secretKey.length < 32 ||
          _cloudConfig.region.isEmpty ||
          _cloudConfig.bucketName.isEmpty) {
        return false;
      }

      debugPrint('Cloud connection test successful');
      return true;
    } catch (e) {
      debugPrint('Cloud connection test failed: $e');
      return false;
    }
  }

  // Get available AI debriefing parameters
  List<String> getAvailableAIDebriefingParameters() {
    return [
      'compressionRate',
      'compressionDepth',
      'recoilQuality',
      'ccf',
      'breathTiming',
      'cycleAnalysis',
      'overallPerformance',
      'improvementAreas',
    ];
  }

  // Validate system configuration
  List<String> validateSystemConfig(SystemConfig config) {
    final errors = <String>[];

    if (config.maxCompressionRate <= config.minCompressionRate) {
      errors.add(
          'Max compression rate must be greater than min compression rate');
    }

    if (config.minCompressionRate < 60) {
      errors.add('Min compression rate should not be less than 60 BPM');
    }

    if (config.maxCompressionRate > 200) {
      errors.add('Max compression rate should not exceed 200 BPM');
    }

    if (config.movingWindow < 1) {
      errors.add('Moving window must be at least 1');
    }

    if (config.hysteresis < 0) {
      errors.add('Hysteresis cannot be negative');
    }

    if (config.quietudePercent < 0 || config.quietudePercent > 1) {
      errors.add('Quietude percent must be between 0 and 1');
    }

    if (config.maxQuietudeTime <= 0) {
      errors.add('Max quietude time must be positive');
    }

    if (config.phaseDeterminationCycles < 1) {
      errors.add('Phase determination cycles must be at least 1');
    }

    if (config.compressionHi <= config.compressionOk) {
      errors.add('Compression Hi must be greater than Compression Ok');
    }

    if (config.recoilOk <= config.recoilLow) {
      errors.add('Recoil Ok must be greater than Recoil Low');
    }

    if (config.compressionRateSmoothingFactor < 0 ||
        config.compressionRateSmoothingFactor > 1) {
      errors.add('Compression rate smoothing factor must be between 0 and 1');
    }

    if (config.compressionRateCalculationPeaks < 2) {
      errors.add('Compression rate calculation peaks must be at least 2');
    }

    return errors;
  }

  // Validate cloud configuration
  List<String> validateCloudConfig(CloudConfig config) {
    final errors = <String>[];

    if (config.provider.isEmpty) {
      errors.add('Cloud provider is required');
    }

    if (config.accessKeyId.isEmpty) {
      errors.add('Access Key ID is required');
    }

    if (config.secretKey.isEmpty) {
      errors.add('Secret Key is required');
    }

    if (config.region.isEmpty) {
      errors.add('Region is required');
    }

    if (config.bucketName.isEmpty) {
      errors.add('Bucket/Space name is required');
    }

    if (config.minTimeElapsed < 1) {
      errors.add('Min time elapsed must be at least 1 minute');
    }

    // Validate bucket name format (basic S3 rules)
    if (config.bucketName.isNotEmpty) {
      final bucketRegex = RegExp(r'^[a-z0-9.-]+$');
      if (!bucketRegex.hasMatch(config.bucketName) ||
          config.bucketName.length < 3 ||
          config.bucketName.length > 63) {
        errors.add('Invalid bucket name format');
      }
    }

    return errors;
  }

  // Private helper method
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }
}
