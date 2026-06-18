import 'package:flutter/material.dart';
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
  Map<String, int> _stageCounts = {
    'Applied': 0,
    'Interview': 0,
    'Offer': 0,
    'Rejected': 0,
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Public so other tabs (e.g. after saving a job) can ask Home to
  /// refresh its stats without needing a full screen rebuild — same
  /// pattern used for TrackerScreen.reload().
  Future<void> reload() => _load();

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final jobs = await ApiService.getSavedJobs();
      final counts = {'Applied': 0, 'Interview': 0, 'Offer': 0, 'Rejected': 0};
      for (final job in jobs) {
        final status = job['status'] ?? 'Applied';
        counts[status] = (counts[status] ?? 0) + 1;
      }
      if (mounted) setState(() => _stageCounts = counts);
    } catch (_) {
      // Stats are a nice-to-have on Home; fail quietly and keep zeros
      // rather than blocking the screen with an error state.
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String get _greetingName {
    final email = supabase.auth.currentUser?.email ?? '';
    final namePart = email.split('@').first;
    if (namePart.isEmpty) return 'there';
    return namePart[0].toUpperCase() + namePart.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final totalApplied = _stageCounts.values.fold(0, (a, b) => a + b);

    return Scaffold(
      appBar: AppBar(title: const Text('JobHero')),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.pine,
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Text('Welcome back, $_greetingName',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 6),
              Text(
                'Ready to find your next role?',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              _QuickSearchCard(
                onTap: () => MainShell.of(context)?.goToTab(1),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Text(
                    'YOUR PIPELINE',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                      color: AppColors.stone,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => MainShell.of(context)?.goToTab(2),
                    child: const Text('View tracker', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: CircularProgressIndicator(color: AppColors.pine),
                  ),
                )
              else if (totalApplied == 0)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.sand),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.dashboard_outlined, color: AppColors.stone, size: 28),
                      const SizedBox(height: 10),
                      Text(
                        'Save a job to start tracking your applications.',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                Row(
                  children: [
                    _StatChip(label: 'Applied', count: _stageCounts['Applied']!, color: AppColors.stone),
                    const SizedBox(width: 8),
                    _StatChip(label: 'Interview', count: _stageCounts['Interview']!, color: const Color(0xFF2563A8)),
                    const SizedBox(width: 8),
                    _StatChip(label: 'Offer', count: _stageCounts['Offer']!, color: AppColors.pine),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickSearchCard extends StatelessWidget {
  final VoidCallback onTap;
  const _QuickSearchCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.pine,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.search_rounded, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Search for jobs',
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                  SizedBox(height: 2),
                  Text('Find live listings and see your match score',
                      style: TextStyle(
                          fontFamily: 'Inter', fontSize: 12, color: Color(0xFFE3ECE8))),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatChip({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.sand),
        ),
        child: Column(
          children: [
            Text('$count',
                style: TextStyle(
                    fontFamily: 'Fraunces', fontSize: 22, fontWeight: FontWeight.w600, color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.stone)),
          ],
        ),
      ),
    );
  }
}