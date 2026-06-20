// SAMPLE — Sharp / modern-tech direction for Job Detail.
// Self-contained: defines its own local style constants so it can be
// dropped in and previewed without touching app_theme.dart yet.
// If approved, these tokens graduate into AppTheme and roll across all screens.

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/job.dart';
import '../services/api_service.dart';
import '../main.dart';
import 'cover_letter_screen.dart';
import 'interview_prep_screen.dart';
import 'main_shell.dart';

// --- Sharp/modern-tech palette (pine-anchored, high contrast) ---
class _C {
  static const ink = Color(0xFF14130F);      // near-black, warm
  static const paper = Color(0xFFF6F4EF);     // tight off-white
  static const surface = Color(0xFFFFFFFF);
  static const pine = Color(0xFF1F4A3D);      // deeper, bolder pine
  static const pineBright = Color(0xFF2D7A5F); // accent pop
  static const ember = Color(0xFFD2691E);
  static const danger = Color(0xFFB3401F);
  static const line = Color(0xFF14130F);      // hairline borders use ink at low opacity
  static const muted = Color(0xFF6E6A60);
}

const _mono = 'Inter'; // swap to a real mono later if desired; weight does the work

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
    setState(() { _isLoading = true; _error = null; });
    try {
      final userId = supabase.auth.currentUser!.id;
      final profile = await supabase.from('profiles').select().eq('user_id', userId).single();
      _cvData = {'skills': profile['extracted_skills'], 'experience': profile['extracted_experience']};
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Couldn\'t save this job — please try again.')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  int get _score => (_matchResult?['match_score'] as num?)?.toInt() ?? 0;
  Color get _scoreColor => _score >= 75 ? _C.pineBright : _score >= 50 ? _C.ember : _C.danger;
  String get _scoreLabel => _score >= 85 ? 'EXCELLENT MATCH'
      : _score >= 70 ? 'STRONG MATCH' : _score >= 50 ? 'WORTH A LOOK' : 'LIMITED MATCH';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.paper,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _C.pine))
          : _error != null
              ? _errorState()
              : CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      backgroundColor: _C.paper,
                      surfaceTintColor: Colors.transparent,
                      foregroundColor: _C.ink,
                      elevation: 0,
                      pinned: true,
                      titleSpacing: 0,
                      title: Text(widget.job.title,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600, color: _C.ink)),
                    ),
                    SliverToBoxAdapter(child: _body(context)),
                  ],
                ),
    );
  }

  Widget _body(BuildContext context) {
    final missing = (_matchResult?['missing_skills'] as List?) ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- SCORE BLOCK: the signature element. Big mono number, no ring,
        // sitting on a bordered panel with a measured baseline rule. ---
        Container(
          margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _C.surface,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: _C.line.withValues(alpha: 0.12)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // big number
                  Text('$_score',
                      style: TextStyle(fontFamily: _mono, fontSize: 64, height: 0.85,
                          fontWeight: FontWeight.w700, color: _scoreColor, letterSpacing: -2)),
                  const SizedBox(width: 2),
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text('%', style: TextStyle(fontFamily: _mono, fontSize: 20,
                        fontWeight: FontWeight.w700, color: _scoreColor)),
                  ),
                  const Spacer(),
                  // label tag, uppercase mono
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _scoreColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(_scoreLabel,
                        style: TextStyle(fontFamily: _mono, fontSize: 10, fontWeight: FontWeight.w700,
                            letterSpacing: 0.6, color: _scoreColor)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // progress rule
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: _score / 100, minHeight: 4,
                  backgroundColor: _C.line.withValues(alpha: 0.08),
                  valueColor: AlwaysStoppedAnimation(_scoreColor),
                ),
              ),
              const SizedBox(height: 16),
              // company / location as a mono meta row
              Row(
                children: [
                  Text(widget.job.company.toUpperCase(),
                      style: const TextStyle(fontFamily: _mono, fontSize: 11, fontWeight: FontWeight.w600,
                          letterSpacing: 0.4, color: _C.ink)),
                  const SizedBox(width: 8),
                  Container(width: 3, height: 3, decoration: const BoxDecoration(color: _C.muted, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(widget.job.location.toUpperCase(),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontFamily: _mono, fontSize: 11, fontWeight: FontWeight.w500,
                            letterSpacing: 0.4, color: _C.muted)),
                  ),
                ],
              ),
            ],
          ),
        ),

        // --- SKILLS TO BUILD: numbered list, not chips ---
        if (missing.isNotEmpty) ...[
          _sectionHeader('SKILLS TO BUILD', missing.length),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              children: List.generate(missing.length, (i) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 1),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                  decoration: BoxDecoration(
                    color: _C.surface,
                    border: Border(bottom: BorderSide(color: _C.line.withValues(alpha: 0.08))),
                  ),
                  child: Row(
                    children: [
                      Text('${(i + 1).toString().padLeft(2, '0')}',
                          style: const TextStyle(fontFamily: _mono, fontSize: 12, fontWeight: FontWeight.w700, color: _C.muted)),
                      const SizedBox(width: 14),
                      Expanded(child: Text(missing[i].toString(),
                          style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: _C.ink))),
                      const Icon(Icons.arrow_outward_rounded, size: 15, color: _C.muted),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],

        // --- RECOMMENDATION: framed as a quote block with a mono tag ---
        _sectionHeader('THE VERDICT', null),
        Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          decoration: BoxDecoration(
            color: _C.ink,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            _matchResult?['recommendation'] ?? '',
            style: const TextStyle(fontFamily: 'Inter', fontSize: 14.5, height: 1.55, color: _C.paper),
          ),
        ),

        const SizedBox(height: 16),
        // --- ACTIONS ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _primaryBtn('Cover letter', () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => CoverLetterScreen(job: widget.job, cvData: _cvData!))))),
                  const SizedBox(width: 8),
                  Expanded(child: _ghostBtn('Interview prep', () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => InterviewPrepScreen(job: widget.job, cvData: _cvData!))))),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: (_isSaving || _saved) ? null : _saveToTracker,
                  icon: _isSaving
                      ? const SizedBox(height: 15, width: 15, child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(_saved ? Icons.check_rounded : Icons.add_rounded, size: 18,
                          color: _saved ? _C.pineBright : _C.muted),
                  label: Text(_saved ? 'SAVED TO TRACKER' : 'SAVE TO TRACKER',
                      style: TextStyle(fontFamily: _mono, fontSize: 12, fontWeight: FontWeight.w600,
                          letterSpacing: 0.5, color: _saved ? _C.pineBright : _C.muted)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
      ],
    );
  }

  Widget _sectionHeader(String label, int? count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontFamily: _mono, fontSize: 11, fontWeight: FontWeight.w700,
              letterSpacing: 1.0, color: _C.ink)),
          if (count != null) ...[
            const SizedBox(width: 8),
            Text('[$count]', style: const TextStyle(fontFamily: _mono, fontSize: 11,
                fontWeight: FontWeight.w600, color: _C.muted)),
          ],
          const SizedBox(width: 10),
          Expanded(child: Container(height: 1, color: _C.line.withValues(alpha: 0.1))),
        ],
      ),
    );
  }

  Widget _primaryBtn(String label, VoidCallback onTap) {
    return Material(
      color: _C.pine,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          height: 48, alignment: Alignment.center,
          child: Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 14,
              fontWeight: FontWeight.w600, color: _C.paper)),
        ),
      ),
    );
  }

  Widget _ghostBtn(String label, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          height: 48, alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: _C.ink.withValues(alpha: 0.18)),
          ),
          child: Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 14,
              fontWeight: FontWeight.w600, color: _C.ink)),
        ),
      ),
    );
  }

  Widget _errorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_error!, textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: _C.ink)),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: _loadMatch, child: const Text('Retry')),
        ]),
      ),
    );
  }
}