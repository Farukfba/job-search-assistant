import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/job.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/match_score_ring.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.job.title, overflow: TextOverflow.ellipsis)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.pine))
          : _error != null
              ? _ErrorState(message: _error!, onRetry: _loadMatch)
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.pineLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.business_center_outlined,
                                color: AppColors.pine, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(widget.job.company,
                                    style: Theme.of(context).textTheme.titleMedium),
                                Text(widget.job.location,
                                    style: Theme.of(context).textTheme.bodyMedium),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      Center(child: MatchScoreRing(score: _matchResult?['match_score'] ?? 0)),
                      const SizedBox(height: 28),
                      if ((_matchResult?['missing_skills'] as List?)?.isNotEmpty ?? false) ...[
                        const _SectionLabel('Skills to highlight or build'),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: (_matchResult!['missing_skills'] as List)
                              .map((s) => Chip(
                                    label: Text(s.toString()),
                                    backgroundColor: AppColors.emberLight,
                                    labelStyle: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 13,
                                      color: AppColors.ember,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 20),
                      ],
                      const _SectionLabel('JobHero\'s take'),
                      const SizedBox(height: 10),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Text(
                            _matchResult?['recommendation'] ?? '',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      FilledButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CoverLetterScreen(job: widget.job, cvData: _cvData!),
                          ),
                        ),
                        icon: const Icon(Icons.edit_note_rounded, size: 20),
                        label: const Text('Generate cover letter'),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => InterviewPrepScreen(job: widget.job, cvData: _cvData!),
                          ),
                        ),
                        icon: const Icon(Icons.forum_outlined, size: 20),
                        label: const Text('Prep for interview'),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: (_isSaving || _saved) ? null : _saveToTracker,
                        icon: _isSaving
                            ? const SizedBox(
                                height: 16, width: 16,
                                child: CircularProgressIndicator(strokeWidth: 2))
                            : Icon(
                                _saved ? Icons.check_circle_rounded : Icons.bookmark_outline_rounded,
                                size: 20,
                                color: _saved ? AppColors.pine : null,
                              ),
                        label: Text(_saved ? 'Saved to tracker' : 'Save to tracker'),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        color: AppColors.stone,
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
            Text(message,
                style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}