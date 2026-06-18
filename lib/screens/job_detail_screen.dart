import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/job.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../main.dart';
import 'cover_letter_screen.dart';
import 'interview_prep_screen.dart';
import 'main_shell.dart';

class JobDetailScreen extends StatefulWidget {
  final Job job;
  const JobDetailScreen({super.key, required this.job});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _matchResult;
  Map<String, dynamic>? _cvData;
  bool _isSaving = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _loadMatch();
  }

  Future<void> _loadMatch() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final userId = supabase.auth.currentUser!.id;
      final profile = await supabase
          .from('profiles')
          .select()
          .eq('user_id', userId)
          .single();

      _cvData = {
        'skills': profile['extracted_skills'],
        'experience': profile['extracted_experience'],
      };

      final result = await ApiService.matchJob(_cvData!, widget.job.description);
      setState(() => _matchResult = result);
    } catch (e) {
      setState(() => _error = 'Couldn\'t load the match score — please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveToTracker() async {
    setState(() => _isSaving = true);
    try {
      await ApiService.saveJob(
        jobTitle: widget.job.title,
        company: widget.job.company,
        jobUrl: widget.job.url,
        matchScore: _matchResult?['match_score'] ?? 0,
        status: 'Applied',
      );
      setState(() => _saved = true);
      MainShell.of(context)?.refreshTracker();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Couldn\'t save this job — please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  int get _score => (_matchResult?['match_score'] as num?)?.toInt() ?? 0;

  Color get _scoreColor {
    if (_score >= 75) return AppColors.pine;
    if (_score >= 50) return AppColors.ember;
    return AppColors.danger;
  }

  String get _scoreLabel {
    if (_score >= 85) return 'Excellent match';
    if (_score >= 70) return 'Strong match';
    if (_score >= 50) return 'Worth a look';
    return 'Limited match';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.pine))
          : _error != null
              ? _ErrorState(message: _error!, onRetry: _loadMatch)
              : CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      backgroundColor: _scoreColor,
                      foregroundColor: Colors.white,
                      expandedHeight: 180,
                      pinned: true,
                      flexibleSpace: FlexibleSpaceBar(
                        background: _ScoreHeader(
                          score: _score,
                          label: _scoreLabel,
                          jobTitle: widget.job.title,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(widget.job.company,
                                          style: Theme.of(context).textTheme.titleMedium),
                                      const SizedBox(height: 2),
                                      Text(widget.job.location,
                                          style: Theme.of(context).textTheme.bodyMedium),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 28),
                            if ((_matchResult?['missing_skills'] as List?)?.isNotEmpty ?? false) ...[
                              Text('Where you can grow',
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 17)),
                              const SizedBox(height: 12),
                              ...List.generate(
                                (_matchResult!['missing_skills'] as List).length,
                                (i) {
                                  final skill = (_matchResult!['missing_skills'] as List)[i];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 6, height: 6,
                                          decoration: const BoxDecoration(
                                            color: AppColors.ember, shape: BoxShape.circle),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(skill.toString(),
                                              style: Theme.of(context).textTheme.bodyLarge),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 24),
                            ],
                            Text('JobHero\'s take',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 17)),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.only(left: 14),
                              decoration: const BoxDecoration(
                                border: Border(left: BorderSide(color: AppColors.sand, width: 3)),
                              ),
                              child: Text(
                                _matchResult?['recommendation'] ?? '',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontStyle: FontStyle.italic, height: 1.6),
                              ),
                            ),
                            const SizedBox(height: 32),
                            Row(
                              children: [
                                Expanded(
                                  child: FilledButton(
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            CoverLetterScreen(job: widget.job, cvData: _cvData!),
                                      ),
                                    ),
                                    child: const Text('Cover letter'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            InterviewPrepScreen(job: widget.job, cvData: _cvData!),
                                      ),
                                    ),
                                    child: const Text('Interview prep'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: TextButton.icon(
                                onPressed: (_isSaving || _saved) ? null : _saveToTracker,
                                icon: _isSaving
                                    ? const SizedBox(
                                        height: 16, width: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2))
                                    : Icon(
                                        _saved ? Icons.check_circle_rounded : Icons.bookmark_outline_rounded,
                                        size: 18,
                                        color: _saved ? AppColors.pine : AppColors.stone,
                                      ),
                                label: Text(
                                  _saved ? 'Saved to tracker' : 'Save to tracker',
                                  style: TextStyle(color: _saved ? AppColors.pine : AppColors.stone),
                                ),
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
}

class _ScoreHeader extends StatelessWidget {
  final int score;
  final String label;
  final String jobTitle;

  const _ScoreHeader({required this.score, required this.label, required this.jobTitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  jobTitle,
                  style: const TextStyle(
                    fontFamily: 'Fraunces',
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.15,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            '$score',
            style: const TextStyle(
              fontFamily: 'Fraunces',
              fontSize: 56,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 0.9,
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 8, left: 2),
            child: Text(
              '%',
              style: TextStyle(
                fontFamily: 'Fraunces',
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
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
            Text(message, style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}