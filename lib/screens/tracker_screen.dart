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

  /// Public so MainShell (or any ancestor holding a key to this screen)
  /// can force a refresh after a job is saved elsewhere in the app —
  /// needed because IndexedStack keeps this screen alive instead of
  /// recreating it, so initState only runs once per session.
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

  IconData _stageIcon(String stage) {
    switch (stage) {
      case 'Interview':
        return Icons.forum_outlined;
      case 'Offer':
        return Icons.celebration_outlined;
      case 'Rejected':
        return Icons.close_rounded;
      default:
        return Icons.send_outlined;
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
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                          children: _stages.map((stage) {
                            final stageJobs =
                                _jobs.where((j) => (j['status'] ?? 'Applied') == stage).toList();
                            return _StageSection(
                              stage: stage,
                              stages: _stages,
                              color: _stageColor(stage),
                              icon: _stageIcon(stage),
                              jobs: stageJobs,
                              onUpdateStatus: _updateStatus,
                            );
                          }).toList(),
                        ),
        ),
      ),
    );
  }
}

class _StageSection extends StatelessWidget {
  final String stage;
  final List<String> stages;
  final Color color;
  final IconData icon;
  final List<Map<String, dynamic>> jobs;
  final void Function(Map<String, dynamic> job, String newStatus) onUpdateStatus;

  const _StageSection({
    required this.stage,
    required this.stages,
    required this.color,
    required this.icon,
    required this.jobs,
    required this.onUpdateStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 10),
          child: Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                stage,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${jobs.length}',
                  style: TextStyle(
                      fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: color),
                ),
              ),
            ],
          ),
        ),
        if (jobs.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: Text(
              'No jobs here yet.',
              style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.stone),
            ),
          )
        else
          ...jobs.map((job) => _TrackerCard(
                job: job,
                stage: stage,
                stages: stages,
                color: color,
                onUpdateStatus: onUpdateStatus,
              )),
      ],
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

  @override
  Widget build(BuildContext context) {
    final isRejected = stage == 'Rejected';
    final isOffer = stage == 'Offer';
    final currentIndex = stages.indexOf(stage);
    final matchScore = job['match_score'];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(14, 6, 8, 6),
        title: Text(
          job['job_title'] ?? '',
          style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Expanded(
              child: Text(
                job['company'] ?? '',
                style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.stone),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (matchScore != null) ...[
              const SizedBox(width: 6),
              const Icon(Icons.bolt_rounded, size: 12, color: AppColors.ember),
              Text('$matchScore%',
                  style: const TextStyle(
                      fontFamily: 'Inter', fontSize: 12, color: AppColors.ember, fontWeight: FontWeight.w600)),
            ],
          ],
        ),
        trailing: (isRejected || isOffer)
            ? null
            : PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: AppColors.stone, size: 20),
                onSelected: (value) => onUpdateStatus(job, value),
                itemBuilder: (context) => [
                  if (currentIndex < stages.length - 2)
                    PopupMenuItem(
                      value: stages[currentIndex + 1],
                      child: Text('Move to ${stages[currentIndex + 1]}'),
                    ),
                  const PopupMenuItem(value: 'Rejected', child: Text('Mark as rejected')),
                ],
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
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.emberLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.error_outline_rounded, color: AppColors.ember, size: 26),
            ),
            const SizedBox(height: 16),
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