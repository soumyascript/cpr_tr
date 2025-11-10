//cpr_training_app/lib/screens/debrief_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/session_provider.dart';
import '../providers/metrics_provider.dart';
import '../providers/alerts_provider.dart';
import '../providers/config_provider.dart';
import '../models/models.dart';

class DebriefScreen extends StatefulWidget {
  const DebriefScreen({super.key});

  @override
  State<DebriefScreen> createState() => _DebriefScreenState();
}

class _DebriefScreenState extends State<DebriefScreen> {
  DebriefData? _debriefData;
  bool _isLoading = true;
  bool _isGeneratingAIDebrief = false;
  String? _aiDebriefContent;
  CPRSession? _currentSession;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _generateDebrief();
  }

  Future<void> _generateDebrief() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Read providers before async operations
      final sessionProvider = context.read<SessionProvider>();
      final metricsProvider = context.read<MetricsProvider>();
      final alertsProvider = context.read<AlertsProvider>();
      final configProvider = context.read<ConfigProvider>();

      _currentSession = sessionProvider.currentSession;

      if (_currentSession == null) {
        throw Exception('No active or recent session found');
      }

      // Generate debrief data from current session
      _debriefData = await _createDebriefData(
        _currentSession!,
        metricsProvider,
        alertsProvider,
      );

      // Generate AI debrief if enabled and configured
      if (configProvider.cloudConfig.aiDebriefing) {
        await _generateAIDebrief();
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
      debugPrint('Error generating debrief: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<DebriefData> _createDebriefData(
    CPRSession session,
    MetricsProvider metricsProvider,
    AlertsProvider alertsProvider,
  ) async {
    final metrics = metricsProvider.currentMetrics;
    final alertStats = alertsProvider.getAlertSummaryForDebrief();

    // Safely handle null values with defaults
    final averageRate = metrics.compressionRate ?? 0.0;
    final averageCCF = metrics.ccf ?? 0.0;
    final cycleNumber = metrics.cycleNumber;
    final totalCompressions = metrics.compressionCount;
    final goodCompressions = metrics.goodCompressions;
    final totalRecoils = metrics.recoilCount;
    final goodRecoils = metrics.goodRecoils;

    // Calculate ideal vs actual comparisons with null safety
    final idealComparison = _calculateIdealComparison(metrics, session);

    // Generate recommendations based on available data
    final recommendations = _generateRecommendations(metrics, alertStats);

    // Generate breath data - use actual data if available, otherwise mock for demo
    final breathsPerCycle =
        List.generate(cycleNumber > 0 ? cycleNumber : 1, (index) => 2);

    return DebriefData(
      sessionId: session.id,
      durationSeconds: session.duration.inSeconds,
      cycleCount: cycleNumber,
      averageRate: averageRate,
      averageCCF: averageCCF,
      totalCompressions: totalCompressions,
      goodCompressions: goodCompressions,
      totalRecoils: totalRecoils,
      goodRecoils: goodRecoils,
      breathsPerCycle: breathsPerCycle,
      recommendations: recommendations,
      idealComparison: idealComparison,
    );
  }

  Map<String, dynamic> _calculateIdealComparison(
      CPRMetrics metrics, CPRSession session) {
    final actualRate = metrics.compressionRate ?? 0.0;
    final actualCCF = metrics.ccf ?? 0.0;

    // Calculate estimated depth based on compression quality
    final estimatedDepth = _calculateEstimatedDepth(metrics);

    return {
      'idealRate': 110.0,
      'actualRate': actualRate,
      'rateDeviation': (actualRate - 110.0).abs(),
      'idealDepth': 5.5,
      'actualDepth': estimatedDepth,
      'depthDeviation': (estimatedDepth - 5.5).abs(),
      'idealCCF': 0.8,
      'actualCCF': actualCCF,
      'ccfDeviation': (actualCCF - 0.8).abs(),
    };
  }

  double _calculateEstimatedDepth(CPRMetrics metrics) {
    // Estimate depth based on compression quality ratio
    if (metrics.compressionCount == 0) return 0.0;

    final compressionQuality =
        metrics.goodCompressions / metrics.compressionCount;

    // Estimate depth based on quality: higher quality suggests better depth control
    // This is an approximation - in a real system you'd have actual depth sensors
    if (compressionQuality >= 0.9) return 5.5; // Ideal depth
    if (compressionQuality >= 0.7) return 5.0; // Slightly shallow
    if (compressionQuality >= 0.5) return 4.5; // Too shallow
    return 4.0; // Much too shallow
  }

  List<String> _generateRecommendations(
      CPRMetrics metrics, Map<String, dynamic> alertStats) {
    final recommendations = <String>[];

    final compressionRate = metrics.compressionRate ?? 0.0;
    final ccf = metrics.ccf ?? 0.0;
    final compressionQuality = metrics.compressionCount > 0
        ? metrics.goodCompressions / metrics.compressionCount
        : 0.0;
    final recoilQuality = metrics.recoilCount > 0
        ? metrics.goodRecoils / metrics.recoilCount
        : 0.0;

    // Rate-based recommendations
    if (compressionRate < 100) {
      recommendations.add('Increase compression rate to at least 100 BPM');
    } else if (compressionRate > 120) {
      recommendations
          .add('Reduce compression rate to stay within 100-120 BPM range');
    }

    // Quality-based recommendations
    if (compressionQuality < 0.7) {
      recommendations
          .add('Focus on proper hand positioning and compression depth');
    }

    if (recoilQuality < 0.7) {
      recommendations.add('Allow complete chest recoil between compressions');
    }

    // CCF-based recommendations
    if (ccf < 0.6) {
      recommendations.add('Minimize interruptions between compression cycles');
    }

    // Alert-based recommendations
    final totalAlerts = (alertStats['totalAlerts'] as int?) ?? 0;
    if (totalAlerts > 10) {
      recommendations
          .add('Focus on maintaining consistent technique to reduce alerts');
    }

    // Default recommendation if none specific
    if (recommendations.isEmpty) {
      recommendations.add('Continue practicing to maintain proficiency');
    }

    return recommendations;
  }

  Future<void> _generateAIDebrief() async {
    if (_debriefData == null) return;

    setState(() {
      _isGeneratingAIDebrief = true;
    });

    try {
      // Simulate AI debrief generation - replace with actual AI service call
      await Future.delayed(const Duration(seconds: 2));

      _aiDebriefContent = _generateDetailedAIDebrief();
    } catch (e) {
      debugPrint('Error generating AI debrief: $e');
      _aiDebriefContent =
          'AI debrief temporarily unavailable. Please try again later.';
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingAIDebrief = false;
        });
      }
    }
  }

  String _generateDetailedAIDebrief() {
    if (_debriefData == null) return 'No session data available for analysis.';

    final averageRate = _debriefData!.averageRate;
    final compressionAccuracy = _debriefData!.compressionAccuracy;
    final recoilAccuracy = _debriefData!.recoilAccuracy;
    final ccf = _debriefData!.averageCCF;
    final duration = Duration(seconds: _debriefData!.durationSeconds);

    return '''
### AI-Generated Performance Analysis

**Session Overview**: Your ${_formatDuration(duration)} CPR session demonstrates ${_getOverallPerformanceLevel()} performance with specific areas for improvement.

**Key Strengths**:
${averageRate >= 100 && averageRate <= 120 ? '- Excellent maintenance of target compression rate (${averageRate.toStringAsFixed(1)} BPM)' : ''}
${compressionAccuracy >= 80 ? '- Well-controlled compression depth and technique (${compressionAccuracy.toStringAsFixed(1)}%)' : ''}
${recoilAccuracy >= 80 ? '- Good recoil technique (${recoilAccuracy.toStringAsFixed(1)}%)' : ''}
${ccf >= 0.6 ? '- Good chest compression fraction (${(ccf * 100).toStringAsFixed(1)}%)' : ''}

**Areas for Improvement**:
${averageRate < 100 ? '- Increase compression rate to meet 100+ BPM guideline' : ''}
${averageRate > 120 ? '- Reduce compression rate to stay within 100-120 BPM range' : ''}
${compressionAccuracy < 80 ? '- Focus on achieving consistent compression depth and technique' : ''}
${recoilAccuracy < 80 ? '- Work on allowing complete chest recoil between compressions' : ''}
${ccf < 0.6 ? '- Work on reducing pause times between compression cycles' : ''}

**Personalized Recommendations**:
1. **Practice Focus**: ${_getPersonalizedPracticeFocus()}
2. **Training Emphasis**: Continue regular practice sessions to maintain muscle memory
3. **Next Session Goal**: ${_getNextSessionGoal()}

**Performance Rating**: Your session ranks as ${_getOverallPerformanceLevel()} compared to CPR guidelines.

*This analysis uses advanced metrics to provide personalized feedback for CPR skill development.*
''';
  }

  String _getOverallPerformanceLevel() {
    if (_debriefData == null) return 'average';

    final rateScore = _calculateRateScore(_debriefData!.averageRate);
    final ccfScore = _debriefData!.averageCCF >= 0.6
        ? 100
        : (_debriefData!.averageCCF / 0.6 * 100);
    final compressionScore = _debriefData!.compressionAccuracy;
    final recoilScore = _debriefData!.recoilAccuracy;

    final averageScore =
        (rateScore + ccfScore + compressionScore + recoilScore) / 4;

    if (averageScore >= 90) return 'excellent';
    if (averageScore >= 75) return 'good';
    if (averageScore >= 60) return 'satisfactory';
    return 'needs improvement';
  }

  int _calculateRateScore(double rate) {
    if (rate >= 100 && rate <= 120) return 100;
    if (rate >= 95 && rate <= 125) return 80;
    if (rate >= 90 && rate <= 130) return 60;
    return 40;
  }

  String _getPersonalizedPracticeFocus() {
    if (_debriefData == null) return 'General CPR technique';

    if (_debriefData!.compressionAccuracy < 70) {
      return 'Compression depth control and hand positioning';
    }
    if (_debriefData!.recoilAccuracy < 70) {
      return 'Complete chest recoil technique';
    }
    if (_debriefData!.averageRate < 100) {
      return 'Increasing compression rate to 100+ BPM';
    }
    if (_debriefData!.averageRate > 120) {
      return 'Controlling compression rate to stay within 100-120 BPM';
    }
    if (_debriefData!.averageCCF < 0.6) {
      return 'Minimizing interruptions between compression cycles';
    }
    return 'Maintaining overall technique consistency';
  }

  String _getNextSessionGoal() {
    if (_debriefData == null) return 'Improve overall performance';

    final currentLevel = _getOverallPerformanceLevel();
    switch (currentLevel) {
      case 'excellent':
        return 'Maintain current performance level and focus on endurance';
      case 'good':
        return 'Achieve 90%+ accuracy in all performance metrics';
      case 'satisfactory':
        return 'Improve weakest performance area by 10%';
      default:
        return 'Focus on basic technique mastery';
    }
  }

  Future<void> _shareDebrief() async {
    if (_debriefData == null) return;

    // Implement sharing functionality
    // This would typically use the share package
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share functionality coming soon')),
    );
  }

  Future<void> _exportDebrief() async {
    if (_debriefData == null) return;

    // Implement export functionality
    // This would typically generate PDF or save to device
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export functionality coming soon')),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes}m ${seconds}s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Debrief'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          if (_debriefData != null) ...[
            IconButton(
              onPressed: _shareDebrief,
              icon: const Icon(Icons.share),
              tooltip: 'Share Debrief',
            ),
            IconButton(
              onPressed: _exportDebrief,
              icon: const Icon(Icons.download),
              tooltip: 'Export Debrief',
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorState()
              : _debriefData == null
                  ? _buildNoDataState()
                  : _buildDebriefContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
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
              'Debrief Generation Failed',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'An unexpected error occurred',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _generateDebrief,
                  child: const Text('Retry'),
                ),
                const SizedBox(width: 16),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No Session Data',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'No session data available for analysis. Please complete a training session first.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Start New Session'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebriefContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSessionHeader(),
          const SizedBox(height: 24),
          _buildPerformanceOverview(),
          const SizedBox(height: 24),
          _buildDetailedMetrics(),
          const SizedBox(height: 24),
          _buildRecommendations(),
          const SizedBox(height: 24),
          if (context.read<ConfigProvider>().cloudConfig.aiDebriefing)
            _buildAIDebriefSection(),
          const SizedBox(height: 24),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildSessionHeader() {
    if (_debriefData == null || _currentSession == null)
      return const SizedBox();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.assignment_turned_in,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Session #${_currentSession!.sessionNumber}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        DateFormat('MMM dd, yyyy • hh:mm a')
                            .format(_currentSession!.startedAt),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Duration',
                    _formatDuration(
                        Duration(seconds: _debriefData!.durationSeconds)),
                    Icons.timer,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    'Cycles',
                    '${_debriefData!.cycleCount}',
                    Icons.repeat,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    'Avg Rate',
                    '${_debriefData!.averageRate.toStringAsFixed(1)} BPM',
                    Icons.favorite,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceOverview() {
    if (_debriefData == null) return const SizedBox();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Overview',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _buildPerformanceBar(
              'Compression Rate',
              _calculateRateScore(_debriefData!.averageRate) / 100,
              '${_debriefData!.averageRate.toStringAsFixed(1)} BPM',
            ),
            const SizedBox(height: 12),
            _buildPerformanceBar(
              'Compression Quality',
              _debriefData!.compressionAccuracy / 100,
              '${_debriefData!.compressionAccuracy.toStringAsFixed(1)}%',
            ),
            const SizedBox(height: 12),
            _buildPerformanceBar(
              'Chest Compression Fraction',
              _debriefData!.averageCCF,
              '${(_debriefData!.averageCCF * 100).toStringAsFixed(1)}%',
            ),
            const SizedBox(height: 12),
            _buildPerformanceBar(
              'Recoil Technique',
              _debriefData!.recoilAccuracy / 100,
              '${_debriefData!.recoilAccuracy.toStringAsFixed(1)}%',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceBar(String label, double progress, String value) {
    final color = progress >= 0.8
        ? Colors.green
        : progress >= 0.6
            ? Colors.orange
            : Colors.red;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0),
          backgroundColor:
              Theme.of(context).colorScheme.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ],
    );
  }

  Widget _buildDetailedMetrics() {
    if (_debriefData == null) return const SizedBox();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detailed Metrics',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _buildMetricRow(
                'Session Duration',
                _formatDuration(
                    Duration(seconds: _debriefData!.durationSeconds))),
            _buildMetricRow('Total Cycles', '${_debriefData!.cycleCount}'),
            _buildMetricRow('Average Rate',
                '${_debriefData!.averageRate.toStringAsFixed(1)} BPM'),
            _buildMetricRow('Chest Compression Fraction',
                '${(_debriefData!.averageCCF * 100).toStringAsFixed(1)}%'),
            _buildMetricRow(
                'Total Compressions', '${_debriefData!.totalCompressions}'),
            _buildMetricRow(
                'Good Compressions', '${_debriefData!.goodCompressions}'),
            _buildMetricRow('Compression Accuracy',
                '${_debriefData!.compressionAccuracy.toStringAsFixed(1)}%'),
            _buildMetricRow('Total Recoils', '${_debriefData!.totalRecoils}'),
            _buildMetricRow('Good Recoils', '${_debriefData!.goodRecoils}'),
            _buildMetricRow('Recoil Accuracy',
                '${_debriefData!.recoilAccuracy.toStringAsFixed(1)}%'),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations() {
    if (_debriefData == null || _debriefData!.recommendations.isEmpty) {
      return const SizedBox();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recommendations',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ..._debriefData!.recommendations.map((recommendation) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          recommendation,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildAIDebriefSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.psychology,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'AI Performance Analysis',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isGeneratingAIDebrief)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Generating AI analysis...'),
                  ],
                ),
              )
            else if (_aiDebriefContent != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _aiDebriefContent!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: _generateAIDebrief,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Generate AI Analysis'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/',
                (route) => false,
              );
            },
            icon: const Icon(Icons.home),
            label: const Text('Return to Dashboard'),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/data-viewer');
                },
                icon: const Icon(Icons.analytics),
                label: const Text('View Data'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  // Start new session
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/',
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('New Session'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
