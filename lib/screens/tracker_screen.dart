import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'main_shell.dart';

class TrackerScreen extends StatefulWidget {
  const TrackerScreen({super.key});
  @override
  State<TrackerScreen> createState() => TrackerScreenState();
}

class TrackerScreenState extends State<TrackerScreen> {
  static const _stages = ['Interview', 'Applied', 'Offer', 'Rejected'];
  bool _isLoading = true;
  List<Map<String, dynamic>> _jobs = [];
  String _activeFilter = 'Interview';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> reload() => _load();

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final jobs = await ApiService.getSavedJobs();
      setState(() => _jobs = jobs);
    } catch (_) {}
    finally { if (mounted) setState(() => _isLoading = false); }
  }

  Future<void> _updateStatus(Map<String, dynamic> job, String newStatus) async {
    try {
      await ApiService.updateJobStatus(job['id'], newStatus);
      setState(() => job['status'] = newStatus);
    } catch (_) {}
  }

  Color _stageColor(String stage) {
    switch (stage) {
      case 'Interview': return AppColors.interview;
      case 'Applied': return AppColors.applied;
      case 'Offer': return AppColors.offer;
      case 'Rejected': return AppColors.rejected;
      default: return AppColors.muted;
    }
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

  int _countForStage(String stage) =>
      _jobs.where((j) => (j['status'] ?? 'Applied') == stage).length;

  @override
  Widget build(BuildContext context) {
    final sans = GoogleFonts.inter().fontFamily!;
    final total = _jobs.length;
    final stageJobs = _jobs.where((j) => (j['status'] ?? 'Applied') == _activeFilter).toList();

    if (_isLoading) {
      return const Scaffold(backgroundColor: AppColors.white,
          body: Center(child: CircularProgressIndicator(color: AppColors.green)));
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.green,
          onRefresh: _load,
          child: _jobs.isEmpty ? _emptyState(sans) : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                child: Row(children: [
                  Text('Tracker', style: TextStyle(fontFamily: sans, fontSize: 28,
                      fontWeight: FontWeight.w800, color: AppColors.ink)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => MainShell.of(context)?.goToTab(1),
                    child: Container(
                      width: 36, height: 36,
                      decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle),
                      child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Text('$total application${total != 1 ? 's' : ''}',
                    style: TextStyle(fontFamily: sans, fontSize: 14, color: AppColors.muted)),
              ),

              // Stage filter tabs
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: _stages.map((stage) {
                    final count = _countForStage(stage);
                    final active = stage == _activeFilter;
                    final color = _stageColor(stage);
                    return GestureDetector(
                      onTap: () => setState(() => _activeFilter = stage),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: active ? color.withValues(alpha: 0.12) : AppColors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: active ? color : AppColors.border,
                            width: active ? 1.5 : 1,
                          ),
                        ),
                        child: Row(children: [
                          Container(width: 7, height: 7,
                              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          Text(stage, style: TextStyle(fontFamily: sans, fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: active ? color : AppColors.muted)),
                          const SizedBox(width: 6),
                          Text('$count', style: TextStyle(fontFamily: sans, fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: active ? color : AppColors.muted)),
                        ]),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Section header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(children: [
                  Text(_activeFilter.toUpperCase(), style: TextStyle(fontFamily: sans,
                      fontSize: 11, fontWeight: FontWeight.w600,
                      color: AppColors.muted, letterSpacing: 0.5)),
                  Text(' · ${stageJobs.length}', style: TextStyle(fontFamily: sans,
                      fontSize: 11, color: AppColors.muted)),
                  const Spacer(),
                  Row(children: [
                    const Icon(Icons.swap_vert_rounded, size: 14, color: AppColors.muted),
                    const SizedBox(width: 4),
                    Text('Sort', style: TextStyle(fontFamily: sans, fontSize: 12,
                        color: AppColors.muted)),
                  ]),
                ]),
              ),
              const SizedBox(height: 10),

              Expanded(
                child: stageJobs.isEmpty
                    ? Center(child: Text('No ${_activeFilter.toLowerCase()} applications',
                        style: TextStyle(fontFamily: sans, fontSize: 14, color: AppColors.muted)))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        itemCount: stageJobs.length,
                        itemBuilder: (context, i) {
                          final job = stageJobs[i];
                          final company = job['company'] ?? '';
                          final score = (job['match_score'] as num?)?.toInt() ?? 0;
                          final stageColor = _stageColor(_activeFilter);
                          final date = job['created_at'] != null
                              ? _formatDate(DateTime.tryParse(job['created_at']) ?? DateTime.now())
                              : '';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: IntrinsicHeight(
                                child: Row(children: [
                                  Container(width: 4, color: stageColor),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 14),
                                      child: Row(children: [
                                        Container(
                                          width: 44, height: 44,
                                          decoration: BoxDecoration(
                                            color: _avatarColor(company),
                                            borderRadius: BorderRadius.circular(12)),
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
                                          Text(job['job_title'] ?? '', style: TextStyle(
                                              fontFamily: sans, fontSize: 15,
                                              fontWeight: FontWeight.w700, color: AppColors.ink),
                                              maxLines: 1, overflow: TextOverflow.ellipsis),
                                          Text('$company · $date', style: TextStyle(
                                              fontFamily: sans, fontSize: 13,
                                              color: AppColors.muted)),
                                        ])),
                                        const SizedBox(width: 10),
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
                                        ),
                                        const SizedBox(width: 4),
                                        PopupMenuButton<String>(
                                          icon: const Icon(Icons.more_horiz_rounded,
                                              color: AppColors.muted, size: 20),
                                          onSelected: (v) => _updateStatus(job, v),
                                          itemBuilder: (_) {
                                            final current = job['status'] ?? 'Applied';
                                            final currentIdx = _stages.indexOf(current);
                                            return [
                                              if (currentIdx < _stages.length - 1)
                                                PopupMenuItem(value: _stages[currentIdx + 1],
                                                    child: Text('Move to ${_stages[currentIdx + 1]}')),
                                              if (current != 'Rejected')
                                                const PopupMenuItem(value: 'Rejected',
                                                    child: Text('Mark as rejected')),
                                            ];
                                          },
                                        ),
                                      ]),
                                    ),
                                  ),
                                ]),
                              ),
                            ),
                          );
                        }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = ['Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[dt.month - 1]} ${dt.day}';
  }

  Widget _emptyState(String sans) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Row(children: [
            Text('Tracker', style: TextStyle(fontFamily: sans, fontSize: 28,
                fontWeight: FontWeight.w800, color: AppColors.ink)),
            const Spacer(),
            GestureDetector(
              onTap: () => MainShell.of(context)?.goToTab(1),
              child: Container(
                width: 36, height: 36,
                decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle),
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
              ),
            ),
          ]),
        ),
        Expanded(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.bar_chart_rounded, size: 40, color: AppColors.muted),
          const SizedBox(height: 12),
          Text('No applications yet', style: TextStyle(fontFamily: sans,
              fontSize: 15, color: AppColors.muted)),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: FilledButton(
              onPressed: () => MainShell.of(context)?.goToTab(1),
              child: Text('Track your first application',
                  style: TextStyle(fontFamily: sans, fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ]))),
      ])),
    );
  }
}