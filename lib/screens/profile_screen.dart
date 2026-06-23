import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final userId = supabase.auth.currentUser!.id;
      final data = await supabase.from('profiles').select().eq('user_id', userId).single();
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

  String get _email => supabase.auth.currentUser?.email ?? '';
  String get _initials {
    final name = _email.split('@').first;
    final parts = name.split('.');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.length >= 2 ? name.substring(0, 2).toUpperCase() : name.toUpperCase();
  }

  Color _expAvatarColor(String company) {
    final colors = [0xFF6366F1, 0xFF3B82F6, 0xFF14B8A6, 0xFF16A34A, 0xFFDC2626];
    return Color(colors[company.hashCode % colors.length]);
  }

  @override
  Widget build(BuildContext context) {
    final sans = GoogleFonts.inter().fontFamily!;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.green))
            : _error != null
                ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(onPressed: _load, child: const Text('Retry')),
                  ]))
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                    children: [
                      // Header row
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('Profile', style: TextStyle(fontFamily: sans, fontSize: 28,
                            fontWeight: FontWeight.w800, color: AppColors.ink)),
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Icon(Icons.edit_outlined, size: 16, color: AppColors.muted),
                        ),
                      ]),
                      const SizedBox(height: 16),

                      // User card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(children: [
                          Container(
                            width: 52, height: 52,
                            decoration: BoxDecoration(
                              color: AppColors.terminalBg,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(child: Text(_initials,
                                style: TextStyle(fontFamily: sans, fontSize: 18,
                                    fontWeight: FontWeight.w800, color: AppColors.green))),
                          ),
                          const SizedBox(width: 14),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(_email.split('@').first.replaceAll('.', ' ')
                                .split(' ').map((w) => w.isEmpty ? '' :
                                  w[0].toUpperCase() + w.substring(1)).join(' '),
                                style: TextStyle(fontFamily: sans, fontSize: 17,
                                    fontWeight: FontWeight.w700, color: AppColors.ink)),
                            Text(_experience.isNotEmpty
                                ? (_experience[0] as Map)['title'] ?? '' : 'Software Engineer',
                                style: TextStyle(fontFamily: sans, fontSize: 13, color: AppColors.muted)),
                            Text(_email, style: TextStyle(fontFamily: sans,
                                fontSize: 12, color: AppColors.placeholder)),
                          ])),
                        ]),
                      ),
                      const SizedBox(height: 24),

                      // CV Analysis
                      Text('CV ANALYSIS', style: TextStyle(fontFamily: sans, fontSize: 11,
                          fontWeight: FontWeight.w600, color: AppColors.muted, letterSpacing: 0.5)),
                      const SizedBox(height: 1),
                      const Divider(color: AppColors.divider),
                      const SizedBox(height: 14),

                      if (_skills.isNotEmpty) ...[
                        Text('SKILLS', style: TextStyle(fontFamily: sans, fontSize: 11,
                            fontWeight: FontWeight.w600, color: AppColors.muted, letterSpacing: 0.5)),
                        const SizedBox(height: 10),
                        Wrap(spacing: 8, runSpacing: 8,
                            children: _skills.map((s) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: AppColors.greenLight,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.green, width: 1),
                              ),
                              child: Text(s.toString(), style: TextStyle(fontFamily: sans,
                                  fontSize: 13, color: AppColors.green,
                                  fontWeight: FontWeight.w500)),
                            )).toList()),
                        const SizedBox(height: 24),
                      ],

                      if (_experience.isNotEmpty) ...[
                        Text('EXPERIENCE', style: TextStyle(fontFamily: sans, fontSize: 11,
                            fontWeight: FontWeight.w600, color: AppColors.muted, letterSpacing: 0.5)),
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            children: _experience.asMap().entries.map((entry) {
                              final i = entry.key;
                              final exp = entry.value as Map<String, dynamic>;
                              final company = exp['company'] ?? '';
                              final isLast = i == _experience.length - 1;
                              return Column(children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                    Container(
                                      width: 38, height: 38,
                                      decoration: BoxDecoration(
                                        color: _expAvatarColor(company),
                                        borderRadius: BorderRadius.circular(10)),
                                      child: Center(child: Text(
                                        company.isNotEmpty ? company[0].toUpperCase() : '?',
                                        style: const TextStyle(fontFamily: 'Inter',
                                            fontSize: 14, fontWeight: FontWeight.w700,
                                            color: Colors.white))),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                      Text(company, style: TextStyle(fontFamily: sans,
                                          fontSize: 14, fontWeight: FontWeight.w700,
                                          color: AppColors.ink), maxLines: 2,
                                          overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 2),
                                      Text(exp['title'] ?? '', style: TextStyle(
                                          fontFamily: sans, fontSize: 12, color: AppColors.muted)),
                                      const SizedBox(height: 2),
                                      Text('${exp['start'] ?? ''} – ${exp['end'] ?? ''}',
                                          style: TextStyle(fontFamily: sans,
                                              fontSize: 12, color: AppColors.placeholder)),
                                    ])),
                                  ]),
                                ),
                                if (!isLast) const Divider(height: 1, color: AppColors.divider),
                              ]);
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Settings rows
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(children: [
                          ...[
                            'Notification Preferences',
                            'CV Preferences',
                            'Linked Accounts',
                          ].asMap().entries.map((entry) {
                            final isLast = entry.key == 2;
                            return Column(children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                child: Row(children: [
                                  Text(entry.value, style: TextStyle(fontFamily: sans,
                                      fontSize: 15, fontWeight: FontWeight.w600,
                                      color: AppColors.ink)),
                                  const Spacer(),
                                  const Icon(Icons.chevron_right_rounded,
                                      size: 20, color: AppColors.muted),
                                ]),
                              ),
                              if (!isLast) const Divider(height: 1, color: AppColors.divider),
                            ]);
                          }),
                        ]),
                      ),
                      const SizedBox(height: 16),

                      // Sign out
                      GestureDetector(
                        onTap: () => supabase.auth.signOut(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: AppColors.dangerLight,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            const Icon(Icons.logout_rounded, size: 18, color: AppColors.danger),
                            const SizedBox(width: 10),
                            Text('Sign Out', style: TextStyle(fontFamily: sans,
                                fontSize: 15, fontWeight: FontWeight.w700,
                                color: AppColors.danger)),
                          ]),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Center(child: Text('JobHero v2.1.0 · Made with care',
                          style: TextStyle(fontFamily: sans, fontSize: 12,
                              color: AppColors.placeholder))),
                    ],
                  ),
      ),
    );
  }
}