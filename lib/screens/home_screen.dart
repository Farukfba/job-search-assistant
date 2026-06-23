import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'main_shell.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _recentJobs = [];
  int _totalJobs = 0;
  int _applications = 0;
  int _interviews = 0;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> reload() => _load();

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final jobs = await ApiService.getSavedJobs();
      int apps = 0, interviews = 0;
      for (final j in jobs) {
        final s = j['status'] ?? 'Applied';
        if (s == 'Applied') apps++;
        if (s == 'Interview') interviews++;
      }
      if (mounted) setState(() {
        _recentJobs = jobs.take(3).toList();
        _applications = apps;
        _interviews = interviews;
        _totalJobs = jobs.length;
      });
    } catch (_) {}
    finally { if (mounted) setState(() => _isLoading = false); }
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning,';
    if (h < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  String get _displayName {
    final email = supabase.auth.currentUser?.email ?? '';
    final name = email.split('@').first;
    if (name.isEmpty) return 'there';
    return name[0].toUpperCase() + name.substring(1);
  }

  String get _dateLabel {
    final now = DateTime.now();
    final days = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }

  Color _scoreColor(int score) {
    if (score >= 75) return AppColors.scoreHigh;
    if (score >= 50) return AppColors.scoreMid;
    return AppColors.scoreLow;
  }

  Color _avatarColor(String company) {
    final colors = [0xFF6366F1, 0xFF1C1C1C, 0xFF16A34A, 0xFFDC2626, 0xFF9333EA];
    return Color(colors[company.hashCode % colors.length]);
  }

  @override
  Widget build(BuildContext context) {
    final sans = GoogleFonts.inter().fontFamily!;

    if (_isLoading) return _buildSkeleton();

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.green,
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_dateLabel, style: TextStyle(fontFamily: sans, fontSize: 13,
                        color: AppColors.muted)),
                    const SizedBox(height: 4),
                    Text(_greeting, style: TextStyle(fontFamily: sans, fontSize: 24,
                        fontWeight: FontWeight.w800, color: AppColors.ink)),
                    Text(_displayName, style: TextStyle(fontFamily: sans, fontSize: 24,
                        fontWeight: FontWeight.w800, color: AppColors.ink)),
                  ]),
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Stack(children: [
                      const Center(child: Icon(Icons.notifications_outlined, size: 20,
                          color: AppColors.muted)),
                      Positioned(top: 8, right: 8,
                          child: Container(width: 7, height: 7,
                              decoration: const BoxDecoration(
                                  color: AppColors.green, shape: BoxShape.circle))),
                    ]),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text('3 new matches since yesterday', style: TextStyle(fontFamily: sans,
                  fontSize: 13, color: AppColors.muted)),
              const SizedBox(height: 24),

              // Stats grid
              Row(children: [
                Expanded(child: _StatCard(label: 'JOBS ANALYZED', value: '1,247', sans: sans)),
                const SizedBox(width: 12),
                Expanded(child: _StatCard(label: 'CV SCORE', value: '94',
                    sans: sans, highlight: true)),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _StatCard(label: 'APPLICATIONS',
                    value: _applications.toString(), sans: sans)),
                const SizedBox(width: 12),
                Expanded(child: _StatCard(label: 'INTERVIEWS',
                    value: _interviews.toString(), sans: sans)),
              ]),
              const SizedBox(height: 28),

              // Recent matches
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Row(children: [
                  Text('RECENT MATCHES', style: TextStyle(fontFamily: sans, fontSize: 11,
                      fontWeight: FontWeight.w600, color: AppColors.muted, letterSpacing: 0.5)),
                  const SizedBox(width: 6),
                  Text('· ${_recentJobs.length}', style: TextStyle(fontFamily: sans, fontSize: 11,
                      color: AppColors.muted)),
                ]),
                GestureDetector(
                  onTap: () => MainShell.of(context)?.goToTab(1),
                  child: Row(children: [
                    const Icon(Icons.swap_vert_rounded, size: 14, color: AppColors.muted),
                    const SizedBox(width: 4),
                    Text('Sort', style: TextStyle(fontFamily: sans, fontSize: 12,
                        color: AppColors.muted, fontWeight: FontWeight.w500)),
                  ]),
                ),
              ]),
              const SizedBox(height: 12),

              if (_recentJobs.isEmpty)
                _EmptyJobCard(sans: sans, onTap: () => MainShell.of(context)?.goToTab(1))
              else ...[
                ..._recentJobs.map((job) {
                  final score = (job['match_score'] as num?)?.toInt() ?? 0;
                  final company = job['company'] ?? '';
                  return _JobListCard(
                    sans: sans,
                    initial: company.isNotEmpty ? company[0].toUpperCase() : '?',
                    avatarColor: _avatarColor(company),
                    company: company,
                    role: job['job_title'] ?? '',
                    meta: 'Remote · 2d ago',
                    score: score,
                    scoreColor: _scoreColor(score),
                  );
                }),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => MainShell.of(context)?.goToTab(1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(child: Text('See all 1,247 matches →',
                        style: TextStyle(fontFamily: sans, fontSize: 14,
                            fontWeight: FontWeight.w600, color: AppColors.muted))),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          children: [
            _Shimmer(width: 180, height: 16, radius: 8),
            const SizedBox(height: 8),
            _Shimmer(width: 240, height: 28, radius: 8),
            const SizedBox(height: 4),
            _Shimmer(width: 180, height: 28, radius: 8),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: _Shimmer(height: 80, radius: 12)),
              const SizedBox(width: 12),
              Expanded(child: _Shimmer(height: 80, radius: 12)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _Shimmer(height: 80, radius: 12)),
              const SizedBox(width: 12),
              Expanded(child: _Shimmer(height: 80, radius: 12)),
            ]),
            const SizedBox(height: 28),
            _Shimmer(width: 140, height: 12, radius: 6),
            const SizedBox(height: 12),
            ...List.generate(3, (_) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _Shimmer(height: 80, radius: 14),
            )),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String sans;
  final bool highlight;

  const _StatCard({required this.label, required this.value,
      required this.sans, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlight ? AppColors.greenLight : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: TextStyle(fontFamily: sans, fontSize: 28,
            fontWeight: FontWeight.w800,
            color: highlight ? AppColors.green : AppColors.ink)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontFamily: sans, fontSize: 11,
            fontWeight: FontWeight.w600,
            color: highlight ? AppColors.green : AppColors.muted, letterSpacing: 0.5)),
      ]),
    );
  }
}

