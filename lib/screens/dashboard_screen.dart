// dual BLE 2

//cpr_training_app/lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';

import '../providers/session_provider.dart';
import '../providers/metrics_provider.dart';
import '../providers/alerts_provider.dart';
import '../providers/graph_provider.dart';
import '../services/sensor_service.dart';
import '../services/voice_service.dart';
import '../services/db_service.dart';
import '../models/models.dart';
import '../utils/responsive_utils.dart';
import '../widgets/responsive_widgets.dart';
import '../widgets/profile_logout_bar.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;

  StreamSubscription? _sensorDataSubscription;
  StreamSubscription? _connectionStatusSubscription;
  StreamSubscription? _deviceConnectionSubscription;
  Timer? _voiceListeningTimer;

  String _connectionStatus = 'Not connected';
  bool _isListeningToVoice = false;
  String _selectedGraphSensor = 'Sensor1';
  bool _shouldRestartListening = false;

  // Track connected devices
  final Map<String, String> _connectedDevices = {};

  @override
  void initState() {
    super.initState();

    // Initialize animation
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _initializeSensorConnection();

    // FIXED: Subscribe AlertsProvider to MetricsProvider's alert stream
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final metricsProvider = context.read<MetricsProvider>();
      final alertsProvider = context.read<AlertsProvider>();

      // Subscribe alerts provider to metrics provider's alert stream
      alertsProvider.listenToAlerts(metricsProvider.alertStream);

      debugPrint('AlertsProvider subscribed to MetricsProvider alert stream');
    });
  }

  void _initializeSensorConnection() {
    final sensorService = context.read<SensorService>();

    // Listen to connection status
    _connectionStatusSubscription = sensorService.connectionStatusStream.listen(
          (status) {
        if (mounted) {
          setState(() {
            _connectionStatus = status;
          });
        }
      },
    );

    // NEW: Listen to device connection events
    _deviceConnectionSubscription = sensorService.deviceConnectionStream.listen(
          (event) {
        if (mounted) {
          setState(() {
            if (event.isConnected) {
              _connectedDevices[event.deviceId] = event.deviceName;
            } else {
              _connectedDevices.remove(event.deviceId);
            }
          });
        }
        debugPrint('Device ${event.deviceName} ${event.isConnected ? 'connected' : 'disconnected'}');
      },
    );

    // Listen to sensor data - FIXED: Use correct field names from SensorData
    _sensorDataSubscription =
        sensorService.sensorDataStream.listen((SensorData data) async {
          if (mounted) {
            // Update graph provider
            context.read<GraphProvider>().addDataPoint(data);

            // Process data through metrics provider
            context.read<MetricsProvider>().processSensorData(data);

            // ADD THIS BLOCK TO SAVE TO DATABASE DURING ACTIVE SESSIONS:
            final sessionProvider = context.read<SessionProvider>();
            if (sessionProvider.isSessionActive &&
                sessionProvider.currentSession != null) {
              try {
                final sample = SensorSample(
                  id: 0,
                  sessionId: sessionProvider.currentSession!.id,
                  timestamp: data.timestamp,
                  // FIXED: Use correct field names from SensorData
                  sensor1Raw: data.compressionDepth.toInt(), // Convert depth to int
                  sensor2Raw: data.compressionCount, // Use compression count
                  sensor1Avg: data.compressionDepth, // Use depth as double
                  sensor2Avg: data.compressionCount.toDouble(), // Use count as double
                );
                await DBService.instance.insertSample(sample);
              } catch (e) {
                debugPrint('Error saving sensor sample: $e');
              }
            }
          }
        });
  }

  // Future<void> _toggleSession() async {
  //   final sessionProvider = context.read<SessionProvider>();
  //   final sensorService = context.read<SensorService>();
  //   final metricsProvider = context.read<MetricsProvider>();
  //   final alertsProvider = context.read<AlertsProvider>();
  //   final graphProvider = context.read<GraphProvider>();
  //
  //   try {
  //     if (sessionProvider.isSessionActive) {
  //       // End session
  //       await sessionProvider.endSession();
  //
  //       // IMPORTANT: Stop CCF tracking when session ends
  //       metricsProvider.setSessionState(false);
  //       _animationController.stop();
  //
  //       if (mounted) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(
  //             content: Text('Session ended successfully'),
  //             backgroundColor: Colors.green,
  //           ),
  //         );
  //
  //         // Navigate to debrief
  //         Navigator.pushNamed(context, '/debrief');
  //       }
  //     } else {
  //       // Check if at least one sensor is connected
  //       if (!sensorService.isConnected) {
  //         if (mounted) {
  //           ScaffoldMessenger.of(context).showSnackBar(
  //             const SnackBar(
  //               content: Text('Please connect to at least one ESP32 first'),
  //               backgroundColor: Colors.orange,
  //             ),
  //           );
  //         }
  //         return;
  //       }
  //
  //       // REMOVED: Pressure check for starting session
  //       // Sessions can now start without pressure
  //
  //       // Start session
  //       final startedSession = await sessionProvider.startSession();
  //
  //       // IMPORTANT: Reset metrics and alerts BEFORE starting CCF tracking
  //       metricsProvider.reset();
  //       alertsProvider.clearAlerts();
  //       graphProvider.clearData();
  //
  //       // CRITICAL FIX: Start CCF tracking when session begins
  //       metricsProvider.setSessionState(true,
  //           sessionStartTime: startedSession.startedAt);
  //
  //       _animationController.repeat();
  //
  //       if (mounted) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(
  //             content: Text('Session started successfully'),
  //             backgroundColor: Colors.green,
  //           ),
  //         );
  //       }
  //     }
  //   } catch (e) {
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text('Error: ${e.toString()}'),
  //           backgroundColor: Colors.red,
  //         ),
  //       );
  //     }
  //   }
  // }


  Future<void> _toggleSession() async {
    final sessionProvider = context.read<SessionProvider>();
    final sensorService = context.read<SensorService>();
    final metricsProvider = context.read<MetricsProvider>();
    final alertsProvider = context.read<AlertsProvider>();
    final graphProvider = context.read<GraphProvider>();

    try {
      if (sessionProvider.isSessionActive) {
        // End session
        await sessionProvider.endSession();

        // ========== ADD THIS LINE ==========
        metricsProvider.finalizeSessionMetrics(); // PRESERVES COMPRESSION RATE

        // IMPORTANT: Stop CCF tracking when session ends
        metricsProvider.setSessionState(false);
        _animationController.stop();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Session ended successfully'),
              backgroundColor: Colors.green,
            ),
          );

          // ========== ADD THIS LINE ==========
          await Future.delayed(const Duration(milliseconds: 100)); // ENSURES DATA IS SAVED

          // Navigate to debrief
          Navigator.pushNamed(context, '/debrief');
        }
      } else {
        // Check if at least one sensor is connected
        if (!sensorService.isConnected) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please connect to at least one ESP32 first'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }

        // ========== ADD THIS LINE ==========
        metricsProvider.clearSessionMetrics(); // CLEARS OLD SESSION DATA

        // REMOVED: Pressure check for starting session
        // Sessions can now start without pressure

        // Start session
        final startedSession = await sessionProvider.startSession();

        // IMPORTANT: Reset metrics and alerts BEFORE starting CCF tracking
        metricsProvider.reset();
        alertsProvider.clearAlerts();
        graphProvider.clearData();

        // CRITICAL FIX: Start CCF tracking when session begins
        metricsProvider.setSessionState(true,
            sessionStartTime: startedSession.startedAt);

        _animationController.repeat();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Session started successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _connectToSensor(int deviceNumber) async {
    final sensorService = context.read<SensorService>();

    try {
      // Check if device is already connected
      final connectedDevices = sensorService.connectedDevices;
      if (connectedDevices.length >= deviceNumber) {
        // Disconnect specific device
        final deviceToDisconnect = connectedDevices[deviceNumber - 1];
        await sensorService.disconnectDevice(deviceToDisconnect);
      } else {
        await _showDeviceSelectionDialog(deviceNumber);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showDeviceSelectionDialog(int deviceNumber) async {
    final sensorService = context.read<SensorService>();

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Select ESP32 Device ${deviceNumber == 1 ? '1 (Primary)' : '2 (Secondary)'}'),
              content: SizedBox(
                width: double.maxFinite,
                height: 300,
                child: Column(
                  children: [
                    ElevatedButton(
                      onPressed: sensorService.isScanning
                          ? null
                          : () async {
                        setDialogState(() {});
                        await sensorService.startScan();
                        setDialogState(() {});
                      },
                      child: Text(
                        sensorService.isScanning
                            ? 'Scanning...'
                            : 'Scan for Devices',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: sensorService.availableDevices.isEmpty
                          ? const Center(
                        child: Text(
                          'No ESP32 devices found.\nMake sure your devices are powered on.',
                          textAlign: TextAlign.center,
                        ),
                      )
                          : ListView.builder(
                        itemCount: sensorService.availableDevices.length,
                        itemBuilder: (context, index) {
                          final device =
                          sensorService.availableDevices[index];
                          final isConnected = sensorService.connectedDevices
                              .any((d) => d.remoteId == device.remoteId);

                          return ListTile(
                            title: Text(
                              device.platformName.isNotEmpty
                                  ? device.platformName
                                  : 'Unknown Device',
                            ),
                            subtitle: Text(
                                '${device.remoteId.toString()}${isConnected ? ' (Connected)' : ''}'
                            ),
                            leading: Icon(
                              isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
                              color: isConnected ? Colors.green : Colors.grey,
                            ),
                            onTap: isConnected ? null : () {
                              Navigator.of(context).pop();
                              sensorService.connectToDevice(device);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // NEW: Auto-connect to all available devices
  Future<void> _connectAllDevices() async {
    final sensorService = context.read<SensorService>();

    try {
      await sensorService.autoConnectAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attempting to connect to all available devices'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Auto-connect error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _toggleVoiceListening() {
    final voiceService = context.read<VoiceService>();

    if (_isListeningToVoice) {
      // Stop continuous listening
      _shouldRestartListening = false;
      _voiceListeningTimer?.cancel();
      voiceService.stopListening();
      setState(() {
        _isListeningToVoice = false;
      });
      debugPrint('Voice listening stopped manually');
    } else {
      // Start continuous listening
      _shouldRestartListening = true;
      _startContinuousListening();
      setState(() {
        _isListeningToVoice = true;
      });
      debugPrint('Voice listening started');
    }
  }

  void _startContinuousListening() {
    if (!_shouldRestartListening || !mounted) return;

    final voiceService = context.read<VoiceService>();

    voiceService.startListening(
      onResult: (command) {
        debugPrint('Voice command received: $command');

        // Process the command
        if (command.toLowerCase().contains('drish start cpr')) {
          _toggleSession();
        } else if (command.toLowerCase().contains('drish stop cpr')) {
          _toggleSession();
        }

        // Automatically restart listening after a short delay
        if (_shouldRestartListening && mounted) {
          _voiceListeningTimer = Timer(const Duration(milliseconds: 500), () {
            if (_shouldRestartListening && mounted) {
              _startContinuousListening();
            }
          });
        }
      },
      onError: (error) {
        debugPrint('Voice recognition error: $error');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Voice recognition error: $error')),
          );
        }

        // Restart listening after error if still supposed to be listening
        if (_shouldRestartListening && mounted) {
          _voiceListeningTimer = Timer(const Duration(seconds: 2), () {
            if (_shouldRestartListening && mounted) {
              _startContinuousListening();
            }
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: ResponsiveUtils.getScreenPadding(context),
          child: Column(
            children: [
              // PRESSURE STATUS BANNER - MODIFIED
              Consumer<SessionProvider>(
                builder: (context, sessionProvider, child) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    color: sessionProvider.isPressureActive
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          sessionProvider.isPressureActive
                              ? Icons.check_circle
                              : Icons.info_outline,
                          color: sessionProvider.isPressureActive
                              ? Colors.green
                              : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          sessionProvider.isPressureActive
                              ? 'Pressure Active (${sessionProvider.currentPressure.toStringAsFixed(1)}) - CPR Processing Enabled'
                              : 'Apply Pressure >10 to Enable CPR Processing (${sessionProvider.currentPressure.toStringAsFixed(1)}/10)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: sessionProvider.isPressureActive
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              // MAIN CONTENT
              ResponsiveLayout(
                mobile: _buildMobileLayout(),
                tablet: _buildTabletLayout(),
                desktop: _buildDesktopLayout(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    final isLandscape = ResponsiveUtils.isLandscape(context);

    if (isLandscape) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left column: Animation and Metrics
          Expanded(
            flex: 2,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildConnectionSection(),
                SizedBox(height: ResponsiveUtils.getSpacing(context)),
                SizedBox(
                  height: ResponsiveUtils.getAnimationPanelHeight(context),
                  child: _buildAnimationPanel(),
                ),
                SizedBox(height: ResponsiveUtils.getSpacing(context)),
                _buildAlertsPanel(),
              ],
            ),
          ),
          SizedBox(width: ResponsiveUtils.getSpacing(context)),
          // Right column: Metrics and Graph
          Expanded(
            flex: 3,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 400,
                  child: _buildMetricsPanel(),
                ),
                SizedBox(height: ResponsiveUtils.getSpacing(context)),
                SizedBox(
                  height: ResponsiveUtils.getChartHeight(context),
                  child: _buildGraphPanel(),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Portrait mobile layout
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildConnectionSection(),
        SizedBox(height: ResponsiveUtils.getSpacing(context)),
        SizedBox(
          height: ResponsiveUtils.getAnimationPanelHeight(context),
          child: _buildAnimationPanel(),
        ),
        SizedBox(height: ResponsiveUtils.getSpacing(context)),
        _buildAlertsPanel(),
        SizedBox(height: ResponsiveUtils.getSpacing(context)),
        SizedBox(
          height: 400,
          child: _buildMetricsPanel(),
        ),
        SizedBox(height: ResponsiveUtils.getSpacing(context)),
        SizedBox(
          height: ResponsiveUtils.getChartHeight(context),
          child: _buildGraphPanel(),
        ),
        SizedBox(height: ResponsiveUtils.getSpacing(context)), // Bottom padding
        const ProfileLogoutBar(),
        SizedBox(height: 40),
      ],
    );
  }

  Widget _buildTabletLayout() {
    final isLandscape = ResponsiveUtils.isLandscape(context);

    if (isLandscape) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left column: Animation and Alerts
          Expanded(
            flex: 2,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildConnectionSection(),
                SizedBox(height: ResponsiveUtils.getSpacing(context)),
                SizedBox(
                  height: ResponsiveUtils.getAnimationPanelHeight(context),
                  child: _buildAnimationPanel(),
                ),
                SizedBox(height: ResponsiveUtils.getSpacing(context)),
                _buildAlertsPanel(),
              ],
            ),
          ),
          SizedBox(width: ResponsiveUtils.getSpacing(context)),
          // Right column: Metrics and Graph
          Expanded(
            flex: 3,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 400,
                  child: _buildMetricsPanel(),
                ),
                SizedBox(height: ResponsiveUtils.getSpacing(context)),
                SizedBox(
                  height: ResponsiveUtils.getChartHeight(context),
                  child: _buildGraphPanel(),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Portrait tablet layout
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildConnectionSection(),
        SizedBox(height: ResponsiveUtils.getSpacing(context)),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: SizedBox(
                height: ResponsiveUtils.getAnimationPanelHeight(context),
                child: _buildAnimationPanel(),
              ),
            ),
            SizedBox(width: ResponsiveUtils.getSpacing(context)),
            Expanded(
              flex: 3,
              child: SizedBox(
                height: ResponsiveUtils.getAnimationPanelHeight(context),
                child: _buildMetricsPanel(),
              ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveUtils.getSpacing(context)),
        _buildAlertsPanel(),
        SizedBox(height: ResponsiveUtils.getSpacing(context)),
        SizedBox(
          height: ResponsiveUtils.getChartHeight(context),
          child: _buildGraphPanel(),
        ),
        SizedBox(height: ResponsiveUtils.getSpacing(context)), // Bottom padding
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left column: Animation and Alerts
        Expanded(
          flex: 2,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildConnectionSection(),
              SizedBox(height: ResponsiveUtils.getSpacing(context)),
              SizedBox(
                height: ResponsiveUtils.getAnimationPanelHeight(context),
                child: _buildAnimationPanel(),
              ),
              SizedBox(height: ResponsiveUtils.getSpacing(context)),
              SizedBox(
                height: ResponsiveUtils.getAlertPanelHeight(context),
                child: _buildAlertsPanel(),
              ),
            ],
          ),
        ),
        SizedBox(width: ResponsiveUtils.getSpacing(context)),
        // Middle column: Metrics
        Expanded(
          flex: 3,
          child: SizedBox(
            height: MediaQuery.of(context).size.height - 100,
            child: _buildMetricsPanel(),
          ),
        ),
        SizedBox(width: ResponsiveUtils.getSpacing(context)),
        // Right column: Graph
        Expanded(
          flex: 4,
          child: SizedBox(
            height: MediaQuery.of(context).size.height - 100,
            child: _buildGraphPanel(),
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionSection() {
    return Consumer2<SensorService, SessionProvider>(
      builder: (context, sensorService, sessionProvider, child) {
        final connectedDevices = sensorService.connectedDevices;

        return ResponsiveCard(
          child: Column(
            children: [
              // Connection Status
              Container(
                width: double.infinity,
                padding:
                EdgeInsets.all(ResponsiveUtils.getSmallSpacing(context)),
                decoration: BoxDecoration(
                  color: _getConnectionStatusColor().withOpacity(0.1),
                  border: Border.all(color: _getConnectionStatusColor()),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      _connectionStatus,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _getConnectionStatusColor(),
                        fontWeight: FontWeight.bold,
                        fontSize: ResponsiveUtils.getBodyFontSize(context),
                      ),
                    ),
                    if (connectedDevices.isNotEmpty) ...[
                      SizedBox(height: ResponsiveUtils.getSmallSpacing(context)),
                      Text(
                        'Connected: ${connectedDevices.length} device(s)',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _getConnectionStatusColor(),
                          fontSize: ResponsiveUtils.getSmallFontSize(context),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              SizedBox(height: ResponsiveUtils.getSpacing(context)),

              // NEW: 3-Button Row Layout
              Row(
                children: [
                  // ESP32 Device 1 Button
                  Expanded(
                    child: _buildDeviceButton(
                      deviceNumber: 1,
                      sensorService: sensorService,
                      isPrimary: true,
                    ),
                  ),

                  SizedBox(width: ResponsiveUtils.getSmallSpacing(context)),

                  // ESP32 Device 2 Button
                  Expanded(
                    child: _buildDeviceButton(
                      deviceNumber: 2,
                      sensorService: sensorService,
                      isPrimary: false,
                    ),
                  ),

                  SizedBox(width: ResponsiveUtils.getSmallSpacing(context)),

                  // Session Button - MODIFIED: No pressure check for button color
                  Expanded(
                    child: Consumer<SessionProvider>(
                      builder: (context, sessionProvider, child) {
                        return ResponsiveButton(
                          onPressed: _toggleSession,
                          icon: sessionProvider.isSessionActive
                              ? Icons.stop
                              : Icons.play_arrow,
                          text: sessionProvider.isSessionActive
                              ? 'End Session'
                              : 'Start Session',
                          backgroundColor: sessionProvider.isSessionActive
                              ? Colors.red
                              : Colors.green, // REMOVED: Pressure check for button color
                          textColor: Colors.white,
                        );
                      },
                    ),
                  ),
                ],
              ),

              SizedBox(height: ResponsiveUtils.getSpacing(context)),

              // Voice Button and Auto-connect
              Row(
                children: [
                  // Voice Button
                  SizedBox(
                    width: ResponsiveUtils.getButtonSize(context).height,
                    height: ResponsiveUtils.getButtonSize(context).height,
                    child: IconButton(
                      onPressed: _toggleVoiceListening,
                      icon: Icon(
                        _isListeningToVoice ? Icons.mic : Icons.mic_none,
                        color: _isListeningToVoice ? Colors.red : Colors.grey,
                        size: ResponsiveUtils.getIconSize(context),
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: _isListeningToVoice
                            ? Colors.red.withOpacity(0.1)
                            : null,
                      ),
                    ),
                  ),

                  SizedBox(width: ResponsiveUtils.getSmallSpacing(context)),

                  // Auto-connect Button
                  Expanded(
                    child: ResponsiveButton(
                      onPressed: sensorService.isConnecting ? null : _connectAllDevices,
                      icon: Icons.bluetooth_searching,
                      text: 'Auto Connect All',
                      backgroundColor: Colors.purple,
                      textColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // NEW: Build individual device button
  Widget _buildDeviceButton({
    required int deviceNumber,
    required SensorService sensorService,
    required bool isPrimary,
  }) {
    final connectedDevices = sensorService.connectedDevices;
    final isConnected = connectedDevices.length >= deviceNumber;
    final device = isConnected ? connectedDevices[deviceNumber - 1] : null;

    return ResponsiveButton(
      onPressed: sensorService.isConnecting ? null : () => _connectToSensor(deviceNumber),
      icon: isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
      text: isConnected
          ? 'ESP32 $deviceNumber\n${_getShortDeviceName(device?.platformName ?? 'Device')}'
          : 'ESP32 $deviceNumber\n${isPrimary ? '(Primary)' : '(Secondary)'}',
      backgroundColor: isConnected ? Colors.blue : Colors.grey,
      textColor: Colors.white,
    );
  }

  // Helper method to shorten device name for display
  String _getShortDeviceName(String fullName) {
    if (fullName.length <= 12) return fullName;
    return '${fullName.substring(0, 10)}...';
  }

  Widget _buildAnimationPanel() {
    return Consumer2<MetricsProvider, SessionProvider>(
      builder: (context, metricsProvider, sessionProvider, child) {
        // MODIFIED: Only show compression animation when both session is active AND pressure is active
        final isCompressing = sessionProvider.isSessionActive &&
            sessionProvider.isPressureActive &&
            metricsProvider.currentPhase == CPRPhase.compression;

        return ResponsiveCard(
          color: Colors.black,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Padding(
                padding:
                EdgeInsets.all(ResponsiveUtils.getSmallSpacing(context)),
                child: ResponsiveText.title(
                  'CPR Visual',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              // Status indicator - ADDED
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveUtils.getSmallSpacing(context),
                ),
                child: Row(
                  children: [
                    Icon(
                      sessionProvider.isSessionActive
                          ? Icons.play_arrow
                          : Icons.stop,
                      color: sessionProvider.isSessionActive
                          ? Colors.green
                          : Colors.grey,
                      size: ResponsiveUtils.getSmallIconSize(context),
                    ),
                    SizedBox(width: 4),
                    Text(
                      sessionProvider.isSessionActive
                          ? 'Session Active'
                          : 'Session Inactive',
                      style: TextStyle(
                        color: sessionProvider.isSessionActive
                            ? Colors.green
                            : Colors.grey,
                        fontSize: ResponsiveUtils.getSmallFontSize(context),
                      ),
                    ),
                    Spacer(),
                    Icon(
                      sessionProvider.isPressureActive
                          ? Icons.check_circle
                          : Icons.info_outline,
                      color: sessionProvider.isPressureActive
                          ? Colors.green
                          : Colors.orange,
                      size: ResponsiveUtils.getSmallIconSize(context),
                    ),
                    SizedBox(width: 4),
                    Text(
                      sessionProvider.isPressureActive
                          ? 'Pressure Active'
                          : 'No Pressure',
                      style: TextStyle(
                        color: sessionProvider.isPressureActive
                            ? Colors.green
                            : Colors.orange,
                        fontSize: ResponsiveUtils.getSmallFontSize(context),
                      ),
                    ),
                  ],
                ),
              ),
              // Image container
              Expanded(
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.black,
                  child: Center(
                    child: Transform.scale(
                      scale: 1.3,
                      child: Image.asset(
                        isCompressing
                            ? 'assets/images/B4.png'
                            : 'assets/images/A4.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.black,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    isCompressing
                                        ? 'COMPRESSION'
                                        : 'NO COMPRESSION',
                                    style: TextStyle(
                                      fontSize:
                                      ResponsiveUtils.getBodyFontSize(context),
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    !sessionProvider.isSessionActive
                                        ? 'Start Session First'
                                        : !sessionProvider.isPressureActive
                                        ? 'Apply Pressure >10'
                                        : 'Ready for CPR',
                                    style: TextStyle(
                                      fontSize: ResponsiveUtils.getSmallFontSize(context),
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricsPanel() {
    return Consumer2<MetricsProvider, SessionProvider>(
      builder: (context, metricsProvider, sessionProvider, child) {
        return ResponsiveCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ResponsiveText.title(
                'Session Metrics',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: ResponsiveUtils.getSpacing(context)),
              Expanded(
                child: ResponsiveGrid(
                  children: [
                    _buildMetricCard(
                      'Compression Rate',
                      metricsProvider.compressionRate?.toStringAsFixed(0) ??
                          '--',
                      'BPM',
                      Icons.speed,
                      Colors.blue,
                    ),
                    _buildMetricCard(
                      'Compressions',
                      '${metricsProvider.compressionCount}',
                      'total',
                      Icons.compress,
                      Colors.blue,
                    ),
                    _buildMetricCard(
                      'Good Compressions',
                      '${metricsProvider.goodCompressions}',
                      'count',
                      Icons.check_circle,
                      Colors.green,
                    ),
                    _buildMetricCard(
                      'Good Recoils',
                      '${metricsProvider.goodRecoils}',
                      'count',
                      Icons.expand,
                      Colors.green,
                    ),
                    _buildMetricCard(
                      'Cycle Number',
                      '${metricsProvider.cycleNumber}',
                      'cycles',
                      Icons.repeat,
                      Colors.purple,
                    ),
                    _buildMetricCard(
                      'CCF',
                      metricsProvider.ccf?.toStringAsFixed(2) ?? '--',
                      'ratio',
                      Icons.timeline,
                      Colors.orange,
                    ),
                    _buildMetricCard(
                      'Session #',
                      '${sessionProvider.nextSessionNumber - (sessionProvider.isSessionActive ? 1 : 0)}',
                      'current',
                      Icons.numbers,
                      Colors.grey,
                    ),
                    // NEW: Connected Devices Card
                    _buildMetricCard(
                      'Connected Devices',
                      '${context.read<SensorService>().connectedDevices.length}',
                      'ESP32',
                      Icons.bluetooth,
                      Colors.blue,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricCard(
      String title,
      String value,
      String unit,
      IconData icon,
      Color color,
      ) {
    return ResponsiveCard(
      padding: EdgeInsets.all(ResponsiveUtils.getSmallSpacing(context)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: color,
                size: ResponsiveUtils.getIconSize(context),
              ),
              SizedBox(width: ResponsiveUtils.getSmallSpacing(context)),
              Flexible(
                child: ResponsiveText.body(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getSmallFontSize(context),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveUtils.getSmallSpacing(context)),
          ResponsiveText.title(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          ResponsiveText.small(
            unit,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // Widget _buildAlertsPanel() {
  //   return Consumer<AlertsProvider>(
  //     builder: (context, alertsProvider, child) {
  //       final alerts = alertsProvider.alertHistory;
  //
  //       return ResponsiveCard(
  //         child: Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             ResponsiveText.title(
  //               'Alerts & Feedback',
  //               style: const TextStyle(fontWeight: FontWeight.bold),
  //             ),
  //             SizedBox(height: ResponsiveUtils.getSpacing(context)),
  //             if (alerts.isEmpty)
  //               Container(
  //                 padding: EdgeInsets.all(ResponsiveUtils.getSpacing(context)),
  //                 child: ResponsiveText.body(
  //                   'No alerts at this time',
  //                   textAlign: TextAlign.center,
  //                   style: const TextStyle(color: Colors.grey),
  //                 ),
  //               )
  //             else
  //               ...alerts
  //                   .take(5) // Show only last 5 alerts
  //                   .map((alert) => Container(
  //                 margin: EdgeInsets.only(
  //                     bottom: ResponsiveUtils.getSmallSpacing(context)),
  //                 padding: EdgeInsets.all(
  //                     ResponsiveUtils.getSmallSpacing(context)),
  //                 decoration: BoxDecoration(
  //                   color: _getAlertColor(alert.type).withOpacity(0.1),
  //                   border:
  //                   Border.all(color: _getAlertColor(alert.type)),
  //                   borderRadius: BorderRadius.circular(8),
  //                 ),
  //                 child: Row(
  //                   children: [
  //                     Icon(
  //                       _getAlertIcon(alert.type),
  //                       color: _getAlertColor(alert.type),
  //                       size: ResponsiveUtils.getIconSize(context),
  //                     ),
  //                     SizedBox(
  //                         width:
  //                         ResponsiveUtils.getSmallSpacing(context)),
  //                     Expanded(
  //                       child: ResponsiveText.body(
  //                         alert.message,
  //                         style: TextStyle(
  //                           color: _getAlertColor(alert.type),
  //                         ),
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               )),
  //           ],
  //         ),
  //       );
  //     },
  //   );
  // }

  Widget _buildAlertsPanel() {
    return Consumer<AlertsProvider>(
      builder: (context, alertsProvider, child) {
        final alerts = alertsProvider.alertHistory;

        return ResponsiveCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ResponsiveText.title(
                'Alerts & Feedback',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: ResponsiveUtils.getSpacing(context)),
              if (alerts.isEmpty)
                Container(
                  padding: EdgeInsets.all(ResponsiveUtils.getSpacing(context)),
                  child: ResponsiveText.body(
                    'No alerts at this time',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                )
              else
                ...alerts
                    .take(5) // Show only last 5 alerts
                    .map((alert) => Container(
                  margin: EdgeInsets.only(
                      bottom: ResponsiveUtils.getSmallSpacing(context)),
                  padding: EdgeInsets.all(
                      ResponsiveUtils.getSmallSpacing(context)),
                  decoration: BoxDecoration(
                    color: _getAlertColor(alert.type).withOpacity(0.1),
                    border:
                    Border.all(color: _getAlertColor(alert.type)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getAlertIcon(alert.type),
                        color: _getAlertColor(alert.type),
                        size: ResponsiveUtils.getIconSize(context),
                      ),
                      SizedBox(
                          width:
                          ResponsiveUtils.getSmallSpacing(context)),
                      Expanded(
                        child: ResponsiveText.body(
                          alert.message,
                          style: TextStyle(
                            color: _getAlertColor(alert.type),
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
            ],
          ),
        );
      },
    );
  }


  Widget _buildGraphPanel() {
    return Consumer<GraphProvider>(
      builder: (context, graphProvider, child) {
        // Calculate spots with time-based x-axis
        List<FlSpot> spots = [];
        if (graphProvider.sensor1Data.isNotEmpty) {
          final firstTimestamp = graphProvider.sensor1Data.first.timestamp;
          spots = graphProvider.sensor1Data.map((dataPoint) {
            final timeDiff =
                dataPoint.timestamp.difference(firstTimestamp).inMilliseconds /
                    1000.0;
            return FlSpot(timeDiff, dataPoint.value);
          }).toList();
        }

        return ResponsiveCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ResponsiveText.title(
                'Sensor Data',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: ResponsiveUtils.getSpacing(context)),
              // Sensor selector
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveUtils.getSmallSpacing(context)),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String>(
                  value: _selectedGraphSensor,
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: ['Sensor1', 'Sensor2', 'Sensor3']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: ResponsiveText.body(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedGraphSensor = newValue;
                      });
                    }
                  },
                ),
              ),
              SizedBox(height: ResponsiveUtils.getSpacing(context)),
              // Graph
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(
                        ResponsiveUtils.getSmallSpacing(context)),
                    child: LineChart(
                      LineChartData(
                        minX: 0,
                        maxX: graphProvider.timeSpanSeconds,
                        minY: 0,
                        maxY: 1024,
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: true,
                            color: Colors.blue,
                            barWidth: 2,
                            isStrokeCapRound: true,
                            belowBarData: BarAreaData(show: false),
                            dotData: const FlDotData(show: false),
                          ),
                        ],
                        titlesData: FlTitlesData(
                          show: true,
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 20,
                              interval: 5, // Show label every 5 seconds
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  '${value.toInt()}s',
                                  style: TextStyle(
                                    fontSize: ResponsiveUtils.getSmallFontSize(
                                        context),
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              interval: 256,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  '${value.toInt()}',
                                  style: TextStyle(
                                    fontSize: ResponsiveUtils.getSmallFontSize(
                                        context),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        gridData: const FlGridData(show: true),
                        borderData: FlBorderData(
                          show: true,
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getConnectionStatusColor() {
    switch (_connectionStatus) {
      case 'Connected':
        return Colors.green;
      case 'Connecting...':
        return Colors.orange;
      case 'Not connected':
        return Colors.red;
    }
    return Colors.grey;
  }

  Color _getAlertColor(AlertType type) {
    switch (type) {
      case AlertType.goFaster:
        return Colors.blue;
      case AlertType.slowDown:
        return Colors.orange;
      case AlertType.beGentle:
        return Colors.red;
      case AlertType.releaseMore:
        return Colors.purple;
    }
    return Colors.grey;
  }

  IconData _getAlertIcon(AlertType type) {
    switch (type) {
      case AlertType.goFaster:
        return Icons.speed;
      case AlertType.slowDown:
        return Icons.warning;
      case AlertType.beGentle:
        return Icons.error;
      case AlertType.releaseMore:
        return Icons.expand;
    }
    return Icons.info;
  }

  @override
  void dispose() {
    _animationController.dispose();
    _sensorDataSubscription?.cancel();
    _connectionStatusSubscription?.cancel();
    _deviceConnectionSubscription?.cancel();

    // Stop voice listening if active
    if (_isListeningToVoice) {
      context.read<VoiceService>().stopListening();
    }

    super.dispose();
  }
}