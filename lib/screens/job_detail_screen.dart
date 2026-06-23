import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
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
  void initState() { super.initState(); _loadMatch(); }

  Future<void> _loadMatch() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final userId = supabase.auth.currentUser!.id;
      final profile = await supabase.from('profiles').select()
          .eq('user_id', userId).single();
      _cvData = {'skills': profile['extracted_skills'],
          'experience': profile['extracted_experience']};
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
        jobTitle: widget.job.title, company: widget.job.company,
        jobUrl: widget.job.url, matchScore: _matchResult?['match_score'] ?? 0, status: 'Applied',
      );
      setState(() => _saved = true);
      MainShell.of(context)?.refreshTracker();
    } catch (_) {} finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Color _avatarColor(String company) {
    final colors = [0xFF6366F1, 0xFF1C1C1C, 0xFF16A34A, 0xFFDC2626, 0xFFF59E0B, 0xFF9333EA];
    return Color(colors[company.hashCode % colors.length]);
  }

  @override
  Widget build(BuildContext context) {
    final sans = GoogleFonts.inter().fontFamily!;
    final score = (_matchResult?['match_score'] as num?)?.toInt() ?? 0;
    final scoreColor = score >= 75 ? AppColors.scoreHigh
        : score >= 50 ? AppColors.scoreMid : AppColors.scoreLow;
    final missing = (_matchResult?['missing_skills'] as List?) ?? [];
    final company = widget.job.company;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surface, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.arrow_back_rounded, size: 18, color: AppColors.ink),
          ),
        ),
        actions: [
          GestureDetector(
            onTap: _saveToTracker,
            child: Container(
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surface, borderRadius: BorderRadius.circular(10)),
              child: Icon(_saved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                  size: 18, color: _saved ? AppColors.green : AppColors.muted),
            ),
          ),
          GestureDetector(
            child: Container(
              margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
              decoration: BoxDecoration(
                color: AppColors.surface, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.share_outlined, size: 18, color: AppColors.muted),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.green))
          : _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(_error!, textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 16),
                  FilledButton(onPressed: _loadMatch, child: const Text('Retry')),
                ]))
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    // Company header
                    Row(children: [
                      Container(
                        width: 52, height: 52,
                        decoration: BoxDecoration(
                          color: _avatarColor(company),
                          borderRadius: BorderRadius.circular(14)),
                        child: Center(child: Text(
                          company.isNotEmpty ? company[0].toUpperCase() : '?',
                          style: const TextStyle(fontFamily: 'Inter', fontSize: 20,
                              fontWeight: FontWeight.w700, color: Colors.white))),
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(company, style: TextStyle(fontFamily: sans, fontSize: 18,
                            fontWeight: FontWeight.w800, color: AppColors.ink)),
                        Text('${company.toLowerCase().replaceAll(' ', '')}.com · Series –',
                            style: TextStyle(fontFamily: sans, fontSize: 13, color: AppColors.muted)),
                      ])),
                    ]),
                    const SizedBox(height: 16),
                    Text(widget.job.title, style: TextStyle(fontFamily: sans, fontSize: 24,
                        fontWeight: FontWeight.w800, color: AppColors.ink)),
                    const SizedBox(height: 12),

                    // Tag chips
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      ...['Remote', 'Full-time', 'Senior', '2d ago'].map((t) =>
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(t, style: TextStyle(fontFamily: sans, fontSize: 13,
                              color: AppColors.ink, fontWeight: FontWeight.w500)),
                        )),
                    ]),
                    const SizedBox(height: 20),
                    const Divider(color: AppColors.divider),
                    const SizedBox(height: 16),

                    // Action buttons
                    Row(children: [
                      Expanded(child: OutlinedButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(
                            builder: (_) => CoverLetterScreen(
                                job: widget.job, cvData: _cvData ?? {}))),
                        child: Text('Generate Cover Letter',
                            style: TextStyle(fontFamily: sans, fontSize: 14,
                                fontWeight: FontWeight.w600)),
                      )),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 140,
                        child: FilledButton.icon(
                          onPressed: () async {
                            final uri = Uri.tryParse(widget.job.url);
                            if (uri != null) launchUrl(uri);
                          },
                          icon: const Icon(Icons.open_in_new_rounded, size: 16),
                          label: Text('Apply', style: TextStyle(fontFamily: sans,
                              fontSize: 16, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 24),

                    // Match score section (if loaded)
                    if (_matchResult != null) ...[
                      Text('Match Score',
                          style: TextStyle(fontFamily: sans, fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              border: Border.all(color: scoreColor, width: 2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text('$score', style: TextStyle(fontFamily: sans,
                                fontSize: 22, fontWeight: FontWeight.w800, color: scoreColor)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(_matchResult?['recommendation'] ?? '',
                                style: TextStyle(fontFamily: sans, fontSize: 13,
                                    color: AppColors.muted, height: 1.4),
                                maxLines: 3, overflow: TextOverflow.ellipsis),
                          ])),
                        ]),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Interview prep button
                    OutlinedButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => InterviewPrepScreen(
                              job: widget.job, cvData: _cvData ?? {}))),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.psychology_outlined, size: 18),
                        const SizedBox(width: 8),
                        Text('Interview Prep', style: TextStyle(fontFamily: sans,
                            fontSize: 15, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                    const SizedBox(height: 24),

                    // About section
                    Text('About the role', style: TextStyle(fontFamily: sans,
                        fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
                    const SizedBox(height: 10),
                    Text(widget.job.description, style: TextStyle(fontFamily: sans,
                        fontSize: 14, color: AppColors.muted, height: 1.6)),

                    if (missing.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text('Requirements', style: TextStyle(fontFamily: sans,
                          fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
                      const SizedBox(height: 10),
                      ...missing.map((s) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Container(margin: const EdgeInsets.only(top: 6, right: 10),
                              width: 6, height: 6,
                              decoration: const BoxDecoration(
                                  color: AppColors.green, shape: BoxShape.circle)),
                          Expanded(child: Text(s.toString(),
                              style: TextStyle(fontFamily: sans, fontSize: 14,
                                  color: AppColors.muted, height: 1.5))),
                        ]),
                      )),
                    ],
                  ]),
              ),
    );
  }
}