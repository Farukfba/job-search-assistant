import 'package:flutter/material.dart';
import '../main.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  String? _error;
  List<dynamic> _skills = [];
  List<dynamic> _experience = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final userId = supabase.auth.currentUser!.id;
      final data = await supabase
          .from('profiles')
          .select()
          .eq('user_id', userId)
          .single();
      setState(() {
        _skills = data['extracted_skills'] ?? [];
        _experience = data['extracted_experience'] ?? [];
      });
    } catch (e) {
      setState(() => _error = 'Couldn\'t load your profile — please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    await supabase.auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final email = supabase.auth.currentUser?.email ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.pine))
            : _error != null
                ? _ErrorState(message: _error!, onRetry: _load)
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: AppColors.pineLight,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.person_outline_rounded,
                                color: AppColors.pine, size: 26),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              email,
                              style: Theme.of(context).textTheme.titleMedium,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      const _SectionLabel('Skills'),
                      const SizedBox(height: 10),
                      if (_skills.isEmpty)
                        const Text('No skills extracted yet.',
                            style: TextStyle(fontFamily: 'Inter', color: AppColors.stone, fontSize: 13))
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _skills.map((s) => Chip(label: Text(s.toString()))).toList(),
                        ),
                      const SizedBox(height: 28),
                      const _SectionLabel('Experience'),
                      const SizedBox(height: 10),
                      if (_experience.isEmpty)
                        const Text('No experience extracted yet.',
                            style: TextStyle(fontFamily: 'Inter', color: AppColors.stone, fontSize: 13))
                      else
                        ..._experience.map((exp) {
                          final e = exp as Map<String, dynamic>;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(e['title'] ?? '',
                                      style: Theme.of(context).textTheme.titleMedium),
                                  const SizedBox(height: 2),
                                  Text('${e['company'] ?? ''}',
                                      style: const TextStyle(color: AppColors.pine, fontSize: 13)),
                                  const SizedBox(height: 2),
                                  Text('${e['start'] ?? ''} – ${e['end'] ?? ''}',
                                      style: const TextStyle(color: AppColors.stone, fontSize: 12)),
                                ],
                              ),
                            ),
                          );
                        }),
                      const SizedBox(height: 28),
                      OutlinedButton.icon(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout_rounded, size: 18),
                        label: const Text('Log out'),
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
            Text(message, textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: 'Inter', fontSize: 14)),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}