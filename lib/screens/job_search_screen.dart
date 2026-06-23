import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../models/job.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'job_detail_screen.dart';

enum _SortMode { none, bestMatch, lowestMatch }

class JobSearchScreen extends StatefulWidget {
  const JobSearchScreen({super.key});
  @override
  State<JobSearchScreen> createState() => _JobSearchScreenState();
}

class _JobSearchScreenState extends State<JobSearchScreen> {
  final _searchController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  List<Job> _jobs = [];
  bool _hasSearched = false;
  bool _isScoring = false;
  Map<String, int> _scores = {};
  bool _scoresShown = false;
  _SortMode _sortMode = _SortMode.none;
  Map<String, dynamic>? _cvData;

  // Active filter chips
  final Set<String> _activeFilters = {};
  static const _filterOptions = ['Remote', 'Full-time', 'Senior', '\$150k+', 'React'];

  @override
  void dispose() { _searchController.dispose(); super.dispose(); }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _isLoading = true; _error = null; _hasSearched = true;
      _scores = {}; _scoresShown = false; _sortMode = _SortMode.none;
    });
    try {
      final parts = query.trim().split(' ');
      final title = parts.take(3).join(' ');
      final location = parts.length > 3 ? parts.skip(3).join(' ') : 'london';
      final results = await ApiService.searchJobs(title, location);
      setState(() => _jobs = results.map((j) => Job.fromJson(j)).toList());
    } catch (e) {
      setState(() => _error = 'Search failed — please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showMatchScores() async {
    setState(() => _isScoring = true);
    try {
      if (_cvData == null) {
        final userId = supabase.auth.currentUser!.id;
        final profile = await supabase.from('profiles').select()
            .eq('user_id', userId).single();
        _cvData = {'skills': profile['extracted_skills'],
            'experience': profile['extracted_experience']};
      }
      final scores = <String, int>{};
      for (final job in _jobs) {
        try {
          final result = await ApiService.matchJob(_cvData!, job.description);
          scores[job.url] = (result['match_score'] as num?)?.toInt() ?? 0;
        } catch (_) {}
      }
      setState(() { _scores = scores; _scoresShown = true; _sortMode = _SortMode.bestMatch; });
    } catch (_) {} finally {
      if (mounted) setState(() => _isScoring = false);
    }
  }

  List<Job> get _filteredJobs {
    var jobs = _sortMode == _SortMode.none || !_scoresShown ? _jobs : [..._jobs]
      ..sort((a, b) {
        final sa = _scores[a.url] ?? -1, sb = _scores[b.url] ?? -1;
        return _sortMode == _SortMode.bestMatch ? sb.compareTo(sa) : sa.compareTo(sb);
      });

    // Apply active filters
    if (_activeFilters.isEmpty) return jobs;
    return jobs.where((job) {
      final desc = '${job.title} ${job.description} ${job.location}'.toLowerCase();
      return _activeFilters.every((f) {
        switch (f) {
          case 'Remote': return desc.contains('remote');
          case 'Full-time': return desc.contains('full');
          case 'Senior': return desc.contains('senior') || job.title.toLowerCase().contains('senior');
          case '\$150k+': return desc.contains('150') || desc.contains('180') || desc.contains('200');
          case 'React': return desc.contains('react');
          default: return true;
        }
      });
    }).toList();
  }

  Color _scoreColor(int score) {
    if (score >= 75) return AppColors.scoreHigh;
    if (score >= 50) return AppColors.scoreMid;
    return AppColors.scoreLow;
  }

  Color _avatarColor(String company) {
    final colors = [0xFF6366F1, 0xFF1C1C1C, 0xFF16A34A, 0xFFDC2626, 0xFFF59E0B, 0xFF9333EA];
    return Color(colors[company.hashCode % colors.length]);
  }

  @override
  Widget build(BuildContext context) {
    final sans = GoogleFonts.inter().fontFamily!;
    final jobs = _filteredJobs;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onSubmitted: _search,
                      decoration: InputDecoration(
                        hintText: 'Search roles, companies, skills...',
                        hintStyle: TextStyle(fontFamily: sans, fontSize: 14,
                            color: AppColors.placeholder),
                        prefixIcon: const Icon(Icons.search_rounded,
                            size: 20, color: AppColors.muted),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        filled: false,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () {
                    // Clear all filters
                    setState(() => _activeFilters.clear());
                  },
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: _activeFilters.isNotEmpty ? AppColors.green : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.tune_rounded, size: 20,
                        color: _activeFilters.isNotEmpty ? AppColors.white : AppColors.muted),
                  ),
                ),
              ]),
            ),

            // Filter chips — now interactive
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: _filterOptions.map((f) {
                  final active = _activeFilters.contains(f);
                  return GestureDetector(
                    onTap: () => setState(() {
                      if (active) _activeFilters.remove(f);
                      else _activeFilters.add(f);
                    }),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: active ? AppColors.green : AppColors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: active ? AppColors.green : AppColors.border,
                          width: active ? 1.5 : 1,
                        ),
                      ),
                      child: Text(f, style: TextStyle(fontFamily: sans, fontSize: 13,
                          color: active ? AppColors.white : AppColors.ink,
                          fontWeight: active ? FontWeight.w600 : FontWeight.w500)),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),

            if (_hasSearched && _jobs.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: [
                  Text(_scoresShown ? 'SCORED RESULTS' : 'RESULTS',
                      style: TextStyle(fontFamily: sans, fontSize: 11,
                          fontWeight: FontWeight.w600, color: AppColors.muted, letterSpacing: 0.5)),
                  Text(' · ${jobs.length}', style: TextStyle(fontFamily: sans,
                      fontSize: 11, color: AppColors.muted)),
                  const Spacer(),
                  GestureDetector(
                    onTap: _scoresShown ? () => setState(() {
                      _sortMode = _sortMode == _SortMode.bestMatch
                          ? _SortMode.lowestMatch : _SortMode.bestMatch;
                    }) : null,
                    child: Row(children: [
                      const Icon(Icons.swap_vert_rounded, size: 14, color: AppColors.muted),
                      const SizedBox(width: 4),
                      Text('Sort', style: TextStyle(fontFamily: sans, fontSize: 12,
                          color: AppColors.muted, fontWeight: FontWeight.w500)),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: 8),

              if (_scoresShown)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(color: AppColors.greenLight,
                        borderRadius: BorderRadius.circular(10)),
                    child: Row(children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(
                          color: AppColors.green, shape: BoxShape.circle)),
                      const SizedBox(width: 10),
                      Text('Showing match scores for your CV profile',
                          style: TextStyle(fontFamily: sans, fontSize: 13,
                              color: AppColors.green, fontWeight: FontWeight.w500)),
                    ]),
                  ),
                )
              else if (!_isScoring)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: GestureDetector(
                    onTap: _showMatchScores,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(color: AppColors.greenLight,
                          borderRadius: BorderRadius.circular(10)),
                      child: Row(children: [
                        Container(width: 8, height: 8, decoration: const BoxDecoration(
                            color: AppColors.green, shape: BoxShape.circle)),
                        const SizedBox(width: 10),
                        Text('Tap to show match scores',
                            style: TextStyle(fontFamily: sans, fontSize: 13,
                                color: AppColors.green, fontWeight: FontWeight.w500)),
                      ]),
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: Row(children: [
                    const SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.green)),
                    const SizedBox(width: 10),
                    Text('Scoring ${_jobs.length} jobs...',
                        style: TextStyle(fontFamily: sans, fontSize: 13, color: AppColors.muted)),
                  ]),
                ),
            ],

            Expanded(
              child: !_hasSearched
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.search_rounded, size: 36, color: AppColors.muted),
                      const SizedBox(height: 12),
                      Text('Search for your next role', style: TextStyle(fontFamily: sans,
                          fontSize: 15, color: AppColors.muted, fontWeight: FontWeight.w500)),
                    ]))
                  : _isLoading
                      ? const Center(child: CircularProgressIndicator(color: AppColors.green))
                      : jobs.isEmpty
                          ? Center(child: Text(
                              _activeFilters.isNotEmpty
                                  ? 'No results match the selected filters'
                                  : 'No results found',
                              style: TextStyle(fontFamily: sans, fontSize: 15, color: AppColors.muted)))
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                              itemCount: jobs.length,
                              itemBuilder: (context, i) {
                                final job = jobs[i];
                                final score = _scoresShown ? _scores[job.url] : null;
                                final company = job.company;

                                return GestureDetector(
                                  onTap: () => Navigator.push(context, MaterialPageRoute(
                                      builder: (_) => JobDetailScreen(job: job))),
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppColors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: Row(children: [
                                      Container(
                                        width: 44, height: 44,
                                        decoration: BoxDecoration(
                                          color: _avatarColor(company),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Center(child: Text(
                                          company.isNotEmpty ? company[0].toUpperCase() : '?',
                                          style: const TextStyle(fontFamily: 'Inter',
                                              fontSize: 16, fontWeight: FontWeight.w700,
                                              color: Colors.white))),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                        Text(company, style: TextStyle(fontFamily: sans,
                                            fontSize: 15, fontWeight: FontWeight.w700,
                                            color: AppColors.ink)),
                                        Text(job.title, style: TextStyle(fontFamily: sans,
                                            fontSize: 13, color: AppColors.muted)),
                                        const SizedBox(height: 4),
                                        Text('${job.location} · 2d ago',
                                            style: TextStyle(fontFamily: sans,
                                                fontSize: 12, color: AppColors.placeholder)),
                                      ])),
                                      const SizedBox(width: 10),
                                      // Score badge only when scores are shown
                                      if (score != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                                color: _scoreColor(score), width: 1.5),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text('$score', style: TextStyle(
                                              fontFamily: sans, fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: _scoreColor(score))),
                                        )
                                      else
                                        // Save bookmark instead of heart
                                        GestureDetector(
                                          onTap: () async {
                                            try {
                                              await ApiService.saveJob(
                                                jobTitle: job.title,
                                                company: job.company,
                                                jobUrl: job.url,
                                                matchScore: 0,
                                                status: 'Applied',
                                              );
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                    content: Text('Saved to tracker'),
                                                    duration: Duration(seconds: 2),
                                                  ),
                                                );
                                              }
                                            } catch (_) {}
                                          },
                                          child: Container(
                                            width: 36, height: 36,
                                            decoration: BoxDecoration(
                                              color: AppColors.surface,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Icon(Icons.bookmark_outline_rounded,
                                                size: 18, color: AppColors.muted),
                                          ),
                                        ),
                                    ]),
                                  ),
                                );
                              }),
            ),
          ],
        ),
      ),
    );
  }
}