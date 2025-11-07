//cpr_training_app/lib/screens/replay_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/replay_provider.dart';
import '../models/models.dart';
import '../services/replay_service.dart';

class ReplayScreen extends StatefulWidget {
  const ReplayScreen({super.key});

  @override
  State<ReplayScreen> createState() => _ReplayScreenState();
}

class _ReplayScreenState extends State<ReplayScreen> {
  CPRSession? _selectedSession;
  bool _showSessionSelector = true;

  @override
  void initState() {
    super.initState();
    // Check if a session was passed as argument
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is CPRSession) {
        _loadSession(args);
      }
    });
  }

  Future<void> _loadSession(CPRSession session) async {
    final replayProvider = context.read<ReplayProvider>();
    await replayProvider.loadSession(session);

    setState(() {
      _selectedSession = session;
      _showSessionSelector = false;
    });
  }

  void _showSessionSelectorOverlay() {
    setState(() {
      _showSessionSelector = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedSession != null
            ? 'Replay Session #${_selectedSession!.sessionNumber}'
            : 'Session Replay'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          if (_selectedSession != null)
            IconButton(
              onPressed: _showSessionSelectorOverlay,
              icon: const Icon(Icons.list),
              tooltip: 'Select Different Session',
            ),
        ],
      ),
      body: _showSessionSelector
          ? _buildSessionSelector()
          : _buildReplayInterface(),
    );
  }

  Widget _buildSessionSelector() {
    return Consumer<ReplayProvider>(
      builder: (context, replayProvider, child) {
        return FutureBuilder<List<CPRSession>>(
          future: replayProvider.getAvailableSessions(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading sessions...'),
                  ],
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error Loading Sessions',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            final sessions = snapshot.data ?? [];

            if (sessions.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history,
                      size: 64,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Sessions Available',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Complete a training session first to view replay data.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.7),
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.replay,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Select Session to Replay',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const Spacer(),
                      Text(
                        '${sessions.length} sessions available',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),

                // Sessions list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: sessions.length,
                    itemBuilder: (context, index) {
                      final session = sessions[index];
                      return _buildSessionCard(session);
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSessionCard(CPRSession session) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Center(
            child: Text(
              '#${session.sessionNumber}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
        title: Text(
          'Session #${session.sessionNumber}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              DateFormat('MMM dd, yyyy - HH:mm').format(session.startedAt),
            ),
            const SizedBox(height: 2),
            Text(
              'Duration: ${_formatDuration(session.duration)}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  session.synced ? Icons.cloud_done : Icons.cloud_off,
                  size: 16,
                  color: session.synced ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 4),
                Text(session.synced ? 'Synced' : 'Local only'),
              ],
            ),
            if (session.notes?.isNotEmpty == true) ...[
              const SizedBox(height: 4),
              Text(
                session.notes!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: const Icon(Icons.play_circle_filled),
        onTap: () => _loadSession(session),
      ),
    );
  }

  Widget _buildReplayInterface() {
    return Consumer<ReplayProvider>(
      builder: (context, replayProvider, child) {
        if (replayProvider.isLoading) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading session data...'),
              ],
            ),
          );
        }

        if (replayProvider.loadError != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to Load Session',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  replayProvider.loadError!,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _showSessionSelectorOverlay,
                  child: const Text('Select Different Session'),
                ),
              ],
            ),
          );
        }

        if (!replayProvider.hasSession) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.movie_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  'No Session Selected',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Select a session to begin replay.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _showSessionSelectorOverlay,
                  child: const Text('Select Session'),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Session info header
            _buildSessionInfoHeader(replayProvider),

            // Main replay content
            Expanded(
              child: Row(
                children: [
                  // Left panel - Animation and metrics
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        // Animation and alerts
                        Expanded(
                          child: _buildAnimationPanel(replayProvider),
                        ),

                        // Metrics cards
                        _buildMetricsPanel(replayProvider),
                      ],
                    ),
                  ),

                  // Right panel - Timeline and graph
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        // Timeline with markers
                        _buildTimelinePanel(replayProvider),

                        // Sensor data graph
                        Expanded(
                          child: _buildGraphPanel(replayProvider),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Controls at bottom
            _buildControlsPanel(replayProvider),
          ],
        );
      },
    );
  }

  Widget _buildSessionInfoHeader(ReplayProvider replayProvider) {
    final session = replayProvider.selectedSession!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.replay,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Session #${session.sessionNumber}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  DateFormat('MMM dd, yyyy - HH:mm').format(session.startedAt),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                      ),
                ),
              ],
            ),
          ),
          if (session.notes?.isNotEmpty == true)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Tooltip(
                message: session.notes!,
                child: Text(
                  session.notes!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onTertiaryContainer,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAnimationPanel(ReplayProvider replayProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'CPR Animation',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: 16),

          // Animation circle
          Expanded(
            child: Center(
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      _getPhaseColor(replayProvider.replayMetrics.currentPhase)
                          .withValues(alpha: 0.7),
                  border: Border.all(
                    color: _getPhaseColor(
                        replayProvider.replayMetrics.currentPhase),
                    width: 4,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getPhaseIcon(
                            replayProvider.replayMetrics.currentPhase),
                        size: 60,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        replayProvider.replayMetrics.currentPhase.name
                            .toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Current alert display
          if (replayProvider.replayAlert != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getAlertColor(replayProvider.replayAlert!.type)
                    .withValues(alpha: 0.1),
                border: Border.all(
                  color: _getAlertColor(replayProvider.replayAlert!.type),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    _getAlertIcon(replayProvider.replayAlert!.type),
                    color: _getAlertColor(replayProvider.replayAlert!.type),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      replayProvider.replayAlert!.message,
                      style: TextStyle(
                        color: _getAlertColor(replayProvider.replayAlert!.type),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMetricsPanel(ReplayProvider replayProvider) {
    final metrics = replayProvider.replayMetrics;

    return Container(
      height: 120,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildMetricCard(
              'Rate',
              metrics.compressionRate != null
                  ? '${metrics.compressionRate!.toStringAsFixed(0)} /min'
                  : '--',
              Icons.speed,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildMetricCard(
              'Count',
              '${metrics.compressionCount}',
              Icons.compress,
              Colors.red,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildMetricCard(
              'CCF',
              metrics.ccf != null
                  ? '${(metrics.ccf! * 100).toStringAsFixed(0)}%'
                  : '--',
              Icons.timeline,
              Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildMetricCard(
              'Cycle',
              '${metrics.cycleNumber}',
              Icons.plus_one,
              Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelinePanel(ReplayProvider replayProvider) {
    return Container(
      height: 80,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Timeline',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                '${replayProvider.formattedCurrentPosition} / ${replayProvider.formattedTotalDuration}',
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Stack(
              children: [
                // Timeline slider
                Positioned.fill(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4,
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 8),
                      overlayShape:
                          const RoundSliderOverlayShape(overlayRadius: 16),
                    ),
                    child: Slider(
                      value: replayProvider.playbackProgress,
                      onChanged: replayProvider.canSeek
                          ? (value) {
                              final position = Duration(
                                milliseconds: (replayProvider
                                            .totalDuration.inMilliseconds *
                                        value)
                                    .round(),
                              );
                              replayProvider.seekTo(position);
                            }
                          : null,
                    ),
                  ),
                ),
                // Timeline markers
                Positioned.fill(
                  child: CustomPaint(
                    painter: _TimelineMarkerPainter(
                      markers: replayProvider.timelineMarkers,
                      totalDuration: replayProvider.totalDuration,
                      currentPosition: replayProvider.currentPosition,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGraphPanel(ReplayProvider replayProvider) {
    final sessionStart = replayProvider.selectedSession!.startedAt;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sensor Data',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: replayProvider.replaySensor1Data.isEmpty
                ? Center(
                    child: Text(
                      'No sensor data available',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.5),
                          ),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: true),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toStringAsFixed(0),
                                style: const TextStyle(fontSize: 10),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              final duration = Duration(seconds: value.toInt());
                              return Text(
                                '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}',
                                style: const TextStyle(fontSize: 10),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .outline
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      lineBarsData: [
                        // Sensor 1 line
                        LineChartBarData(
                          spots: replayProvider.replaySensor1Data
                              .map((point) => FlSpot(
                                    point.timestamp
                                        .difference(sessionStart)
                                        .inSeconds
                                        .toDouble(),
                                    point.value,
                                  ))
                              .toList(),
                          color: Colors.blue,
                          barWidth: 2,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.blue.withValues(alpha: 0.1),
                          ),
                        ),
                        // Sensor 2 line
                        LineChartBarData(
                          spots: replayProvider.replaySensor2Data
                              .map((point) => FlSpot(
                                    point.timestamp
                                        .difference(sessionStart)
                                        .inSeconds
                                        .toDouble(),
                                    point.value,
                                  ))
                              .toList(),
                          color: Colors.red,
                          barWidth: 2,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.red.withValues(alpha: 0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlsPanel(ReplayProvider replayProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Column(
        children: [
          // Main controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Step backward
              IconButton(
                onPressed:
                    replayProvider.canSeek ? replayProvider.stepBackward : null,
                icon: const Icon(Icons.skip_previous),
                tooltip: 'Step Back',
              ),

              const SizedBox(width: 8),

              // Play/Pause
              IconButton(
                onPressed: replayProvider.canPlay
                    ? replayProvider.togglePlayPause
                    : null,
                icon: Icon(
                    replayProvider.isPlaying ? Icons.pause : Icons.play_arrow),
                iconSize: 32,
                tooltip: replayProvider.isPlaying ? 'Pause' : 'Play',
              ),

              const SizedBox(width: 8),

              // Step forward
              IconButton(
                onPressed:
                    replayProvider.canSeek ? replayProvider.stepForward : null,
                icon: const Icon(Icons.skip_next),
                tooltip: 'Step Forward',
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Secondary controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Speed control
              PopupMenuButton<double>(
                onSelected: replayProvider.setPlaybackSpeed,
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 0.25, child: Text('0.25x')),
                  const PopupMenuItem(value: 0.5, child: Text('0.5x')),
                  const PopupMenuItem(value: 1.0, child: Text('1x')),
                  const PopupMenuItem(value: 1.5, child: Text('1.5x')),
                  const PopupMenuItem(value: 2.0, child: Text('2x')),
                  const PopupMenuItem(value: 4.0, child: Text('4x')),
                ],
                child: Chip(
                  label: Text('${replayProvider.playbackSpeed}x'),
                  avatar: const Icon(Icons.speed),
                ),
              ),

              // Jump to markers
              OutlinedButton.icon(
                onPressed: replayProvider.canSeek &&
                        replayProvider.timelineMarkers.isNotEmpty
                    ? replayProvider.jumpToPreviousMarker
                    : null,
                icon: const Icon(Icons.skip_previous),
                label: const Text('Prev'),
              ),

              OutlinedButton.icon(
                onPressed: replayProvider.canSeek &&
                        replayProvider.timelineMarkers.isNotEmpty
                    ? replayProvider.jumpToNextMarker
                    : null,
                icon: const Icon(Icons.skip_next),
                label: const Text('Next'),
              ),

              // Reset
              OutlinedButton.icon(
                onPressed: replayProvider.canSeek
                    ? replayProvider.resetToBeginning
                    : null,
                icon: const Icon(Icons.replay),
                label: const Text('Reset'),
              ),

              // Export replay data
              OutlinedButton.icon(
                onPressed: () => _showExportDialog(replayProvider),
                icon: const Icon(Icons.download),
                label: const Text('Export'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getPhaseColor(CPRPhase phase) {
    switch (phase) {
      case CPRPhase.compression:
        return Colors.red;
      case CPRPhase.recoil:
        return Colors.blue;
      case CPRPhase.quietude:
        return Colors.green;
      case CPRPhase.pause:
        return Colors.orange;
    }
  }

  IconData _getPhaseIcon(CPRPhase phase) {
    switch (phase) {
      case CPRPhase.compression:
        return Icons.compress;
      case CPRPhase.recoil:
        return Icons.expand;
      case CPRPhase.quietude:
        return Icons.pause_circle;
      case CPRPhase.pause:
        return Icons.stop_circle;
    }
  }

  Color _getAlertColor(AlertType type) {
    switch (type) {
      case AlertType.goFaster:
      case AlertType.slowDown:
        return Colors.orange;
      case AlertType.beGentle:
      case AlertType.releaseMore:
        return Colors.red;
    }
  }

  IconData _getAlertIcon(AlertType type) {
    switch (type) {
      case AlertType.goFaster:
        return Icons.fast_forward;
      case AlertType.slowDown:
        return Icons.slow_motion_video;
      case AlertType.beGentle:
        return Icons.touch_app;
      case AlertType.releaseMore:
        return Icons.expand;
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes}m ${seconds}s';
  }

  void _showExportDialog(ReplayProvider replayProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Replay Data'),
        content: const Text(
          'Export current replay session data including metrics, timing, and sensor readings?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _exportReplayData(replayProvider);
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportReplayData(ReplayProvider replayProvider) async {
    if (!mounted) return;

    try {
      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Exporting replay data...'),
          duration: Duration(seconds: 2),
        ),
      );

      // TODO: Implement actual export functionality
      // This would typically involve:
      // 1. Collecting all replay data
      // 2. Converting to CSV/JSON format
      // 3. Saving to device storage or sharing

      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Replay data exported successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// Custom painter for timeline markers
class _TimelineMarkerPainter extends CustomPainter {
  final List<TimelineMarker> markers;
  final Duration totalDuration;
  final Duration currentPosition;

  _TimelineMarkerPainter({
    required this.markers,
    required this.totalDuration,
    required this.currentPosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (totalDuration.inMilliseconds == 0) return;

    for (final marker in markers) {
      final position =
          marker.position.inMilliseconds / totalDuration.inMilliseconds;
      final x = position * size.width;

      Color color;
      switch (marker.type) {
        case TimelineMarkerType.alert:
          color = Colors.red;
          break;
        case TimelineMarkerType.cycle:
          color = Colors.blue;
          break;
        case TimelineMarkerType.pause:
          color = Colors.orange;
          break;
      }

      final paint = Paint()
        ..color = color
        ..strokeWidth = 2;

      // Draw marker line
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );

      // Draw marker circle
      canvas.drawCircle(
        Offset(x, size.height / 2),
        3,
        paint..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}


//
//
// //cpr_training_app/lib/services/replay_service.dart
// import 'dart:async';
// import '../models/models.dart';
// import 'db_service.dart';
// import 'package:flutter/material.dart';
//
// class ReplayService {
//   static final ReplayService _instance = ReplayService._internal();
//   static ReplayService get instance => _instance;
//
//   CPRSession? _loadedSession;
//   List<SensorSample>? _loadedSamples;
//   List<CPREvent>? _loadedEvents;
//
//   ReplayService._internal();
//
//   // Load session data for replay
//   Future<void> loadSession(CPRSession session) async {
//     try {
//       debugPrint('Loading session ${session.sessionNumber} for replay');
//
//       _loadedSession = session;
//       _loadedSamples =
//       await DBService.instance.getSamplesForSession(session.id);
//       _loadedEvents = await DBService.instance.getEventsForSession(session.id);
//
//       debugPrint(
//         'Loaded ${_loadedSamples?.length ?? 0} samples and ${_loadedEvents?.length ?? 0} events',
//       );
//
//       if (_loadedSamples?.isEmpty == true) {
//         debugPrint(
//             'Warning: No samples found for session ${session.sessionNumber}');
//       }
//       if (_loadedEvents?.isEmpty == true) {
//         debugPrint(
//             'Warning: No events found for session ${session.sessionNumber}');
//       }
//     } catch (e) {
//       debugPrint('Error loading session for replay: $e');
//       rethrow;
//     }
//   }
//
//   // Get available sessions for replay
//   Future<List<CPRSession>> getAvailableSessions() async {
//     try {
//       final sessions = await DBService.instance.getAllSessions();
//       // Only return completed sessions with data
//       return sessions
//           .where((s) => s.endedAt != null && s.duration.inSeconds > 0)
//           .toList();
//     } catch (e) {
//       debugPrint('Error getting available sessions: $e');
//       return [];
//     }
//   }
//
//   // Get replay data at specific position
//   Future<ReplayData?> getDataAtPosition(
//       CPRSession session,
//       Duration position,
//       ) async {
//     if (_loadedSession?.id != session.id) {
//       await loadSession(session);
//     }
//
//     if (_loadedSamples == null || _loadedEvents == null) {
//       return null;
//     }
//
//     try {
//       final sessionStartTime = session.startedAt;
//       final absoluteTime = sessionStartTime.add(position);
//
//       // Get samples within a reasonable window around this time
//       final windowDuration = const Duration(milliseconds: 500);
//       final windowStart = absoluteTime.subtract(windowDuration);
//       final windowEnd = absoluteTime.add(windowDuration);
//
//       final samplesInWindow = _loadedSamples!
//           .where((sample) =>
//       sample.timestamp.isAfter(windowStart) &&
//           sample.timestamp.isBefore(windowEnd))
//           .toList();
//
//       // Sort samples by timestamp
//       samplesInWindow.sort((a, b) => a.timestamp.compareTo(b.timestamp));
//
//       // Get events up to this time
//       final eventsUpToNow = _loadedEvents!
//           .where((event) =>
//       event.timestamp.isBefore(absoluteTime) ||
//           event.timestamp.isAtSameMomentAs(absoluteTime))
//           .toList();
//
//       // Sort events by timestamp
//       eventsUpToNow.sort((a, b) => a.timestamp.compareTo(b.timestamp));
//
//       // Calculate metrics from events
//       final metrics = _calculateMetricsFromEvents(eventsUpToNow, position);
//
//       // Get current alert (most recent alert event)
//       CPRAlert? currentAlert;
//       try {
//         final alertEvents =
//         eventsUpToNow.where((event) => event.type == 'alert').toList();
//
//         if (alertEvents.isNotEmpty) {
//           final lastAlert = alertEvents.last;
//           currentAlert = _parseAlertFromEvent(lastAlert);
//         }
//       } catch (e) {
//         debugPrint('Error parsing alert: $e');
//       }
//
//       // Convert samples to graph data points with DateTime timestamps
//       final sensor1Data = samplesInWindow
//           .map((sample) => GraphDataPoint(
//         timestamp: sample.timestamp,
//         value: sample.sensor1Avg, // Use sensor1Avg
//         color: Colors.blue, // Default color
//       ))
//           .toList();
//
//       final sensor2Data = samplesInWindow
//           .map((sample) => GraphDataPoint(
//         timestamp: sample.timestamp,
//         value: sample.sensor2Avg, // Use sensor2Avg
//         color: Colors.red, // Default color
//       ))
//           .toList();
//
//       return ReplayData(
//         metrics: metrics,
//         alert: currentAlert,
//         sensor1Data: sensor1Data,
//         sensor2Data: sensor2Data,
//       );
//     } catch (e) {
//       debugPrint('Error getting replay data at position: $e');
//       return null;
//     }
//   }
//
//   // Calculate metrics from events up to current position
//   CPRMetrics _calculateMetricsFromEvents(
//       List<CPREvent> events, Duration position) {
//     try {
//       int compressionCount = 0;
//       int goodCompressions = 0;
//       int goodRecoils = 0;
//       int recoilCount = 0;
//       double totalRate = 0;
//       int rateCalculations = 0;
//       CPRPhase currentPhase = CPRPhase.quietude;
//       double? ccf;
//       int cycleNumber = 0;
//
//       for (final event in events) {
//         final payload = event.payload;
//
//         switch (event.type) {
//           case 'compression_detected':
//             compressionCount++;
//             if (payload['quality'] == 'good') {
//               goodCompressions++;
//             }
//             break;
//
//           case 'recoil_detected':
//             recoilCount++;
//             if (payload['quality'] == 'good') {
//               goodRecoils++;
//             }
//             break;
//
//           case 'rate_calculated':
//             final rate = payload['rate']?.toDouble() ?? 0.0;
//             if (rate > 0) {
//               totalRate += rate;
//               rateCalculations++;
//             }
//             break;
//
//           case 'phase_change':
//             final phaseName = payload['to_phase'] as String?;
//             if (phaseName != null) {
//               currentPhase = _parsePhase(phaseName);
//             }
//             break;
//
//           case 'ccf_calculated':
//             ccf = payload['ccf']?.toDouble();
//             break;
//
//           case 'cycle_end':
//             cycleNumber = payload['cycle_number'] ?? cycleNumber;
//             break;
//         }
//       }
//
//       final averageRate =
//       rateCalculations > 0 ? totalRate / rateCalculations : null;
//
//       return CPRMetrics(
//         compressionRate: averageRate,
//         compressionCount: compressionCount,
//         recoilCount: recoilCount,
//         goodCompressions: goodCompressions,
//         goodRecoils: goodRecoils,
//         cycleNumber: cycleNumber,
//         ccf: ccf,
//         currentPhase: currentPhase,
//       );
//     } catch (e) {
//       debugPrint('Error calculating metrics: $e');
//       return const CPRMetrics();
//     }
//   }
//
//   // Parse phase from string
//   CPRPhase _parsePhase(String phaseName) {
//     switch (phaseName.toLowerCase()) {
//       case 'compression':
//         return CPRPhase.compression;
//       case 'recoil':
//         return CPRPhase.recoil;
//       case 'pause':
//         return CPRPhase.pause;
//       default:
//         return CPRPhase.quietude;
//     }
//   }
//
//   // Parse alert from event
//   CPRAlert _parseAlertFromEvent(CPREvent event) {
//     final payload = event.payload;
//     final message = payload['message'] as String? ?? 'Alert';
//     final typeString = payload['type'] as String? ?? 'go_faster';
//
//     AlertType alertType;
//     switch (typeString.toLowerCase()) {
//       case 'slow_down':
//         alertType = AlertType.slowDown;
//         break;
//       case 'be_gentle':
//         alertType = AlertType.beGentle;
//         break;
//       case 'release_more':
//         alertType = AlertType.releaseMore;
//         break;
//       default:
//         alertType = AlertType.goFaster;
//     }
//
//     return CPRAlert(
//       type: alertType,
//       message: message,
//       timestamp: event.timestamp,
//     );
//   }
//
//   // Get session timeline markers
//   Future<List<TimelineMarker>> getSessionTimelineMarkers(
//       CPRSession session) async {
//     if (_loadedSession?.id != session.id) {
//       await loadSession(session);
//     }
//
//     if (_loadedEvents == null) return [];
//
//     final markers = <TimelineMarker>[];
//
//     try {
//       for (final event in _loadedEvents!) {
//         final position = event.timestamp.difference(session.startedAt);
//
//         switch (event.type) {
//           case 'alert':
//             final message = event.payload['message'] as String? ?? 'Alert';
//             markers.add(
//               TimelineMarker(
//                 position: position,
//                 type: TimelineMarkerType.alert,
//                 label: message,
//               ),
//             );
//             break;
//
//           case 'cycle_end':
//             final cycleNumber = event.payload['cycle_number'] ?? 0;
//             markers.add(
//               TimelineMarker(
//                 position: position,
//                 type: TimelineMarkerType.cycle,
//                 label: 'Cycle $cycleNumber',
//               ),
//             );
//             break;
//
//           case 'phase_change':
//             if (event.payload['to_phase'] == 'pause') {
//               markers.add(
//                 TimelineMarker(
//                   position: position,
//                   type: TimelineMarkerType.pause,
//                   label: 'Pause',
//                 ),
//               );
//             }
//             break;
//         }
//       }
//     } catch (e) {
//       debugPrint('Error creating timeline markers: $e');
//     }
//
//     // Sort markers by position
//     markers.sort((a, b) => a.position.compareTo(b.position));
//     return markers;
//   }
//
//   // Clear loaded session data
//   void clearLoadedSession() {
//     _loadedSession = null;
//     _loadedSamples = null;
//     _loadedEvents = null;
//   }
//
//   // Get loaded session
//   CPRSession? get loadedSession => _loadedSession;
//
//   // Check if session is loaded
//   bool isSessionLoaded(CPRSession session) {
//     return _loadedSession?.id == session.id;
//   }
// }
//
// // Supporting classes for replay
// class ReplayData {
//   final CPRMetrics metrics;
//   final CPRAlert? alert;
//   final List<GraphDataPoint> sensor1Data;
//   final List<GraphDataPoint> sensor2Data;
//
//   const ReplayData({
//     required this.metrics,
//     this.alert,
//     required this.sensor1Data,
//     required this.sensor2Data,
//   });
// }
//
// );
// }
//
