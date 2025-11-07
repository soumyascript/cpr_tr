// //cpr_training_app/lib/screens/replay_screen.dart
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:intl/intl.dart';
// import 'package:fl_chart/fl_chart.dart';
// import '../providers/replay_provider.dart';
// import '../models/models.dart';
// import '../services/replay_service.dart';
//
// class ReplayScreen extends StatefulWidget {
//   const ReplayScreen({super.key});
//
//   @override
//   State<ReplayScreen> createState() => _ReplayScreenState();
// }
//
// class _ReplayScreenState extends State<ReplayScreen> {
//   CPRSession? _selectedSession;
//   bool _showSessionSelector = true;
//
//   @override
//   void initState() {
//     super.initState();
//     // Check if a session was passed as argument
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       final args = ModalRoute.of(context)?.settings.arguments;
//       if (args is CPRSession) {
//         _loadSession(args);
//       }
//     });
//   }
//
//   Future<void> _loadSession(CPRSession session) async {
//     final replayProvider = context.read<ReplayProvider>();
//     await replayProvider.loadSession(session);
//
//     setState(() {
//       _selectedSession = session;
//       _showSessionSelector = false;
//     });
//   }
//
//   void _showSessionSelectorOverlay() {
//     setState(() {
//       _showSessionSelector = true;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(_selectedSession != null
//             ? 'Replay Session #${_selectedSession!.sessionNumber}'
//             : 'Session Replay'),
//         backgroundColor: Theme.of(context).colorScheme.primary,
//         foregroundColor: Theme.of(context).colorScheme.onPrimary,
//         actions: [
//           if (_selectedSession != null)
//             IconButton(
//               onPressed: _showSessionSelectorOverlay,
//               icon: const Icon(Icons.list),
//               tooltip: 'Select Different Session',
//             ),
//         ],
//       ),
//       body: _showSessionSelector
//           ? _buildSessionSelector()
//           : _buildReplayInterface(),
//     );
//   }
//
//   Widget _buildSessionSelector() {
//     return Consumer<ReplayProvider>(
//       builder: (context, replayProvider, child) {
//         return FutureBuilder<List<CPRSession>>(
//           future: replayProvider.getAvailableSessions(),
//           builder: (context, snapshot) {
//             if (snapshot.connectionState == ConnectionState.waiting) {
//               return const Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     CircularProgressIndicator(),
//                     SizedBox(height: 16),
//                     Text('Loading sessions...'),
//                   ],
//                 ),
//               );
//             }
//
//             if (snapshot.hasError) {
//               return Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(
//                       Icons.error_outline,
//                       size: 64,
//                       color: Theme.of(context).colorScheme.error,
//                     ),
//                     const SizedBox(height: 16),
//                     Text(
//                       'Error Loading Sessions',
//                       style: Theme.of(context).textTheme.titleLarge,
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       snapshot.error.toString(),
//                       textAlign: TextAlign.center,
//                     ),
//                   ],
//                 ),
//               );
//             }
//
//             final sessions = snapshot.data ?? [];
//
//             if (sessions.isEmpty) {
//               return Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(
//                       Icons.history,
//                       size: 64,
//                       color: Theme.of(context).colorScheme.outline,
//                     ),
//                     const SizedBox(height: 16),
//                     Text(
//                       'No Sessions Available',
//                       style: Theme.of(context).textTheme.titleLarge,
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       'Complete a training session first to view replay data.',
//                       style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                         color: Theme.of(context)
//                             .colorScheme
//                             .onSurface
//                             .withValues(alpha: 0.7),
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                   ],
//                 ),
//               );
//             }
//
//             return Column(
//               children: [
//                 // Header
//                 Container(
//                   padding: const EdgeInsets.all(16),
//                   decoration: BoxDecoration(
//                     color:
//                     Theme.of(context).colorScheme.surfaceContainerHighest,
//                     border: Border(
//                       bottom: BorderSide(
//                         color: Theme.of(context)
//                             .colorScheme
//                             .outline
//                             .withValues(alpha: 0.2),
//                       ),
//                     ),
//                   ),
//                   child: Row(
//                     children: [
//                       Icon(Icons.replay,
//                           color: Theme.of(context).colorScheme.primary),
//                       const SizedBox(width: 8),
//                       Text(
//                         'Select Session to Replay',
//                         style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       const Spacer(),
//                       Text(
//                         '${sessions.length} sessions available',
//                         style: Theme.of(context).textTheme.bodyMedium,
//                       ),
//                     ],
//                   ),
//                 ),
//
//                 // Sessions list
//                 Expanded(
//                   child: ListView.builder(
//                     padding: const EdgeInsets.all(16),
//                     itemCount: sessions.length,
//                     itemBuilder: (context, index) {
//                       final session = sessions[index];
//                       return _buildSessionCard(session);
//                     },
//                   ),
//                 ),
//               ],
//             );
//           },
//         );
//       },
//     );
//   }
//
//   Widget _buildSessionCard(CPRSession session) {
//     return Card(
//       margin: const EdgeInsets.only(bottom: 12),
//       child: ListTile(
//         contentPadding: const EdgeInsets.all(16),
//         leading: Container(
//           width: 50,
//           height: 50,
//           decoration: BoxDecoration(
//             color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
//             borderRadius: BorderRadius.circular(25),
//           ),
//           child: Center(
//             child: Text(
//               '#${session.sessionNumber}',
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 color: Theme.of(context).colorScheme.primary,
//               ),
//             ),
//           ),
//         ),
//         title: Text(
//           'Session #${session.sessionNumber}',
//           style: const TextStyle(fontWeight: FontWeight.bold),
//         ),
//         subtitle: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const SizedBox(height: 4),
//             Text(
//               DateFormat('MMM dd, yyyy - HH:mm').format(session.startedAt),
//             ),
//             const SizedBox(height: 2),
//             Text(
//               'Duration: ${_formatDuration(session.duration)}',
//               style: TextStyle(
//                 color: Theme.of(context).colorScheme.primary,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//             const SizedBox(height: 4),
//             Row(
//               children: [
//                 Icon(
//                   session.synced ? Icons.cloud_done : Icons.cloud_off,
//                   size: 16,
//                   color: session.synced ? Colors.green : Colors.orange,
//                 ),
//                 const SizedBox(width: 4),
//                 Text(session.synced ? 'Synced' : 'Local only'),
//               ],
//             ),
//             if (session.notes?.isNotEmpty == true) ...[
//               const SizedBox(height: 4),
//               Text(
//                 session.notes!,
//                 style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                   fontStyle: FontStyle.italic,
//                 ),
//                 maxLines: 2,
//                 overflow: TextOverflow.ellipsis,
//               ),
//             ],
//           ],
//         ),
//         trailing: const Icon(Icons.play_circle_filled),
//         onTap: () => _loadSession(session),
//       ),
//     );
//   }
//
//   Widget _buildReplayInterface() {
//     return Consumer<ReplayProvider>(
//       builder: (context, replayProvider, child) {
//         if (replayProvider.isLoading) {
//           return const Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 CircularProgressIndicator(),
//                 SizedBox(height: 16),
//                 Text('Loading session data...'),
//               ],
//             ),
//           );
//         }
//
//         if (replayProvider.loadError != null) {
//           return Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(
//                   Icons.error_outline,
//                   size: 64,
//                   color: Theme.of(context).colorScheme.error,
//                 ),
//                 const SizedBox(height: 16),
//                 Text(
//                   'Failed to Load Session',
//                   style: Theme.of(context).textTheme.titleLarge,
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   replayProvider.loadError!,
//                   textAlign: TextAlign.center,
//                 ),
//                 const SizedBox(height: 16),
//                 ElevatedButton(
//                   onPressed: _showSessionSelectorOverlay,
//                   child: const Text('Select Different Session'),
//                 ),
//               ],
//             ),
//           );
//         }
//
//         if (!replayProvider.hasSession) {
//           return Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(
//                   Icons.movie_outlined,
//                   size: 64,
//                   color: Theme.of(context).colorScheme.outline,
//                 ),
//                 const SizedBox(height: 16),
//                 Text(
//                   'No Session Selected',
//                   style: Theme.of(context).textTheme.titleLarge,
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   'Select a session to begin replay.',
//                   style: Theme.of(context).textTheme.bodyMedium,
//                 ),
//                 const SizedBox(height: 16),
//                 ElevatedButton(
//                   onPressed: _showSessionSelectorOverlay,
//                   child: const Text('Select Session'),
//                 ),
//               ],
//             ),
//           );
//         }
//
//         return Column(
//           children: [
//             // Session info header
//             _buildSessionInfoHeader(replayProvider),
//
//             // Main replay content
//             Expanded(
//               child: Row(
//                 children: [
//                   // Left panel - Animation and metrics
//                   Expanded(
//                     flex: 2,
//                     child: Column(
//                       children: [
//                         // Animation and alerts
//                         Expanded(
//                           child: _buildAnimationPanel(replayProvider),
//                         ),
//
//                         // Metrics cards
//                         _buildMetricsPanel(replayProvider),
//                       ],
//                     ),
//                   ),
//
//                   // Right panel - Timeline and graph
//                   Expanded(
//                     flex: 3,
//                     child: Column(
//                       children: [
//                         // Timeline with markers
//                         _buildTimelinePanel(replayProvider),
//
//                         // Sensor data graph
//                         Expanded(
//                           child: _buildGraphPanel(replayProvider),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//
//             // Controls at bottom
//             _buildControlsPanel(replayProvider),
//           ],
//         );
//       },
//     );
//   }
//
//   Widget _buildSessionInfoHeader(ReplayProvider replayProvider) {
//     final session = replayProvider.selectedSession!;
//
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Theme.of(context).colorScheme.surfaceContainerHigh,
//         border: Border(
//           bottom: BorderSide(
//             color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
//           ),
//         ),
//       ),
//       child: Row(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(8),
//             decoration: BoxDecoration(
//               color:
//               Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: Icon(
//               Icons.replay,
//               color: Theme.of(context).colorScheme.primary,
//             ),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Session #${session.sessionNumber}',
//                   style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 Text(
//                   DateFormat('MMM dd, yyyy - HH:mm').format(session.startedAt),
//                   style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                     color: Theme.of(context)
//                         .colorScheme
//                         .onSurface
//                         .withValues(alpha: 0.7),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           if (session.notes?.isNotEmpty == true)
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//               decoration: BoxDecoration(
//                 color: Theme.of(context).colorScheme.tertiaryContainer,
//                 borderRadius: BorderRadius.circular(4),
//               ),
//               child: Tooltip(
//                 message: session.notes!,
//                 child: Text(
//                   session.notes!,
//                   style: TextStyle(
//                     color: Theme.of(context).colorScheme.onTertiaryContainer,
//                     fontSize: 12,
//                   ),
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildAnimationPanel(ReplayProvider replayProvider) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         children: [
//           Text(
//             'CPR Animation',
//             style: Theme.of(context).textTheme.titleMedium?.copyWith(
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//
//           const SizedBox(height: 16),
//
//           // Animation circle
//           Expanded(
//             child: Center(
//               child: Container(
//                 width: 200,
//                 height: 200,
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   color:
//                   _getPhaseColor(replayProvider.replayMetrics.currentPhase)
//                       .withValues(alpha: 0.7),
//                   border: Border.all(
//                     color: _getPhaseColor(
//                         replayProvider.replayMetrics.currentPhase),
//                     width: 4,
//                   ),
//                 ),
//                 child: Center(
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Icon(
//                         _getPhaseIcon(
//                             replayProvider.replayMetrics.currentPhase),
//                         size: 60,
//                         color: Colors.white,
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         replayProvider.replayMetrics.currentPhase.name
//                             .toUpperCase(),
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontWeight: FontWeight.bold,
//                           fontSize: 16,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ),
//
//           const SizedBox(height: 16),
//
//           // Current alert display
//           if (replayProvider.replayAlert != null)
//             Container(
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: _getAlertColor(replayProvider.replayAlert!.type)
//                     .withValues(alpha: 0.1),
//                 border: Border.all(
//                   color: _getAlertColor(replayProvider.replayAlert!.type),
//                 ),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Row(
//                 children: [
//                   Icon(
//                     _getAlertIcon(replayProvider.replayAlert!.type),
//                     color: _getAlertColor(replayProvider.replayAlert!.type),
//                   ),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: Text(
//                       replayProvider.replayAlert!.message,
//                       style: TextStyle(
//                         color: _getAlertColor(replayProvider.replayAlert!.type),
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildMetricsPanel(ReplayProvider replayProvider) {
//     final metrics = replayProvider.replayMetrics;
//
//     return Container(
//       height: 120,
//       padding: const EdgeInsets.all(16),
//       child: Row(
//         children: [
//           Expanded(
//             child: _buildMetricCard(
//               'Rate',
//               metrics.compressionRate != null
//                   ? '${metrics.compressionRate!.toStringAsFixed(0)} /min'
//                   : '--',
//               Icons.speed,
//               Colors.blue,
//             ),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: _buildMetricCard(
//               'Count',
//               '${metrics.compressionCount}',
//               Icons.compress,
//               Colors.red,
//             ),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: _buildMetricCard(
//               'CCF',
//               metrics.ccf != null
//                   ? '${(metrics.ccf! * 100).toStringAsFixed(0)}%'
//                   : '--',
//               Icons.timeline,
//               Colors.green,
//             ),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: _buildMetricCard(
//               'Cycle',
//               '${metrics.cycleNumber}',
//               Icons.plus_one,
//               Colors.orange,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildMetricCard(
//       String title, String value, IconData icon, Color color) {
//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: color.withValues(alpha: 0.1),
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: color.withValues(alpha: 0.3)),
//       ),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(icon, color: color, size: 20),
//           const SizedBox(height: 4),
//           Text(
//             value,
//             style: TextStyle(
//               color: color,
//               fontWeight: FontWeight.bold,
//               fontSize: 16,
//             ),
//           ),
//           const SizedBox(height: 2),
//           Text(
//             title,
//             style: TextStyle(
//               color: color,
//               fontSize: 12,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildTimelinePanel(ReplayProvider replayProvider) {
//     return Container(
//       height: 80,
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 'Timeline',
//                 style: Theme.of(context).textTheme.titleSmall?.copyWith(
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               Text(
//                 '${replayProvider.formattedCurrentPosition} / ${replayProvider.formattedTotalDuration}',
//                 style: const TextStyle(fontFamily: 'monospace'),
//               ),
//             ],
//           ),
//           const SizedBox(height: 8),
//           Expanded(
//             child: Stack(
//               children: [
//                 // Timeline slider
//                 Positioned.fill(
//                   child: SliderTheme(
//                     data: SliderTheme.of(context).copyWith(
//                       trackHeight: 4,
//                       thumbShape:
//                       const RoundSliderThumbShape(enabledThumbRadius: 8),
//                       overlayShape:
//                       const RoundSliderOverlayShape(overlayRadius: 16),
//                     ),
//                     child: Slider(
//                       value: replayProvider.playbackProgress,
//                       onChanged: replayProvider.canSeek
//                           ? (value) {
//                         final position = Duration(
//                           milliseconds: (replayProvider
//                               .totalDuration.inMilliseconds *
//                               value)
//                               .round(),
//                         );
//                         replayProvider.seekTo(position);
//                       }
//                           : null,
//                     ),
//                   ),
//                 ),
//                 // Timeline markers
//                 Positioned.fill(
//                   child: CustomPaint(
//                     painter: _TimelineMarkerPainter(
//                       markers: replayProvider.timelineMarkers,
//                       totalDuration: replayProvider.totalDuration,
//                       currentPosition: replayProvider.currentPosition,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildGraphPanel(ReplayProvider replayProvider) {
//     final sessionStart = replayProvider.selectedSession!.startedAt;
//
//     return Container(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Sensor Data',
//             style: Theme.of(context).textTheme.titleSmall?.copyWith(
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Expanded(
//             child: replayProvider.replaySensor1Data.isEmpty
//                 ? Center(
//               child: Text(
//                 'No sensor data available',
//                 style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                   color: Theme.of(context)
//                       .colorScheme
//                       .onSurface
//                       .withValues(alpha: 0.5),
//                 ),
//               ),
//             )
//                 : LineChart(
//               LineChartData(
//                 gridData: const FlGridData(show: true),
//                 titlesData: FlTitlesData(
//                   leftTitles: AxisTitles(
//                     sideTitles: SideTitles(
//                       showTitles: true,
//                       reservedSize: 40,
//                       getTitlesWidget: (value, meta) {
//                         return Text(
//                           value.toStringAsFixed(0),
//                           style: const TextStyle(fontSize: 10),
//                         );
//                       },
//                     ),
//                   ),
//                   bottomTitles: AxisTitles(
//                     sideTitles: SideTitles(
//                       showTitles: true,
//                       reservedSize: 30,
//                       getTitlesWidget: (value, meta) {
//                         final duration = Duration(seconds: value.toInt());
//                         return Text(
//                           '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}',
//                           style: const TextStyle(fontSize: 10),
//                         );
//                       },
//                     ),
//                   ),
//                   topTitles: const AxisTitles(
//                     sideTitles: SideTitles(showTitles: false),
//                   ),
//                   rightTitles: const AxisTitles(
//                     sideTitles: SideTitles(showTitles: false),
//                   ),
//                 ),
//                 borderData: FlBorderData(
//                   show: true,
//                   border: Border.all(
//                     color: Theme.of(context)
//                         .colorScheme
//                         .outline
//                         .withValues(alpha: 0.3),
//                   ),
//                 ),
//                 lineBarsData: [
//                   // Sensor 1 line
//                   LineChartBarData(
//                     spots: replayProvider.replaySensor1Data
//                         .map((point) => FlSpot(
//                       point.timestamp
//                           .difference(sessionStart)
//                           .inSeconds
//                           .toDouble(),
//                       point.value,
//                     ))
//                         .toList(),
//                     color: Colors.blue,
//                     barWidth: 2,
//                     dotData: const FlDotData(show: false),
//                     belowBarData: BarAreaData(
//                       show: true,
//                       color: Colors.blue.withValues(alpha: 0.1),
//                     ),
//                   ),
//                   // Sensor 2 line
//                   LineChartBarData(
//                     spots: replayProvider.replaySensor2Data
//                         .map((point) => FlSpot(
//                       point.timestamp
//                           .difference(sessionStart)
//                           .inSeconds
//                           .toDouble(),
//                       point.value,
//                     ))
//                         .toList(),
//                     color: Colors.red,
//                     barWidth: 2,
//                     dotData: const FlDotData(show: false),
//                     belowBarData: BarAreaData(
//                       show: true,
//                       color: Colors.red.withValues(alpha: 0.1),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildControlsPanel(ReplayProvider replayProvider) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Theme.of(context).colorScheme.surfaceContainerHigh,
//         border: Border(
//           top: BorderSide(
//             color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
//           ),
//         ),
//       ),
//       child: Column(
//         children: [
//           // Main controls
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               // Step backward
//               IconButton(
//                 onPressed:
//                 replayProvider.canSeek ? replayProvider.stepBackward : null,
//                 icon: const Icon(Icons.skip_previous),
//                 tooltip: 'Step Back',
//               ),
//
//               const SizedBox(width: 8),
//
//               // Play/Pause
//               IconButton(
//                 onPressed: replayProvider.canPlay
//                     ? replayProvider.togglePlayPause
//                     : null,
//                 icon: Icon(
//                     replayProvider.isPlaying ? Icons.pause : Icons.play_arrow),
//                 iconSize: 32,
//                 tooltip: replayProvider.isPlaying ? 'Pause' : 'Play',
//               ),
//
//               const SizedBox(width: 8),
//
//               // Step forward
//               IconButton(
//                 onPressed:
//                 replayProvider.canSeek ? replayProvider.stepForward : null,
//                 icon: const Icon(Icons.skip_next),
//                 tooltip: 'Step Forward',
//               ),
//             ],
//           ),
//
//           const SizedBox(height: 16),
//
//           // Secondary controls
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             children: [
//               // Speed control
//               PopupMenuButton<double>(
//                 onSelected: replayProvider.setPlaybackSpeed,
//                 itemBuilder: (context) => [
//                   const PopupMenuItem(value: 0.25, child: Text('0.25x')),
//                   const PopupMenuItem(value: 0.5, child: Text('0.5x')),
//                   const PopupMenuItem(value: 1.0, child: Text('1x')),
//                   const PopupMenuItem(value: 1.5, child: Text('1.5x')),
//                   const PopupMenuItem(value: 2.0, child: Text('2x')),
//                   const PopupMenuItem(value: 4.0, child: Text('4x')),
//                 ],
//                 child: Chip(
//                   label: Text('${replayProvider.playbackSpeed}x'),
//                   avatar: const Icon(Icons.speed),
//                 ),
//               ),
//
//               // Jump to markers
//               OutlinedButton.icon(
//                 onPressed: replayProvider.canSeek &&
//                     replayProvider.timelineMarkers.isNotEmpty
//                     ? replayProvider.jumpToPreviousMarker
//                     : null,
//                 icon: const Icon(Icons.skip_previous),
//                 label: const Text('Prev'),
//               ),
//
//               OutlinedButton.icon(
//                 onPressed: replayProvider.canSeek &&
//                     replayProvider.timelineMarkers.isNotEmpty
//                     ? replayProvider.jumpToNextMarker
//                     : null,
//                 icon: const Icon(Icons.skip_next),
//                 label: const Text('Next'),
//               ),
//
//               // Reset
//               OutlinedButton.icon(
//                 onPressed: replayProvider.canSeek
//                     ? replayProvider.resetToBeginning
//                     : null,
//                 icon: const Icon(Icons.replay),
//                 label: const Text('Reset'),
//               ),
//
//               // Export replay data
//               OutlinedButton.icon(
//                 onPressed: () => _showExportDialog(replayProvider),
//                 icon: const Icon(Icons.download),
//                 label: const Text('Export'),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   Color _getPhaseColor(CPRPhase phase) {
//     switch (phase) {
//       case CPRPhase.compression:
//         return Colors.red;
//       case CPRPhase.recoil:
//         return Colors.blue;
//       case CPRPhase.quietude:
//         return Colors.green;
//       case CPRPhase.pause:
//         return Colors.orange;
//     }
//   }
//
//   IconData _getPhaseIcon(CPRPhase phase) {
//     switch (phase) {
//       case CPRPhase.compression:
//         return Icons.compress;
//       case CPRPhase.recoil:
//         return Icons.expand;
//       case CPRPhase.quietude:
//         return Icons.pause_circle;
//       case CPRPhase.pause:
//         return Icons.stop_circle;
//     }
//   }
//
//   Color _getAlertColor(AlertType type) {
//     switch (type) {
//       case AlertType.goFaster:
//       case AlertType.slowDown:
//         return Colors.orange;
//       case AlertType.beGentle:
//       case AlertType.releaseMore:
//         return Colors.red;
//     }
//   }
//
//   IconData _getAlertIcon(AlertType type) {
//     switch (type) {
//       case AlertType.goFaster:
//         return Icons.fast_forward;
//       case AlertType.slowDown:
//         return Icons.slow_motion_video;
//       case AlertType.beGentle:
//         return Icons.touch_app;
//       case AlertType.releaseMore:
//         return Icons.expand;
//     }
//   }
//
//   String _formatDuration(Duration duration) {
//     final minutes = duration.inMinutes;
//     final seconds = duration.inSeconds.remainder(60);
//     return '${minutes}m ${seconds}s';
//   }
//
//   void _showExportDialog(ReplayProvider replayProvider) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Export Replay Data'),
//         content: const Text(
//           'Export current replay session data including metrics, timing, and sensor readings?',
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               Navigator.pop(context);
//               _exportReplayData(replayProvider);
//             },
//             child: const Text('Export'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Future<void> _exportReplayData(ReplayProvider replayProvider) async {
//     if (!mounted) return;
//
//     try {
//       // Show loading
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Exporting replay data...'),
//           duration: Duration(seconds: 2),
//         ),
//       );
//
//       // TODO: Implement actual export functionality
//       // This would typically involve:
//       // 1. Collecting all replay data
//       // 2. Converting to CSV/JSON format
//       // 3. Saving to device storage or sharing
//
//       await Future.delayed(const Duration(seconds: 2));
//
//       if (!mounted) return;
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Replay data exported successfully'),
//           backgroundColor: Colors.green,
//         ),
//       );
//     } catch (e) {
//       if (!mounted) return;
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Export failed: ${e.toString()}'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }
// }
//
// // Custom painter for timeline markers
// class _TimelineMarkerPainter extends CustomPainter {
//   final List<TimelineMarker> markers;
//   final Duration totalDuration;
//   final Duration currentPosition;
//
//   _TimelineMarkerPainter({
//     required this.markers,
//     required this.totalDuration,
//     required this.currentPosition,
//   });
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     if (totalDuration.inMilliseconds == 0) return;
//
//     for (final marker in markers) {
//       final position =
//           marker.position.inMilliseconds / totalDuration.inMilliseconds;
//       final x = position * size.width;
//
//       Color color;
//       switch (marker.type) {
//         case TimelineMarkerType.alert:
//           color = Colors.red;
//           break;
//         case TimelineMarkerType.cycle:
//           color = Colors.blue;
//           break;
//         case TimelineMarkerType.pause:
//           color = Colors.orange;
//           break;
//       }
//
//       final paint = Paint()
//         ..color = color
//         ..strokeWidth = 2;
//
//       // Draw marker line
//       canvas.drawLine(
//         Offset(x, 0),
//         Offset(x, size.height),
//         paint,
//       );
//
//       // Draw marker circle
//       canvas.drawCircle(
//         Offset(x, size.height / 2),
//         3,
//         paint..style = PaintingStyle.fill,
//       );
//     }
//   }
//
//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
// }



//
// //cpr_training_app/lib/screens/dashboard_screen.dart
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:fl_chart/fl_chart.dart';
// import 'dart:async';
//
// import '../providers/session_provider.dart';
// import '../providers/metrics_provider.dart';
// import '../providers/alerts_provider.dart';
// import '../providers/graph_provider.dart';
// import '../services/sensor_service.dart';
// import '../services/voice_service.dart';
// import '../services/db_service.dart';
// import '../models/models.dart';
// import '../utils/responsive_utils.dart';
// import '../widgets/responsive_widgets.dart';
//
// class DashboardScreen extends StatefulWidget {
//   const DashboardScreen({super.key});
//
//   @override
//   State<DashboardScreen> createState() => _DashboardScreenState();
// }
//
// class _DashboardScreenState extends State<DashboardScreen>
//     with TickerProviderStateMixin {
//   late AnimationController _animationController;
//
//   StreamSubscription? _sensorDataSubscription;
//   StreamSubscription? _connectionStatusSubscription;
//   Timer? _voiceListeningTimer;
//
//   String _connectionStatus = 'Not connected';
//   bool _isListeningToVoice = false;
//   String _selectedGraphSensor = 'Sensor1';
//   bool _shouldRestartListening = false;
//
//   @override
//   void initState() {
//     super.initState();
//
//     // Initialize animation
//     _animationController = AnimationController(
//       duration: const Duration(milliseconds: 600),
//       vsync: this,
//     );
//
//     _initializeSensorConnection();
//
//     // FIXED: Subscribe AlertsProvider to MetricsProvider's alert stream
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       final metricsProvider = context.read<MetricsProvider>();
//       final alertsProvider = context.read<AlertsProvider>();
//
//       // Subscribe alerts provider to metrics provider's alert stream
//       alertsProvider.listenToAlerts(metricsProvider.alertStream);
//
//       debugPrint('AlertsProvider subscribed to MetricsProvider alert stream');
//     });
//   }
//
//   //cpr_training_app/lib/screens/dashboard_screen.dart
//
// // Find the existing _initializeSensorConnection() method and modify the sensor data listener:
//
//   void _initializeSensorConnection() {
//     final sensorService = context.read<SensorService>();
//
//     // Listen to connection status
//     _connectionStatusSubscription = sensorService.connectionStatusStream.listen(
//           (status) {
//         if (mounted) {
//           setState(() {
//             _connectionStatus = status;
//           });
//         }
//       },
//     );
//
//     // Listen to sensor data
//     _sensorDataSubscription =
//         sensorService.sensorDataStream.listen((data) async {
//           if (mounted) {
//             // Update graph provider
//             context.read<GraphProvider>().addDataPoint(data);
//
//             // Process data through metrics provider
//             context.read<MetricsProvider>().processSensorData(data);
//
//             // ADD THIS BLOCK TO SAVE TO DATABASE DURING ACTIVE SESSIONS:
//             final sessionProvider = context.read<SessionProvider>();
//             if (sessionProvider.isSessionActive &&
//                 sessionProvider.currentSession != null) {
//               try {
//                 final sample = SensorSample(
//                   id: 0,
//                   sessionId: sessionProvider.currentSession!.id,
//                   timestamp: data.timestamp,
//                   sensor1Raw: data.sensor1Raw,
//                   sensor2Raw: data.sensor2Raw,
//                   sensor1Avg: data.sensor1Raw.toDouble(),
//                   sensor2Avg: data.sensor2Raw.toDouble(),
//                 );
//                 await DBService.instance.insertSample(sample);
//               } catch (e) {
//                 debugPrint('Error saving sensor sample: $e');
//               }
//             }
//           }
//         });
//   }
//
//   // Replace your existing _toggleSession method in dashboard_screen.dart with this:
//
//   Future<void> _toggleSession() async {
//     final sessionProvider = context.read<SessionProvider>();
//     final sensorService = context.read<SensorService>();
//     final metricsProvider = context.read<MetricsProvider>();
//     final alertsProvider = context.read<AlertsProvider>();
//     final graphProvider = context.read<GraphProvider>();
//
//     try {
//       if (sessionProvider.isSessionActive) {
//         // End session
//         await sessionProvider.endSession();
//
//         // IMPORTANT: Stop CCF tracking when session ends
//         metricsProvider.setSessionState(false);
//         _animationController.stop();
//
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text('Session ended successfully'),
//               backgroundColor: Colors.green,
//             ),
//           );
//
//           // Navigate to debrief
//           Navigator.pushNamed(context, '/debrief');
//         }
//       } else {
//         // Check if sensor is connected
//         if (!sensorService.isConnected) {
//           if (mounted) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(
//                 content: Text('Please connect to ESP32 first'),
//                 backgroundColor: Colors.orange,
//               ),
//             );
//           }
//           return;
//         }
//
//         // Start session
//         final startedSession = await sessionProvider.startSession();
//
//         // IMPORTANT: Reset metrics and alerts BEFORE starting CCF tracking
//         metricsProvider.reset();
//         alertsProvider.clearAlerts();
//         graphProvider.clearData();
//
//         // CRITICAL FIX: Start CCF tracking when session begins
//         metricsProvider.setSessionState(true,
//             sessionStartTime: startedSession.startedAt);
//
//         _animationController.repeat();
//
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text('Session started successfully'),
//               backgroundColor: Colors.green,
//             ),
//           );
//         }
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error: ${e.toString()}'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }
//
//   Future<void> _connectToSensor() async {
//     final sensorService = context.read<SensorService>();
//
//     try {
//       if (sensorService.isConnected) {
//         await sensorService.disconnect();
//       } else {
//         await _showDeviceSelectionDialog();
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Connection error: ${e.toString()}'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }
//
//   Future<void> _showDeviceSelectionDialog() async {
//     final sensorService = context.read<SensorService>();
//
//     await showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return StatefulBuilder(
//           builder: (context, setDialogState) {
//             return AlertDialog(
//               title: const Text('Select CPR Device'),
//               content: SizedBox(
//                 width: double.maxFinite,
//                 height: 300,
//                 child: Column(
//                   children: [
//                     ElevatedButton(
//                       onPressed: sensorService.isScanning
//                           ? null
//                           : () async {
//                         setDialogState(() {});
//                         await sensorService.startScan();
//                         setDialogState(() {});
//                       },
//                       child: Text(
//                         sensorService.isScanning
//                             ? 'Scanning...'
//                             : 'Scan for Devices',
//                       ),
//                     ),
//                     const SizedBox(height: 10),
//                     Expanded(
//                       child: sensorService.availableDevices.isEmpty
//                           ? const Center(
//                         child: Text(
//                           'No CPR devices found.\nMake sure your ESP32 is powered on.',
//                           textAlign: TextAlign.center,
//                         ),
//                       )
//                           : ListView.builder(
//                         itemCount: sensorService.availableDevices.length,
//                         itemBuilder: (context, index) {
//                           final device =
//                           sensorService.availableDevices[index];
//                           return ListTile(
//                             title: Text(
//                               device.platformName.isNotEmpty
//                                   ? device.platformName
//                                   : 'Unknown Device',
//                             ),
//                             subtitle: Text(device.remoteId.toString()),
//                             leading: const Icon(Icons.bluetooth),
//                             onTap: () {
//                               Navigator.of(context).pop();
//                               sensorService.connectToDevice(device);
//                             },
//                           );
//                         },
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.of(context).pop(),
//                   child: const Text('Cancel'),
//                 ),
//               ],
//             );
//           },
//         );
//       },
//     );
//   }
//
//   void _toggleVoiceListening() {
//     final voiceService = context.read<VoiceService>();
//
//     if (_isListeningToVoice) {
//       // Stop continuous listening
//       _shouldRestartListening = false;
//       _voiceListeningTimer?.cancel();
//       voiceService.stopListening();
//       setState(() {
//         _isListeningToVoice = false;
//       });
//       debugPrint('Voice listening stopped manually');
//     } else {
//       // Start continuous listening
//       _shouldRestartListening = true;
//       _startContinuousListening();
//       setState(() {
//         _isListeningToVoice = true;
//       });
//       debugPrint('Voice listening started');
//     }
//   }
//
//   void _startContinuousListening() {
//     if (!_shouldRestartListening || !mounted) return;
//
//     final voiceService = context.read<VoiceService>();
//
//     voiceService.startListening(
//       onResult: (command) {
//         debugPrint('Voice command received: $command');
//
//         // Process the command
//         if (command.toLowerCase().contains('drish start cpr')) {
//           _toggleSession();
//         } else if (command.toLowerCase().contains('drish stop cpr')) {
//           _toggleSession();
//         }
//
//         // Automatically restart listening after a short delay
//         if (_shouldRestartListening && mounted) {
//           _voiceListeningTimer = Timer(const Duration(milliseconds: 500), () {
//             if (_shouldRestartListening && mounted) {
//               _startContinuousListening();
//             }
//           });
//         }
//       },
//       onError: (error) {
//         debugPrint('Voice recognition error: $error');
//
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text('Voice recognition error: $error')),
//           );
//         }
//
//         // Restart listening after error if still supposed to be listening
//         if (_shouldRestartListening && mounted) {
//           _voiceListeningTimer = Timer(const Duration(seconds: 2), () {
//             if (_shouldRestartListening && mounted) {
//               _startContinuousListening();
//             }
//           });
//         }
//       },
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: ResponsiveUtils.getScreenPadding(context),
//           child: ResponsiveLayout(
//             mobile: _buildMobileLayout(),
//             tablet: _buildTabletLayout(),
//             desktop: _buildDesktopLayout(),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildMobileLayout() {
//     final isLandscape = ResponsiveUtils.isLandscape(context);
//
//     if (isLandscape) {
//       return Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Left column: Animation and Metrics
//           Expanded(
//             flex: 2,
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 _buildConnectionSection(),
//                 SizedBox(height: ResponsiveUtils.getSpacing(context)),
//                 SizedBox(
//                   height: ResponsiveUtils.getAnimationPanelHeight(context),
//                   child: _buildAnimationPanel(),
//                 ),
//                 SizedBox(height: ResponsiveUtils.getSpacing(context)),
//                 _buildAlertsPanel(),
//               ],
//             ),
//           ),
//           SizedBox(width: ResponsiveUtils.getSpacing(context)),
//           // Right column: Metrics and Graph
//           Expanded(
//             flex: 3,
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 SizedBox(
//                   height: 400,
//                   child: _buildMetricsPanel(),
//                 ),
//                 SizedBox(height: ResponsiveUtils.getSpacing(context)),
//                 SizedBox(
//                   height: ResponsiveUtils.getChartHeight(context),
//                   child: _buildGraphPanel(),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       );
//     }
//
//     // Portrait mobile layout
//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         _buildConnectionSection(),
//         SizedBox(height: ResponsiveUtils.getSpacing(context)),
//         SizedBox(
//           height: ResponsiveUtils.getAnimationPanelHeight(context),
//           child: _buildAnimationPanel(),
//         ),
//         SizedBox(height: ResponsiveUtils.getSpacing(context)),
//         _buildAlertsPanel(),
//         SizedBox(height: ResponsiveUtils.getSpacing(context)),
//         SizedBox(
//           height: 400,
//           child: _buildMetricsPanel(),
//         ),
//         SizedBox(height: ResponsiveUtils.getSpacing(context)),
//         SizedBox(
//           height: ResponsiveUtils.getChartHeight(context),
//           child: _buildGraphPanel(),
//         ),
//         SizedBox(height: ResponsiveUtils.getSpacing(context)), // Bottom padding
//       ],
//     );
//   }
//
//   Widget _buildTabletLayout() {
//     final isLandscape = ResponsiveUtils.isLandscape(context);
//
//     if (isLandscape) {
//       return Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Left column: Animation and Alerts
//           Expanded(
//             flex: 2,
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 _buildConnectionSection(),
//                 SizedBox(height: ResponsiveUtils.getSpacing(context)),
//                 SizedBox(
//                   height: ResponsiveUtils.getAnimationPanelHeight(context),
//                   child: _buildAnimationPanel(),
//                 ),
//                 SizedBox(height: ResponsiveUtils.getSpacing(context)),
//                 _buildAlertsPanel(),
//               ],
//             ),
//           ),
//           SizedBox(width: ResponsiveUtils.getSpacing(context)),
//           // Right column: Metrics and Graph
//           Expanded(
//             flex: 3,
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 SizedBox(
//                   height: 400,
//                   child: _buildMetricsPanel(),
//                 ),
//                 SizedBox(height: ResponsiveUtils.getSpacing(context)),
//                 SizedBox(
//                   height: ResponsiveUtils.getChartHeight(context),
//                   child: _buildGraphPanel(),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       );
//     }
//
//     // Portrait tablet layout
//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         _buildConnectionSection(),
//         SizedBox(height: ResponsiveUtils.getSpacing(context)),
//         Row(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Expanded(
//               flex: 2,
//               child: SizedBox(
//                 height: ResponsiveUtils.getAnimationPanelHeight(context),
//                 child: _buildAnimationPanel(),
//               ),
//             ),
//             SizedBox(width: ResponsiveUtils.getSpacing(context)),
//             Expanded(
//               flex: 3,
//               child: SizedBox(
//                 height: ResponsiveUtils.getAnimationPanelHeight(context),
//                 child: _buildMetricsPanel(),
//               ),
//             ),
//           ],
//         ),
//         SizedBox(height: ResponsiveUtils.getSpacing(context)),
//         _buildAlertsPanel(),
//         SizedBox(height: ResponsiveUtils.getSpacing(context)),
//         SizedBox(
//           height: ResponsiveUtils.getChartHeight(context),
//           child: _buildGraphPanel(),
//         ),
//         SizedBox(height: ResponsiveUtils.getSpacing(context)), // Bottom padding
//       ],
//     );
//   }
//
//   Widget _buildDesktopLayout() {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // Left column: Animation and Alerts
//         Expanded(
//           flex: 2,
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               _buildConnectionSection(),
//               SizedBox(height: ResponsiveUtils.getSpacing(context)),
//               SizedBox(
//                 height: ResponsiveUtils.getAnimationPanelHeight(context),
//                 child: _buildAnimationPanel(),
//               ),
//               SizedBox(height: ResponsiveUtils.getSpacing(context)),
//               SizedBox(
//                 height: ResponsiveUtils.getAlertPanelHeight(context),
//                 child: _buildAlertsPanel(),
//               ),
//             ],
//           ),
//         ),
//         SizedBox(width: ResponsiveUtils.getSpacing(context)),
//         // Middle column: Metrics
//         Expanded(
//           flex: 3,
//           child: SizedBox(
//             height: MediaQuery.of(context).size.height - 100,
//             child: _buildMetricsPanel(),
//           ),
//         ),
//         SizedBox(width: ResponsiveUtils.getSpacing(context)),
//         // Right column: Graph
//         Expanded(
//           flex: 4,
//           child: SizedBox(
//             height: MediaQuery.of(context).size.height - 100,
//             child: _buildGraphPanel(),
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildConnectionSection() {
//     return Consumer<SensorService>(
//       builder: (context, sensorService, child) {
//         return ResponsiveCard(
//           child: Column(
//             children: [
//               // Connection Status
//               Container(
//                 width: double.infinity,
//                 padding:
//                 EdgeInsets.all(ResponsiveUtils.getSmallSpacing(context)),
//                 decoration: BoxDecoration(
//                   color: _getConnectionStatusColor().withOpacity(0.1),
//                   border: Border.all(color: _getConnectionStatusColor()),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: Text(
//                   _connectionStatus,
//                   textAlign: TextAlign.center,
//                   style: TextStyle(
//                     color: _getConnectionStatusColor(),
//                     fontWeight: FontWeight.bold,
//                     fontSize: ResponsiveUtils.getBodyFontSize(context),
//                   ),
//                 ),
//               ),
//
//               SizedBox(height: ResponsiveUtils.getSpacing(context)),
//
//               // Control Buttons Row
//               Row(
//                 children: [
//                   // Connect Button
//                   Expanded(
//                     child: ResponsiveButton(
//                       onPressed:
//                       sensorService.isConnecting ? null : _connectToSensor,
//                       icon: sensorService.isConnected
//                           ? Icons.bluetooth_connected
//                           : Icons.bluetooth,
//                       text: sensorService.isConnected
//                           ? 'Disconnect'
//                           : (sensorService.isConnecting
//                           ? 'Connecting...'
//                           : 'Connect ESP32'),
//                       backgroundColor:
//                       sensorService.isConnected ? Colors.red : Colors.blue,
//                       textColor: Colors.white,
//                     ),
//                   ),
//
//                   SizedBox(width: ResponsiveUtils.getSmallSpacing(context)),
//
//                   // Session Button
//                   Expanded(
//                     child: Consumer<SessionProvider>(
//                       builder: (context, sessionProvider, child) {
//                         return ResponsiveButton(
//                           onPressed: _toggleSession,
//                           icon: sessionProvider.isSessionActive
//                               ? Icons.stop
//                               : Icons.play_arrow,
//                           text: sessionProvider.isSessionActive
//                               ? 'End Session'
//                               : 'Start Session',
//                           backgroundColor: sessionProvider.isSessionActive
//                               ? Colors.red
//                               : Colors.green,
//                           textColor: Colors.white,
//                         );
//                       },
//                     ),
//                   ),
//
//                   SizedBox(width: ResponsiveUtils.getSmallSpacing(context)),
//
//                   // Voice Button
//                   SizedBox(
//                     width: ResponsiveUtils.getButtonSize(context).height,
//                     height: ResponsiveUtils.getButtonSize(context).height,
//                     child: IconButton(
//                       onPressed: _toggleVoiceListening,
//                       icon: Icon(
//                         _isListeningToVoice ? Icons.mic : Icons.mic_none,
//                         color: _isListeningToVoice ? Colors.red : Colors.grey,
//                         size: ResponsiveUtils.getIconSize(context),
//                       ),
//                       style: IconButton.styleFrom(
//                         backgroundColor: _isListeningToVoice
//                             ? Colors.red.withOpacity(0.1)
//                             : null,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _buildAnimationPanel() {
//     return Consumer2<MetricsProvider, SessionProvider>(
//       builder: (context, metricsProvider, sessionProvider, child) {
//         final isCompressing =
//             metricsProvider.currentPhase == CPRPhase.compression;
//
//         return ResponsiveCard(
//           color: Colors.black, // Make the card background black
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Title
//               Padding(
//                 padding:
//                 EdgeInsets.all(ResponsiveUtils.getSmallSpacing(context)),
//                 child: ResponsiveText.title(
//                   'CPR Visual',
//                   style: const TextStyle(
//                     fontWeight: FontWeight.bold,
//                     color: Colors.white, // White title text on black background
//                   ),
//                 ),
//               ),
//               // Image container
//               Expanded(
//                 child: Container(
//                   width: double.infinity,
//                   height: double.infinity,
//                   color: Colors.black, // Black background
//                   child: Center(
//                     child: Transform.scale(
//                       scale: 1.3, // Reduced scale to fit within card
//                       child: Image.asset(
//                         isCompressing
//                             ? 'assets/images/B4.png' // Compression image
//                             : 'assets/images/A4.png', // No compression image
//                         fit: BoxFit.contain,
//                         errorBuilder: (context, error, stackTrace) {
//                           // Fallback to text if images not found
//                           return Container(
//                             color: Colors.black,
//                             child: Center(
//                               child: Text(
//                                 isCompressing
//                                     ? 'COMPRESSION'
//                                     : 'NO COMPRESSION',
//                                 style: TextStyle(
//                                   fontSize:
//                                   ResponsiveUtils.getBodyFontSize(context),
//                                   fontWeight: FontWeight.bold,
//                                   color: Colors
//                                       .white, // White text on black background
//                                 ),
//                               ),
//                             ),
//                           );
//                         },
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _buildMetricsPanel() {
//     return Consumer2<MetricsProvider, SessionProvider>(
//       builder: (context, metricsProvider, sessionProvider, child) {
//         return ResponsiveCard(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               ResponsiveText.title(
//                 'Session Metrics',
//                 style: const TextStyle(fontWeight: FontWeight.bold),
//               ),
//               SizedBox(height: ResponsiveUtils.getSpacing(context)),
//               Expanded(
//                 child: ResponsiveGrid(
//                   children: [
//                     _buildMetricCard(
//                       'Compression Rate',
//                       metricsProvider.compressionRate?.toStringAsFixed(0) ??
//                           '--',
//                       'BPM',
//                       Icons.speed,
//                       Colors.blue,
//                     ),
//                     _buildMetricCard(
//                       'Compressions',
//                       '${metricsProvider.compressionCount}',
//                       'total',
//                       Icons.compress,
//                       Colors.blue,
//                     ),
//                     _buildMetricCard(
//                       'Good Compressions',
//                       '${metricsProvider.goodCompressions}',
//                       'count',
//                       Icons.check_circle,
//                       Colors.green,
//                     ),
//                     _buildMetricCard(
//                       'Good Recoils',
//                       '${metricsProvider.goodRecoils}',
//                       'count',
//                       Icons.expand,
//                       Colors.green,
//                     ),
//                     _buildMetricCard(
//                       'Cycle Number',
//                       '${metricsProvider.cycleNumber}',
//                       'cycles',
//                       Icons.repeat,
//                       Colors.purple,
//                     ),
//                     _buildMetricCard(
//                       'CCF',
//                       metricsProvider.ccf?.toStringAsFixed(2) ?? '--',
//                       'ratio',
//                       Icons.timeline,
//                       Colors.orange,
//                     ),
//                     _buildMetricCard(
//                       'Session #',
//                       '${sessionProvider.nextSessionNumber - (sessionProvider.isSessionActive ? 1 : 0)}',
//                       'current',
//                       Icons.numbers,
//                       Colors.grey,
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _buildMetricCard(
//       String title,
//       String value,
//       String unit,
//       IconData icon,
//       Color color,
//       ) {
//     return ResponsiveCard(
//       padding: EdgeInsets.all(ResponsiveUtils.getSmallSpacing(context)),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(
//                 icon,
//                 color: color,
//                 size: ResponsiveUtils.getIconSize(context),
//               ),
//               SizedBox(width: ResponsiveUtils.getSmallSpacing(context)),
//               Flexible(
//                 child: ResponsiveText.body(
//                   title,
//                   textAlign: TextAlign.center,
//                   maxLines: 2,
//                   style: TextStyle(
//                     fontSize: ResponsiveUtils.getSmallFontSize(context),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           SizedBox(height: ResponsiveUtils.getSmallSpacing(context)),
//           ResponsiveText.title(
//             value,
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               fontWeight: FontWeight.bold,
//               color: color,
//             ),
//           ),
//           ResponsiveText.small(
//             unit,
//             textAlign: TextAlign.center,
//             style: const TextStyle(color: Colors.grey),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildAlertsPanel() {
//     return Consumer<AlertsProvider>(
//       builder: (context, alertsProvider, child) {
//         final alerts = alertsProvider.alertHistory;
//
//         return ResponsiveCard(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               ResponsiveText.title(
//                 'Alerts & Feedback',
//                 style: const TextStyle(fontWeight: FontWeight.bold),
//               ),
//               SizedBox(height: ResponsiveUtils.getSpacing(context)),
//               if (alerts.isEmpty)
//                 Container(
//                   padding: EdgeInsets.all(ResponsiveUtils.getSpacing(context)),
//                   child: ResponsiveText.body(
//                     'No alerts at this time',
//                     textAlign: TextAlign.center,
//                     style: const TextStyle(color: Colors.grey),
//                   ),
//                 )
//               else
//                 ...alerts
//                     .take(5) // Show only last 5 alerts
//                     .map((alert) => Container(
//                   margin: EdgeInsets.only(
//                       bottom: ResponsiveUtils.getSmallSpacing(context)),
//                   padding: EdgeInsets.all(
//                       ResponsiveUtils.getSmallSpacing(context)),
//                   decoration: BoxDecoration(
//                     color: _getAlertColor(alert.type).withOpacity(0.1),
//                     border:
//                     Border.all(color: _getAlertColor(alert.type)),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Row(
//                     children: [
//                       Icon(
//                         _getAlertIcon(alert.type),
//                         color: _getAlertColor(alert.type),
//                         size: ResponsiveUtils.getIconSize(context),
//                       ),
//                       SizedBox(
//                           width:
//                           ResponsiveUtils.getSmallSpacing(context)),
//                       Expanded(
//                         child: ResponsiveText.body(
//                           alert.message,
//                           style: TextStyle(
//                             color: _getAlertColor(alert.type),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 )),
//             ],
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _buildGraphPanel() {
//     return Consumer<GraphProvider>(
//       builder: (context, graphProvider, child) {
//         // Calculate spots with time-based x-axis
//         List<FlSpot> spots = [];
//         if (graphProvider.sensor1Data.isNotEmpty) {
//           final firstTimestamp = graphProvider.sensor1Data.first.timestamp;
//           spots = graphProvider.sensor1Data.map((dataPoint) {
//             final timeDiff =
//                 dataPoint.timestamp.difference(firstTimestamp).inMilliseconds /
//                     1000.0;
//             return FlSpot(timeDiff, dataPoint.value);
//           }).toList();
//         }
//
//         return ResponsiveCard(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               ResponsiveText.title(
//                 'Sensor Data',
//                 style: const TextStyle(fontWeight: FontWeight.bold),
//               ),
//               SizedBox(height: ResponsiveUtils.getSpacing(context)),
//               // Sensor selector
//               Container(
//                 padding: EdgeInsets.symmetric(
//                     horizontal: ResponsiveUtils.getSmallSpacing(context)),
//                 decoration: BoxDecoration(
//                   border: Border.all(color: Colors.grey),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: DropdownButton<String>(
//                   value: _selectedGraphSensor,
//                   isExpanded: true,
//                   underline: const SizedBox(),
//                   items: ['Sensor1', 'Sensor2', 'Sensor3']
//                       .map<DropdownMenuItem<String>>((String value) {
//                     return DropdownMenuItem<String>(
//                       value: value,
//                       child: ResponsiveText.body(value),
//                     );
//                   }).toList(),
//                   onChanged: (String? newValue) {
//                     if (newValue != null) {
//                       setState(() {
//                         _selectedGraphSensor = newValue;
//                       });
//                     }
//                   },
//                 ),
//               ),
//               SizedBox(height: ResponsiveUtils.getSpacing(context)),
//               // Graph
//               Expanded(
//                 child: Container(
//                   decoration: BoxDecoration(
//                     border: Border.all(color: Colors.grey.shade300),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Padding(
//                     padding: EdgeInsets.all(
//                         ResponsiveUtils.getSmallSpacing(context)),
//                     child: LineChart(
//                       LineChartData(
//                         minX: 0,
//                         maxX: graphProvider.timeSpanSeconds,
//                         minY: 0,
//                         maxY: 1024,
//                         lineBarsData: [
//                           LineChartBarData(
//                             spots: spots,
//                             isCurved: true,
//                             color: Colors.blue,
//                             barWidth: 2,
//                             isStrokeCapRound: true,
//                             belowBarData: BarAreaData(show: false),
//                             dotData: const FlDotData(show: false),
//                           ),
//                         ],
//                         titlesData: FlTitlesData(
//                           show: true,
//                           rightTitles: const AxisTitles(
//                             sideTitles: SideTitles(showTitles: false),
//                           ),
//                           topTitles: const AxisTitles(
//                             sideTitles: SideTitles(showTitles: false),
//                           ),
//                           bottomTitles: AxisTitles(
//                             sideTitles: SideTitles(
//                               showTitles: true,
//                               reservedSize: 20,
//                               interval: 5, // Show label every 5 seconds
//                               getTitlesWidget: (value, meta) {
//                                 return Text(
//                                   '${value.toInt()}s',
//                                   style: TextStyle(
//                                     fontSize: ResponsiveUtils.getSmallFontSize(
//                                         context),
//                                   ),
//                                 );
//                               },
//                             ),
//                           ),
//                           leftTitles: AxisTitles(
//                             sideTitles: SideTitles(
//                               showTitles: true,
//                               reservedSize: 30,
//                               interval: 256,
//                               getTitlesWidget: (value, meta) {
//                                 return Text(
//                                   '${value.toInt()}',
//                                   style: TextStyle(
//                                     fontSize: ResponsiveUtils.getSmallFontSize(
//                                         context),
//                                   ),
//                                 );
//                               },
//                             ),
//                           ),
//                         ),
//                         gridData: const FlGridData(show: true),
//                         borderData: FlBorderData(
//                           show: true,
//                           border: Border.all(color: Colors.grey.shade300),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
//
//   Color _getConnectionStatusColor() {
//     switch (_connectionStatus) {
//       case 'Connected':
//         return Colors.green;
//       case 'Connecting...':
//         return Colors.orange;
//       case 'Not connected':
//         return Colors.red;
//     }
//     return Colors.grey;
//   }
//
//   Color _getAlertColor(AlertType type) {
//     switch (type) {
//       case AlertType.goFaster:
//         return Colors.blue;
//       case AlertType.slowDown:
//         return Colors.orange;
//       case AlertType.beGentle:
//         return Colors.red;
//       case AlertType.releaseMore:
//         return Colors.purple;
//     }
//     return Colors.grey;
//   }
//
//   IconData _getAlertIcon(AlertType type) {
//     switch (type) {
//       case AlertType.goFaster:
//         return Icons.speed;
//       case AlertType.slowDown:
//         return Icons.warning;
//       case AlertType.beGentle:
//         return Icons.error;
//       case AlertType.releaseMore:
//         return Icons.expand;
//     }
//     return Icons.info;
//   }
//
//   @override
//   void dispose() {
//     _animationController.dispose();
//     _sensorDataSubscription?.cancel();
//     _connectionStatusSubscription?.cancel();
//
//     // Stop voice listening if active
//     if (_isListeningToVoice) {
//       context.read<VoiceService>().stopListening();
//     }
//
//     super.dispose();
//   }
// }


//3rd part

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
  Timer? _voiceListeningTimer;

  String _connectionStatus = 'Not connected';
  bool _isListeningToVoice = false;
  String _selectedGraphSensor = 'Sensor1';
  bool _shouldRestartListening = false;

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

  // Rest of your existing code remains exactly the same...
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

          // Navigate to debrief
          Navigator.pushNamed(context, '/debrief');
        }
      } else {
        // Check if sensor is connected
        if (!sensorService.isConnected) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please connect to ESP32 first'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }

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

  Future<void> _connectToSensor() async {
    final sensorService = context.read<SensorService>();

    try {
      if (sensorService.isConnected) {
        await sensorService.disconnect();
      } else {
        await _showDeviceSelectionDialog();
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

  Future<void> _showDeviceSelectionDialog() async {
    final sensorService = context.read<SensorService>();

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Select CPR Device'),
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
                          'No CPR devices found.\nMake sure your ESP32 is powered on.',
                          textAlign: TextAlign.center,
                        ),
                      )
                          : ListView.builder(
                        itemCount: sensorService.availableDevices.length,
                        itemBuilder: (context, index) {
                          final device =
                          sensorService.availableDevices[index];
                          return ListTile(
                            title: Text(
                              device.platformName.isNotEmpty
                                  ? device.platformName
                                  : 'Unknown Device',
                            ),
                            subtitle: Text(device.remoteId.toString()),
                            leading: const Icon(Icons.bluetooth),
                            onTap: () {
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
          child: ResponsiveLayout(
            mobile: _buildMobileLayout(),
            tablet: _buildTabletLayout(),
            desktop: _buildDesktopLayout(),
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
    return Consumer<SensorService>(
      builder: (context, sensorService, child) {
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
                child: Text(
                  _connectionStatus,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _getConnectionStatusColor(),
                    fontWeight: FontWeight.bold,
                    fontSize: ResponsiveUtils.getBodyFontSize(context),
                  ),
                ),
              ),

              SizedBox(height: ResponsiveUtils.getSpacing(context)),

              // Control Buttons Row
              Row(
                children: [
                  // Connect Button
                  Expanded(
                    child: ResponsiveButton(
                      onPressed:
                      sensorService.isConnecting ? null : _connectToSensor,
                      icon: sensorService.isConnected
                          ? Icons.bluetooth_connected
                          : Icons.bluetooth,
                      text: sensorService.isConnected
                          ? 'Disconnect'
                          : (sensorService.isConnecting
                          ? 'Connecting...'
                          : 'Connect ESP32'),
                      backgroundColor:
                      sensorService.isConnected ? Colors.red : Colors.blue,
                      textColor: Colors.white,
                    ),
                  ),

                  SizedBox(width: ResponsiveUtils.getSmallSpacing(context)),

                  // Session Button
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
                              : Colors.green,
                          textColor: Colors.white,
                        );
                      },
                    ),
                  ),

                  SizedBox(width: ResponsiveUtils.getSmallSpacing(context)),

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
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnimationPanel() {
    return Consumer2<MetricsProvider, SessionProvider>(
      builder: (context, metricsProvider, sessionProvider, child) {
        final isCompressing =
            metricsProvider.currentPhase == CPRPhase.compression;

        return ResponsiveCard(
          color: Colors.black, // Make the card background black
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
                    color: Colors.white, // White title text on black background
                  ),
                ),
              ),
              // Image container
              Expanded(
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.black, // Black background
                  child: Center(
                    child: Transform.scale(
                      scale: 1.3, // Reduced scale to fit within card
                      child: Image.asset(
                        isCompressing
                            ? 'assets/images/B4.png' // Compression image
                            : 'assets/images/A4.png', // No compression image
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback to text if images not found
                          return Container(
                            color: Colors.black,
                            child: Center(
                              child: Text(
                                isCompressing
                                    ? 'COMPRESSION'
                                    : 'NO COMPRESSION',
                                style: TextStyle(
                                  fontSize:
                                  ResponsiveUtils.getBodyFontSize(context),
                                  fontWeight: FontWeight.bold,
                                  color: Colors
                                      .white, // White text on black background
                                ),
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

    // Stop voice listening if active
    if (_isListeningToVoice) {
      context.read<VoiceService>().stopListening();
    }

    super.dispose();
  }
}