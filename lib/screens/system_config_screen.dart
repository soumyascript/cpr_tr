//cpr_training_app/lib/screens/system_config_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/config_provider.dart';
import '../models/models.dart';

class SystemConfigScreen extends StatefulWidget {
  const SystemConfigScreen({super.key});

  @override
  State<SystemConfigScreen> createState() => _SystemConfigScreenState();
}

class _SystemConfigScreenState extends State<SystemConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  late SystemConfig _config;
  bool _hasChanges = false;
  bool _isLoading = false;
  String _selectedPreset = '';

  final _maxCompressionRateController = TextEditingController();
  final _minCompressionRateController = TextEditingController();
  final _movingWindowController = TextEditingController();
  final _hysteresisController = TextEditingController();
  final _quietudePercentController = TextEditingController();
  final _maxQuietudeTimeController = TextEditingController();
  final _phaseDeterminationCyclesController = TextEditingController();
  final _compressionOkController = TextEditingController();
  final _compressionHiController = TextEditingController();
  final _recoilOkController = TextEditingController();
  final _recoilLowController = TextEditingController();
  final _compressionRateSmoothingFactorController = TextEditingController();
  final _compressionRateCalculationPeaksController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadConfiguration();
  }

  @override
  void dispose() {
    _maxCompressionRateController.dispose();
    _minCompressionRateController.dispose();
    _movingWindowController.dispose();
    _hysteresisController.dispose();
    _quietudePercentController.dispose();
    _maxQuietudeTimeController.dispose();
    _phaseDeterminationCyclesController.dispose();
    _compressionOkController.dispose();
    _compressionHiController.dispose();
    _recoilOkController.dispose();
    _recoilLowController.dispose();
    _compressionRateSmoothingFactorController.dispose();
    _compressionRateCalculationPeaksController.dispose();
    super.dispose();
  }

  void _loadConfiguration() {
    final configProvider = context.read<ConfigProvider>();
    _config = configProvider.systemConfig;
    _populateControllers();
  }

  void _populateControllers() {
    _maxCompressionRateController.text = _config.maxCompressionRate.toString();
    _minCompressionRateController.text = _config.minCompressionRate.toString();
    _movingWindowController.text = _config.movingWindow.toString();
    _hysteresisController.text = _config.hysteresis.toString();
    _quietudePercentController.text = _config.quietudePercent.toString();
    _maxQuietudeTimeController.text = _config.maxQuietudeTime.toString();
    _phaseDeterminationCyclesController.text =
        _config.phaseDeterminationCycles.toString();
    _compressionOkController.text = _config.compressionOk.toString();
    _compressionHiController.text = _config.compressionHi.toString();
    _recoilOkController.text = _config.recoilOk.toString();
    _recoilLowController.text = _config.recoilLow.toString();
    _compressionRateSmoothingFactorController.text =
        _config.compressionRateSmoothingFactor.toString();
    _compressionRateCalculationPeaksController.text =
        _config.compressionRateCalculationPeaks.toString();
  }

  SystemConfig _buildConfigFromForm() {
    return SystemConfig(
      compressionDirection: _config.compressionDirection,
      maxCompressionRate: double.tryParse(_maxCompressionRateController.text) ??
          _config.maxCompressionRate,
      minCompressionRate: double.tryParse(_minCompressionRateController.text) ??
          _config.minCompressionRate,
      movingWindow:
          int.tryParse(_movingWindowController.text) ?? _config.movingWindow,
      hysteresis:
          double.tryParse(_hysteresisController.text) ?? _config.hysteresis,
      quietudePercent: double.tryParse(_quietudePercentController.text) ??
          _config.quietudePercent,
      maxQuietudeTime: double.tryParse(_maxQuietudeTimeController.text) ??
          _config.maxQuietudeTime,
      phaseDeterminationCycles:
          int.tryParse(_phaseDeterminationCyclesController.text) ??
              _config.phaseDeterminationCycles,
      compressionOk: double.tryParse(_compressionOkController.text) ??
          _config.compressionOk,
      compressionHi: double.tryParse(_compressionHiController.text) ??
          _config.compressionHi,
      recoilOk: double.tryParse(_recoilOkController.text) ?? _config.recoilOk,
      recoilLow:
          double.tryParse(_recoilLowController.text) ?? _config.recoilLow,
      compressionRateSmoothingFactor:
          double.tryParse(_compressionRateSmoothingFactorController.text) ??
              _config.compressionRateSmoothingFactor,
      compressionRateCalculationPeaks:
          int.tryParse(_compressionRateCalculationPeaksController.text) ??
              _config.compressionRateCalculationPeaks,
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
      final errors = configProvider.validateSystemConfig(newConfig);
      if (errors.isNotEmpty) {
        _showErrorDialog('Configuration Validation Failed', errors.join('\n'));
        return;
      }

      await configProvider.updateSystemConfig(newConfig);

      setState(() {
        _config = newConfig;
        _hasChanges = false;
      });

      _showSuccessSnackBar('Configuration saved successfully');
    } catch (e) {
      _showErrorDialog('Save Failed', e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _resetToDefaults() async {
    final confirmed = await _showConfirmDialog(
      'Reset to Defaults',
      'Are you sure you want to reset all settings to default values? This cannot be undone.',
    );

    if (confirmed) {
      setState(() {
        _config = const SystemConfig();
        _populateControllers();
        _hasChanges = true;
      });
    }
  }

  Future<void> _loadPreset(String presetName) async {
    try {
      final configProvider = context.read<ConfigProvider>();
      await configProvider.loadPresetConfig(presetName);

      setState(() {
        _config = configProvider.systemConfig;
        _populateControllers();
        _hasChanges = false;
        _selectedPreset = presetName;
      });

      _showSuccessSnackBar('Preset "$presetName" loaded successfully');
    } catch (e) {
      _showErrorDialog('Load Preset Failed', e.toString());
    }
  }

  Future<void> _saveAsPreset() async {
    final nameController = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save as Preset'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter a name for this preset:'),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Preset Name',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                Navigator.pop(context, nameController.text.trim());
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (name != null) {
      try {
        final configProvider = context.read<ConfigProvider>();
        final currentConfig = _buildConfigFromForm();
        await configProvider.savePresetConfig(name, currentConfig);

        setState(() {
          _selectedPreset = name;
        });

        _showSuccessSnackBar('Preset "$name" saved successfully');
      } catch (e) {
        _showErrorDialog('Save Preset Failed', e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<ConfigProvider>(
        builder: (context, configProvider, child) {
          if (configProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Form(
            key: _formKey,
            child: Column(
              children: [
                // Header with presets
                _buildHeader(configProvider),

                // Configuration form
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCompressionDirectionSection(),
                        const SizedBox(height: 24),
                        _buildRateConfigSection(),
                        const SizedBox(height: 24),
                        _buildSignalProcessingSection(),
                        const SizedBox(height: 24),
                        _buildPhaseDetectionSection(),
                        const SizedBox(height: 24),
                        _buildThresholdSection(),
                        const SizedBox(height: 24),
                        _buildCalculationSection(),
                      ],
                    ),
                  ),
                ),

                // Action buttons
                _buildActionButtons(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(ConfigProvider configProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.settings,
                  color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'System Configuration',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
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

          const SizedBox(height: 16),

          // Preset controls
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Load Preset',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  value: _selectedPreset.isEmpty ? null : _selectedPreset,
                  items: configProvider.presetConfigs.keys
                      .map((name) => DropdownMenuItem(
                            value: name,
                            child: Text(name),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      _loadPreset(value);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _saveAsPreset,
                icon: const Icon(Icons.save_alt, size: 18),
                label: const Text('Save as Preset'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompressionDirectionSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Compression Direction',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<CompressionDirection>(
                    title: const Text('Increasing'),
                    //subtitle: const Text('Higher values = compression'),
                    value: CompressionDirection.increasing,
                    groupValue: _config.compressionDirection,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _config =
                              _config.copyWith(compressionDirection: value);
                          _hasChanges = true;
                        });
                      }
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<CompressionDirection>(
                    title: const Text('Decreasing'),
                    //subtitle: const Text('Lower values = compression'),
                    value: CompressionDirection.decreasing,
                    groupValue: _config.compressionDirection,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _config =
                              _config.copyWith(compressionDirection: value);
                          _hasChanges = true;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRateConfigSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Compression Rate Configuration',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _minCompressionRateController,
                    decoration: const InputDecoration(
                      labelText: 'Min Rate (BPM)',
                      border: OutlineInputBorder(),
                      helperText: 'Target: 100 BPM',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      final val = double.tryParse(value ?? '');
                      if (val == null || val < 60) {
                        return 'Must be ≥ 60 BPM';
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
                    controller: _maxCompressionRateController,
                    decoration: const InputDecoration(
                      labelText: 'Max Rate (BPM)',
                      border: OutlineInputBorder(),
                      helperText: 'Target: 120 BPM',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      final val = double.tryParse(value ?? '');
                      final minVal =
                          double.tryParse(_minCompressionRateController.text);
                      if (val == null || val > 200) {
                        return 'Must be ≤ 200 BPM';
                      }
                      if (minVal != null && val <= minVal) {
                        return 'Must be > min rate';
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
          ],
        ),
      ),
    );
  }

  Widget _buildSignalProcessingSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Signal Processing',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _movingWindowController,
                    decoration: const InputDecoration(
                      labelText: 'Moving Window',
                      border: OutlineInputBorder(),
                      helperText: 'Samples for averaging',
                      suffixText: 'samples',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      final val = int.tryParse(value ?? '');
                      if (val == null || val < 1) {
                        return 'Must be ≥ 1';
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
                    controller: _hysteresisController,
                    decoration: const InputDecoration(
                      labelText: 'Hysteresis',
                      border: OutlineInputBorder(),
                      helperText: 'Noise reduction',
                      suffixText: 'units',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      final val = double.tryParse(value ?? '');
                      if (val == null || val < 0) {
                        return 'Must be ≥ 0';
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
          ],
        ),
      ),
    );
  }

  Widget _buildPhaseDetectionSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Phase Detection',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _quietudePercentController,
                    decoration: const InputDecoration(
                      labelText: 'Quietude Percent',
                      border: OutlineInputBorder(),
                      helperText: '0.0 - 1.0',
                      suffixText: '%',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      final val = double.tryParse(value ?? '');
                      if (val == null || val < 0 || val > 1) {
                        return 'Must be 0.0 - 1.0';
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
                    controller: _maxQuietudeTimeController,
                    decoration: const InputDecoration(
                      labelText: 'Max Quietude Time',
                      border: OutlineInputBorder(),
                      helperText: 'Before pause phase',
                      suffixText: 'seconds',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      final val = double.tryParse(value ?? '');
                      if (val == null || val <= 0) {
                        return 'Must be > 0';
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
              controller: _phaseDeterminationCyclesController,
              decoration: const InputDecoration(
                labelText: 'Phase Determination Cycles',
                border: OutlineInputBorder(),
                helperText: 'Samples to confirm phase change',
                suffixText: 'cycles',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                final val = int.tryParse(value ?? '');
                if (val == null || val < 1) {
                  return 'Must be ≥ 1';
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

  Widget _buildThresholdSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quality Thresholds',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _compressionOkController,
                    decoration: const InputDecoration(
                      labelText: 'Compression Ok',
                      border: OutlineInputBorder(),
                      helperText: 'Min good compression',
                      suffixText: 'units',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      final val = double.tryParse(value ?? '');
                      if (val == null || val < 0) {
                        return 'Must be ≥ 0';
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
                    controller: _compressionHiController,
                    decoration: const InputDecoration(
                      labelText: 'Compression Hi',
                      border: OutlineInputBorder(),
                      helperText: 'Max good compression',
                      suffixText: 'units',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      final val = double.tryParse(value ?? '');
                      final okVal =
                          double.tryParse(_compressionOkController.text);
                      if (val == null || val < 0) {
                        return 'Must be ≥ 0';
                      }
                      if (okVal != null && val <= okVal) {
                        return 'Must be > Compression Ok';
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
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _recoilOkController,
                    decoration: const InputDecoration(
                      labelText: 'Recoil Ok',
                      border: OutlineInputBorder(),
                      helperText: 'Min good recoil',
                      suffixText: 'units',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      final val = double.tryParse(value ?? '');
                      if (val == null || val < 0) {
                        return 'Must be ≥ 0';
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
                    controller: _recoilLowController,
                    decoration: const InputDecoration(
                      labelText: 'Recoil Low',
                      border: OutlineInputBorder(),
                      helperText: 'Poor recoil threshold',
                      suffixText: 'units',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      final val = double.tryParse(value ?? '');
                      final okVal = double.tryParse(_recoilOkController.text);
                      if (val == null || val < 0) {
                        return 'Must be ≥ 0';
                      }
                      if (okVal != null && val >= okVal) {
                        return 'Must be < Recoil Ok';
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
          ],
        ),
      ),
    );
  }

  Widget _buildCalculationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rate Calculation',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _compressionRateSmoothingFactorController,
                    decoration: const InputDecoration(
                      labelText: 'Smoothing Factor',
                      border: OutlineInputBorder(),
                      helperText: '0.0 - 1.0 (higher = less smoothing)',
                      suffixText: 'α',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      final val = double.tryParse(value ?? '');
                      if (val == null || val < 0 || val > 1) {
                        return 'Must be 0.0 - 1.0';
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
                    controller: _compressionRateCalculationPeaksController,
                    decoration: const InputDecoration(
                      labelText: 'Calculation Peaks',
                      border: OutlineInputBorder(),
                      helperText: 'Peaks used for rate calc',
                      suffixText: 'peaks',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      final val = int.tryParse(value ?? '');
                      if (val == null || val < 2) {
                        return 'Must be ≥ 2';
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
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          OutlinedButton(
            onPressed: _resetToDefaults,
            child: const Text('Reset to Defaults'),
          ),
          const SizedBox(width: 16),
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
            onPressed: _hasChanges && !_isLoading ? _saveConfiguration : null,
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
    );
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

  Future<bool> _showConfirmDialog(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