class _JobListCard extends StatelessWidget {
  final String sans, initial, company, role, meta;
  final Color avatarColor, scoreColor;
  final int score;

  const _JobListCard({required this.sans, required this.initial,
      required this.avatarColor, required this.company, required this.role,
      required this.meta, required this.score, required this.scoreColor});

  @override
  Widget build(BuildContext context) {
    return Container(
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
          decoration: BoxDecoration(color: avatarColor, borderRadius: BorderRadius.circular(12)),
          child: Center(child: Text(initial, style: const TextStyle(fontFamily: 'Inter',
              fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(company, style: TextStyle(fontFamily: sans, fontSize: 15,
              fontWeight: FontWeight.w700, color: AppColors.ink)),
          Text(role, style: TextStyle(fontFamily: sans, fontSize: 13, color: AppColors.muted)),
          const SizedBox(height: 4),
          Text(meta, style: TextStyle(fontFamily: sans, fontSize: 12, color: AppColors.placeholder)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: scoreColor, width: 1.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('$score', style: TextStyle(fontFamily: sans, fontSize: 13,
                fontWeight: FontWeight.w700, color: scoreColor)),
          ),
          const SizedBox(height: 8),
          // Icon(Icons.favorite_border_rounded, size: 18, color: AppColors.muted),
        ]),
      ]),
    );
  }
}

class _EmptyJobCard extends StatelessWidget {
  final String sans;
  final VoidCallback onTap;
  const _EmptyJobCard({required this.sans, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(children: [
          const Icon(Icons.search_rounded, size: 28, color: AppColors.muted),
          const SizedBox(height: 8),
          Text('Search for your first match', style: TextStyle(fontFamily: sans,
              fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.muted)),
        ]),
      ),
    );
  }
}

class _Shimmer extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;
  const _Shimmer({this.width, required this.height, required this.radius});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFEEEEEE),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}