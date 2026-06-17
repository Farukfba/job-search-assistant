import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../models/job.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/job_card.dart';
import 'job_detail_screen.dart';

enum _SortMode { none, bestMatch, lowestMatch }

class JobSearchScreen extends StatefulWidget {
  const JobSearchScreen({super.key});

  @override
  State<JobSearchScreen> createState() => _JobSearchScreenState();
}

class _JobSearchScreenState extends State<JobSearchScreen> {
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  List<Job> _jobs = [];
  bool _hasSearched = false;

  bool _isScoring = false;
  Map<String, int> _scores = {}; // job.url -> match_score
  bool _scoresShown = false;
  _SortMode _sortMode = _SortMode.none;
  Map<String, dynamic>? _cvData;

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final title = _titleController.text.trim();
    final location = _locationController.text.trim();

    if (title.isEmpty || location.isEmpty) {
      setState(() => _error = 'Enter both a job title and location.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _hasSearched = true;
      _scores = {};
      _scoresShown = false;
      _sortMode = _SortMode.none;
    });

    try {
      final results = await ApiService.searchJobs(title, location);
      setState(() => _jobs = results.map((j) => Job.fromJson(j)).toList());
    } catch (e) {
      setState(() => _error = 'Couldn\'t search jobs right now — please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showMatchScores() async {
    setState(() => _isScoring = true);
    try {
      if (_cvData == null) {
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
      }

      final scores = <String, int>{};
      for (final job in _jobs) {
        try {
          final result = await ApiService.matchJob(_cvData!, job.description);
          scores[job.url] = (result['match_score'] as num?)?.toInt() ?? 0;
        } catch (_) {
          // Skip jobs that fail to score rather than failing the whole batch.
        }
      }

      setState(() {
        _scores = scores;
        _scoresShown = true;
        _sortMode = _SortMode.bestMatch;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Couldn\'t load match scores — please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isScoring = false);
    }
  }

  Future<void> _logout() async {
    await supabase.auth.signOut();
  }

  List<Job> get _sortedJobs {
    if (!_scoresShown || _sortMode == _SortMode.none) return _jobs;
    final sorted = [..._jobs];
    sorted.sort((a, b) {
      final scoreA = _scores[a.url] ?? -1;
      final scoreB = _scores[b.url] ?? -1;
      return _sortMode == _SortMode.bestMatch
          ? scoreB.compareTo(scoreA)
          : scoreA.compareTo(scoreB);
    });
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find a role'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 20),
            tooltip: 'Log out',
            onPressed: _logout,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Job title',
                      hintText: 'e.g. Flutter Developer',
                      prefixIcon: Icon(Icons.work_outline_rounded, size: 20),
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      labelText: 'Location',
                      hintText: 'e.g. London',
                      prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: _isLoading ? null : _search,
                    icon: _isLoading
                        ? const SizedBox(
                            height: 18, width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.paper),
                          )
                        : const Icon(Icons.search_rounded, size: 20),
                    label: Text(_isLoading ? 'Searching live listings...' : 'Search jobs'),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.error_outline, size: 16, color: AppColors.ember),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(_error!,
                              style: const TextStyle(color: AppColors.ember, fontSize: 13)),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (_hasSearched && _jobs.isNotEmpty) _buildToolbar(),
            const Divider(height: 1),
            Expanded(child: _buildResults()),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        children: [
          if (!_scoresShown)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isScoring ? null : _showMatchScores,
                icon: _isScoring
                    ? const SizedBox(
                        height: 16, width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.bolt_rounded, size: 18, color: AppColors.ember),
                label: Text(_isScoring ? 'Scoring ${_jobs.length} jobs...' : 'Show match scores'),
              ),
            )
          else
            Expanded(
              child: Row(
                children: [
                  Text('Sort: ', style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(width: 4),
                  Expanded(
                    child: SegmentedButton<_SortMode>(
                      segments: const [
                        ButtonSegment(value: _SortMode.bestMatch, label: Text('Best match')),
                        ButtonSegment(value: _SortMode.lowestMatch, label: Text('Lowest match')),
                      ],
                      selected: {_sortMode == _SortMode.none ? _SortMode.bestMatch : _sortMode},
                      onSelectionChanged: (s) => setState(() => _sortMode = s.first),
                      style: const ButtonStyle(visualDensity: VisualDensity.compact),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (!_hasSearched) {
      return _EmptyState(
        icon: Icons.travel_explore_rounded,
        title: 'Search to get started',
        subtitle: 'Try a job title and a location — we\'ll pull live listings for you.',
      );
    }

    if (_jobs.isEmpty && !_isLoading) {
      return _EmptyState(
        icon: Icons.search_off_rounded,
        title: 'No jobs found',
        subtitle: 'Try a broader title or a different location.',
      );
    }

    final jobs = _sortedJobs;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      itemCount: jobs.length,
      itemBuilder: (context, index) {
        final job = jobs[index];
        final score = _scoresShown ? _scores[job.url] : null;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: JobCard(
            job: job,
            matchScore: score,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => JobDetailScreen(job: job)),
            ),
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({required this.icon, required this.title, required this.subtitle});

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
              child: Icon(icon, size: 30, color: AppColors.stone),
            ),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(subtitle,
                style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}