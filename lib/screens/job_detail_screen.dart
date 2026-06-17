import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/job.dart';
import '../services/api_service.dart';
import '../widgets/match_score_ring.dart';
import '../main.dart';
import 'cover_letter_screen.dart';
import 'interview_prep_screen.dart';

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
      setState(() => _error = 'Failed to load match score — please try again.');
    } finally {
      setState(() => _isLoading = false);
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save job — please try again.')),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.job.title)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(widget.job.company,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      Text(widget.job.location, style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 24),
                      Center(child: MatchScoreRing(score: _matchResult?['match_score'] ?? 0)),
                      const SizedBox(height: 24),
                      if ((_matchResult?['missing_skills'] as List?)?.isNotEmpty ?? false) ...[
                        const Text('Missing skills:', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: (_matchResult!['missing_skills'] as List)
                              .map((s) => Chip(label: Text(s.toString())))
                              .toList(),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(_matchResult?['recommendation'] ?? ''),
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CoverLetterScreen(
                              job: widget.job,
                              cvData: _cvData!,
                            ),
                          ),
                        ),
                        child: const Text('Generate Cover Letter'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => InterviewPrepScreen(
                              job: widget.job,
                              cvData: _cvData!,
                            ),
                          ),
                        ),
                        child: const Text('Prep for Interview'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: (_isSaving || _saved) ? null : _saveToTracker,
                        icon: _isSaving
                            ? const SizedBox(
                                height: 16, width: 16,
                                child: CircularProgressIndicator(strokeWidth: 2))
                            : Icon(_saved ? Icons.check : Icons.bookmark_outline),
                        label: Text(_saved ? 'Saved to Tracker' : 'Save to Tracker'),
                      ),
                    ],
                  ),
                ),
    );
  }
}