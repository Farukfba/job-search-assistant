import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class TrackerScreen extends StatefulWidget {
  const TrackerScreen({super.key});

  @override
  State<TrackerScreen> createState() => TrackerScreenState();
}

class TrackerScreenState extends State<TrackerScreen> {
  static const _stages = ['Applied', 'Interview', 'Offer', 'Rejected'];

  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _jobs = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> reload() => _load();

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final jobs = await ApiService.getSavedJobs();
      setState(() => _jobs = jobs);
    } catch (e) {
      setState(() => _error = 'Couldn\'t load your tracker — please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(Map<String, dynamic> job, String newStatus) async {
    try {
      await ApiService.updateJobStatus(job['id'], newStatus);
      setState(() => job['status'] = newStatus);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Couldn\'t update status — please try again.')),
        );
      }
    }
  }

  Color _stageColor(String stage) {
    switch (stage) {
      case 'Interview':
        return const Color(0xFF2563A8);
      case 'Offer':
        return AppColors.pine;
      case 'Rejected':
        return AppColors.danger;
      default:
        return AppColors.stone;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tracker')),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.pine,
          onRefresh: _load,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.pine))
              : _error != null
                  ? _ErrorState(message: _error!, onRetry: _load)
                  : _jobs.isEmpty
                      ? _EmptyTracker()
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          children: _stages.expand((stage) {
                            final stageJobs =
                                _jobs.where((j) => (j['status'] ?? 'Applied') == stage).toList();
                            if (stageJobs.isEmpty) return <Widget>[];
                            return [
                              _StageHeader(
                                stage: stage,
                                count: stageJobs.length,
                                color: _stageColor(stage),
                              ),
                              ...stageJobs.map((job) => _TrackerCard(
                                    job: job,
                                    stage: stage,
                                    stages: _stages,
                                    color: _stageColor(stage),
                                    onUpdateStatus: _updateStatus,
                                  )),
                              const SizedBox(height: 8),
                            ];
                          }).toList(),
                        ),
        ),
      ),
    );
  }
}

class _StageHeader extends StatelessWidget {
  final String stage;
  final int count;
  final Color color;

  const _StageHeader({required this.stage, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 10),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(
            stage,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: AppColors.ink,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$count',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
              fontSize: 13,
              color: AppColors.stone,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackerCard extends StatelessWidget {
  final Map<String, dynamic> job;
  final String stage;
  final List<String> stages;
  final Color color;
  final void Function(Map<String, dynamic> job, String newStatus) onUpdateStatus;

  const _TrackerCard({
    required this.job,
    required this.stage,
    required this.stages,
    required this.color,
    required this.onUpdateStatus,
  });

  Color _scoreColor(int score) {
    if (score >= 75) return AppColors.pine;
    if (score >= 50) return AppColors.ember;
    return AppColors.danger;
  }

  @override
  Widget build(BuildContext context) {
    final isRejected = stage == 'Rejected';
    final isOffer = stage == 'Offer';
    final currentIndex = stages.indexOf(stage);
    final matchScore = (job['match_score'] as num?)?.toInt();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.sand),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              job['job_title'] ?? '',
                              style: const TextStyle(
                                  fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 14, height: 1.2),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              job['company'] ?? '',
                              style: const TextStyle(
                                  fontFamily: 'Inter', fontSize: 12.5, color: AppColors.stone),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (matchScore != null) ...[
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _scoreColor(matchScore).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$matchScore%',
                            style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _scoreColor(matchScore)),
                          ),
                        ),
                      ],
                      if (!isRejected && !isOffer)
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert_rounded, color: AppColors.stone, size: 18),
                          padding: EdgeInsets.zero,
                          onSelected: (value) => onUpdateStatus(job, value),
                          itemBuilder: (context) => [
                            if (currentIndex < stages.length - 2)
                              PopupMenuItem(
                                value: stages[currentIndex + 1],
                                child: Text('Move to ${stages[currentIndex + 1]}'),
                              ),
                            const PopupMenuItem(value: 'Rejected', child: Text('Mark as rejected')),
                          ],
                        )
                      else
                        const SizedBox(width: 8),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyTracker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.sand,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.dashboard_outlined, size: 30, color: AppColors.stone),
            ),
            const SizedBox(height: 16),
            Text('No saved jobs yet', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            const Text(
              'Save a job from its detail screen to start tracking your applications here.',
              style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.stone),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: 'Inter', fontSize: 14)),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}