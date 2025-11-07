//cpr_training_app/lib/screens/cloud_config_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/config_provider.dart';
import '../providers/sync_provider.dart';
import '../models/models.dart';

class CloudConfigScreen extends StatefulWidget {
  const CloudConfigScreen({super.key});

  @override
  State<CloudConfigScreen> createState() => _CloudConfigScreenState();
}

class _CloudConfigScreenState extends State<CloudConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  late CloudConfig _config;
  bool _hasChanges = false;
  bool _isLoading = false;
  bool _isTesting = false;
  bool _obscureSecretKey = true;

  final _accessKeyIdController = TextEditingController();
  final _secretKeyController = TextEditingController();
  final _regionController = TextEditingController();
  final _bucketNameController = TextEditingController();
  final _folderPrefixController = TextEditingController();
  final _minTimeElapsedController = TextEditingController();

  final List<String> _availableProviders = [
    'AWS S3',
    'DigitalOcean Spaces',
    'MinIO',
    'Wasabi',
    'Backblaze B2',
  ];

  final List<String> _availableAIParameters = [
    'compressionRate',
    'compressionDepth',
    'recoilQuality',
    'ccf',
    'breathTiming',
    'cycleAnalysis',
    'overallPerformance',
    'improvementAreas',
  ];

  @override
  void initState() {
    super.initState();
    _loadConfiguration();
  }

  @override
  void dispose() {
    _accessKeyIdController.dispose();
    _secretKeyController.dispose();
    _regionController.dispose();
    _bucketNameController.dispose();
    _folderPrefixController.dispose();
    _minTimeElapsedController.dispose();
    super.dispose();
  }

  void _loadConfiguration() {
    final configProvider = context.read<ConfigProvider>();
    _config = configProvider.cloudConfig;
    _populateControllers();
  }

  void _populateControllers() {
    _accessKeyIdController.text = _config.accessKeyId;
    _secretKeyController.text = _config.secretKey;
    _regionController.text = _config.region;
    _bucketNameController.text = _config.bucketName;
    _folderPrefixController.text = _config.folderPrefix ?? '';
    _minTimeElapsedController.text = _config.minTimeElapsed.toString();
  }

  CloudConfig _buildConfigFromForm() {
    return _config.copyWith(
      accessKeyId: _accessKeyIdController.text.trim(),
      secretKey: _secretKeyController.text.trim(),
      region: _regionController.text.trim(),
      bucketName: _bucketNameController.text.trim(),
      folderPrefix: _folderPrefixController.text.trim().isEmpty
          ? null
          : _folderPrefixController.text.trim(),
      minTimeElapsed: int.tryParse(_minTimeElapsedController.text) ??
          _config.minTimeElapsed,
    );
  }

  Future<void> _saveConfiguration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final newConfig = _buildConfigFromForm();
      final configProvider = context.read<ConfigProvider>();

      // Validate configuration
      final errors = configProvider.validateCloudConfig(newConfig);
      if (errors.isNotEmpty) {
        _showErrorDialog('Configuration Validation Failed', errors.join('\n'));
        return;
      }

      await configProvider.updateCloudConfig(newConfig);

      // Update sync provider with new config
      if (mounted) {
        context.read<SyncProvider>().updateCloudConfig(newConfig);
      }

      setState(() {
        _config = newConfig;
        _hasChanges = false;
      });

      _showSuccessSnackBar('Cloud configuration saved successfully');
    } catch (e) {
      _showErrorDialog('Save Failed', e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) {
      _showErrorDialog(
          'Invalid Configuration', 'Please fix validation errors first.');
      return;
    }

    setState(() {
      _isTesting = true;
    });

    try {
      // Save config temporarily for testing
      final testConfig = _buildConfigFromForm();
      final syncProvider = context.read<SyncProvider>();
      syncProvider.updateCloudConfig(testConfig);

      final success = await syncProvider.testCloudConnection();

      if (success) {
        _showSuccessSnackBar('Connection test successful!');
      } else {
        _showErrorDialog('Connection Test Failed',
            'Unable to connect to cloud storage. Please check your credentials and network connection.');
      }
    } catch (e) {
      _showErrorDialog('Connection Test Error', e.toString());
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  Future<void> _triggerManualSync() async {
    try {
      final syncProvider = context.read<SyncProvider>();
      await syncProvider.startManualSync();
      _showSuccessSnackBar('Manual sync completed successfully');
    } catch (e) {
      _showErrorDialog('Sync Failed', e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer2<ConfigProvider, SyncProvider>(
        builder: (context, configProvider, syncProvider, child) {
          if (configProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Form(
            key: _formKey,
            child: Column(
              children: [
                // Header with sync status
                _buildHeader(syncProvider),

                // Configuration form
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProviderSection(),
                        const SizedBox(height: 24),
                        _buildCredentialsSection(),
                        const SizedBox(height: 24),
                        _buildStorageSection(),
                        const SizedBox(height: 24),
                        _buildSyncSettingsSection(),
                        const SizedBox(height: 24),
                        _buildAISection(),
                      ],
                    ),
                  ),
                ),

                // Action buttons
                _buildActionButtons(syncProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(SyncProvider syncProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.cloud, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Cloud Configuration',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Sync status
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getSyncStatusColor(syncProvider.syncHealthStatus)
                  .withValues(alpha: 0.1),
              border: Border.all(
                  color: _getSyncStatusColor(syncProvider.syncHealthStatus)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  _getSyncStatusIcon(syncProvider.syncHealthStatus),
                  color: _getSyncStatusColor(syncProvider.syncHealthStatus),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        syncProvider.syncHealthMessage,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _getSyncStatusColor(
                              syncProvider.syncHealthStatus),
                        ),
                      ),
                      if (syncProvider.lastSyncTime != null)
                        Text(
                          'Last sync: ${syncProvider.formattedTimeSinceLastSync}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
                if (syncProvider.isSyncing)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),

          if (_hasChanges) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.edit,
                    size: 16,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Unsaved changes',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProviderSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cloud Provider',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Provider',
                border: OutlineInputBorder(),
                helperText: 'Select your cloud storage provider',
              ),
              initialValue: _config.provider,
              items: _availableProviders
                  .map((provider) => DropdownMenuItem(
                        value: provider,
                        child: Text(provider),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _config = _config.copyWith(provider: value);
                    _hasChanges = true;
                    // Auto-populate region for known providers
                    if (value == 'AWS S3' && _regionController.text.isEmpty) {
                      _regionController.text = 'us-east-1';
                    } else if (value == 'DigitalOcean Spaces' &&
                        _regionController.text.isEmpty) {
                      _regionController.text = 'nyc3';
                    }
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCredentialsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.security,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Credentials',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _accessKeyIdController,
              decoration: const InputDecoration(
                labelText: 'Access Key ID',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.key),
                helperText: 'Your cloud storage access key',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Access Key ID is required';
                }
                if (value.trim().length < 16) {
                  return 'Access Key ID seems too short';
                }
                return null;
              },
              onChanged: (value) {
                setState(() {
                  _hasChanges = true;
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _secretKeyController,
              decoration: InputDecoration(
                labelText: 'Secret Key',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(_obscureSecretKey
                      ? Icons.visibility
                      : Icons.visibility_off),
                  onPressed: () {
                    setState(() {
                      _obscureSecretKey = !_obscureSecretKey;
                    });
                  },
                ),
                helperText: 'Your cloud storage secret key',
              ),
              obscureText: _obscureSecretKey,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Secret Key is required';
                }
                if (value.trim().length < 32) {
                  return 'Secret Key seems too short';
                }
                return null;
              },
              onChanged: (value) {
                setState(() {
                  _hasChanges = true;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Storage Configuration',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _regionController,
                    decoration: const InputDecoration(
                      labelText: 'Region',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.public),
                      helperText: 'e.g., us-east-1, nyc3',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Region is required';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      setState(() {
                        _hasChanges = true;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _bucketNameController,
                    decoration: const InputDecoration(
                      labelText: 'Bucket/Space Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.folder),
                      helperText: 'Container for your data',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Bucket name is required';
                      }
                      if (!RegExp(r'^[a-z0-9.-]+$').hasMatch(value.trim()) ||
                          value.trim().length < 3 ||
                          value.trim().length > 63) {
                        return 'Invalid bucket name format';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      setState(() {
                        _hasChanges = true;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _folderPrefixController,
              decoration: const InputDecoration(
                labelText: 'Folder Prefix (Optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.folder_open),
                helperText: 'Organize data in subfolders',
              ),
              onChanged: (value) {
                setState(() {
                  _hasChanges = true;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncSettingsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sync Settings',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _minTimeElapsedController,
              decoration: const InputDecoration(
                labelText: 'Auto Sync Interval',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.schedule),
                suffixText: 'minutes',
                helperText: 'Time between automatic sync attempts',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                final val = int.tryParse(value ?? '');
                if (val == null || val < 1) {
                  return 'Must be at least 1 minute';
                }
                return null;
              },
              onChanged: (value) {
                setState(() {
                  _hasChanges = true;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAISection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.psychology,
                        color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'AI Debriefing',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
                Switch(
                  value: _config.aiDebriefing,
                  onChanged: (value) {
                    setState(() {
                      _config = _config.copyWith(aiDebriefing: value);
                      _hasChanges = true;
                    });
                  },
                ),
              ],
            ),
            if (_config.aiDebriefing) ...[
              const SizedBox(height: 16),
              Text(
                'AI Analysis Parameters',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Select which metrics to include in AI analysis:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                    ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _availableAIParameters
                    .map((param) => FilterChip(
                          label: Text(param
                              .replaceAll(RegExp(r'([A-Z])'), ' \$1')
                              .trim()),
                          selected:
                              _config.aiDebriefingParameters.contains(param),
                          onSelected: (selected) {
                            setState(() {
                              final params = List<String>.from(
                                  _config.aiDebriefingParameters);
                              if (selected) {
                                params.add(param);
                              } else {
                                params.remove(param);
                              }
                              _config = _config.copyWith(
                                  aiDebriefingParameters: params);
                              _hasChanges = true;
                            });
                          },
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(SyncProvider syncProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Column(
        children: [
          // Test and sync buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isTesting || _isLoading ? null : _testConnection,
                  icon: _isTesting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.wifi_protected_setup),
                  label: Text(_isTesting ? 'Testing...' : 'Test Connection'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: syncProvider.isSyncing || !_config.isConfigured
                      ? null
                      : _triggerManualSync,
                  icon: syncProvider.isSyncing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.sync),
                  label: Text(
                      syncProvider.isSyncing ? 'Syncing...' : 'Manual Sync'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Save and discard buttons
          Row(
            children: [
              OutlinedButton(
                onPressed: _hasChanges
                    ? () {
                        setState(() {
                          _loadConfiguration();
                          _hasChanges = false;
                        });
                      }
                    : null,
                child: const Text('Discard Changes'),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed:
                    _hasChanges && !_isLoading ? _saveConfiguration : null,
                child: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Configuration'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getSyncStatusColor(SyncHealthStatus status) {
    switch (status) {
      case SyncHealthStatus.healthy:
        return Colors.green;
      case SyncHealthStatus.pending:
        return Colors.blue;
      case SyncHealthStatus.warning:
        return Colors.orange;
      case SyncHealthStatus.error:
        return Colors.red;
    }
  }

  IconData _getSyncStatusIcon(SyncHealthStatus status) {
    switch (status) {
      case SyncHealthStatus.healthy:
        return Icons.check_circle;
      case SyncHealthStatus.pending:
        return Icons.sync;
      case SyncHealthStatus.warning:
        return Icons.warning;
      case SyncHealthStatus.error:
        return Icons.error;
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
