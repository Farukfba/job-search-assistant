import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart';
import '../theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  void _next() {
    if (_page < 2) {
      _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    } else {
      _finish();
    }
  }

  void _finish() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthGate()), (route) => false);
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final sans = GoogleFonts.inter().fontFamily!;
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _controller,
              onPageChanged: (i) => setState(() => _page = i),
              children: [
                _Slide1(sans: sans),
                _Slide2(sans: sans),
                _Slide3(sans: sans),
              ],
            ),
          ),
          // Progress dots + CTA
          Container(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            color: AppColors.white,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _page == i ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _page == i ? AppColors.green : AppColors.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  )),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _next,
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(_page == 2 ? 'Get Started' : 'Continue',
                        style: TextStyle(fontFamily: sans, fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 18),
                  ]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SlideLabel extends StatelessWidget {
  final String text;
  const _SlideLabel(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(fontFamily: 'Inter', fontSize: 13,
            fontWeight: FontWeight.w700, color: AppColors.green, letterSpacing: 0.3));
  }
}

class _Slide1 extends StatelessWidget {
  final String sans;
  const _Slide1({required this.sans});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SlideLabel('JH · 01'),
            const SizedBox(height: 16),
            Text('Your career,\nscored.',
                style: TextStyle(fontFamily: sans, fontSize: 38,
                    fontWeight: FontWeight.w800, color: AppColors.ink, height: 1.1)),
            const SizedBox(height: 16),
            Text('AI that reads every job posting, scores your match, and tells you exactly where to improve.',
                style: TextStyle(fontFamily: sans, fontSize: 16,
                    color: AppColors.muted, height: 1.5)),
            const SizedBox(height: 32),
            // Feature card — shows what the AI actually analyzes
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF0F2419), // deep forest green, not black
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.green.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('JobHero AI · v2.1.0',
                          style: TextStyle(fontFamily: sans, fontSize: 11,
                              fontWeight: FontWeight.w600, color: AppColors.green)),
                    ),
                  ]),
                  const SizedBox(height: 20),
                  ...[ 
                    ['CV parsed', 'Skills & experience extracted'],
                    ['94 jobs scored', 'Matched against your profile'],
                    ['Cover letter ready', 'Tailored in seconds'],
                  ].map((row) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(children: [
                      Container(
                        width: 8, height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.green, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 12),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(row[0], style: TextStyle(fontFamily: sans, fontSize: 14,
                            fontWeight: FontWeight.w700, color: Colors.white)),
                        Text(row[1], style: TextStyle(fontFamily: sans, fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.5))),
                      ]),
                    ]),
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slide2 extends StatelessWidget {
  final String sans;
  const _Slide2({required this.sans});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SlideLabel('JH · 02'),
            const SizedBox(height: 16),
            Text('Instant CV\nanalysis.',
                style: TextStyle(fontFamily: sans, fontSize: 38,
                    fontWeight: FontWeight.w800, color: AppColors.ink, height: 1.1)),
            const SizedBox(height: 16),
            Text('Upload once. Get a match score for every role — skills, experience, location, keywords.',
                style: TextStyle(fontFamily: sans, fontSize: 16, color: AppColors.muted, height: 1.5)),
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('MATCH SCORE', style: TextStyle(fontFamily: sans, fontSize: 11,
                        fontWeight: FontWeight.w600, color: AppColors.muted, letterSpacing: 0.5)),
                    Text('↗ +12 pts', style: TextStyle(fontFamily: sans, fontSize: 12,
                        fontWeight: FontWeight.w600, color: AppColors.green)),
                  ]),
                  const SizedBox(height: 8),
                  RichText(text: TextSpan(
                    text: '94',
                    style: TextStyle(fontFamily: sans, fontSize: 48, fontWeight: FontWeight.w800,
                        color: AppColors.green),
                    children: [TextSpan(text: ' / 100',
                        style: TextStyle(fontSize: 18, color: AppColors.muted,
                            fontWeight: FontWeight.w400))],
                  )),
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.divider),
                  const SizedBox(height: 12),
                  ...[ ['SKILLS', 0.82, AppColors.green],
                       ['EXPERIENCE', 0.95, AppColors.green],
                       ['LOCATION', 1.0, AppColors.green],
                       ['KEYWORDS', 0.74, AppColors.scoreMid],
                  ].map((row) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text(row[0] as String, style: TextStyle(fontFamily: sans, fontSize: 11,
                            fontWeight: FontWeight.w600, color: AppColors.muted, letterSpacing: 0.5)),
                        Text('${((row[1] as double) * 100).toInt()}%',
                            style: TextStyle(fontFamily: sans, fontSize: 12,
                                fontWeight: FontWeight.w600, color: AppColors.ink)),
                      ]),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: row[1] as double,
                          minHeight: 6,
                          backgroundColor: AppColors.divider,
                          valueColor: AlwaysStoppedAnimation(row[2] as Color),
                        ),
                      ),
                    ]),
                  )),
                  const SizedBox(height: 4),
                  Text('vs. similar profiles on platform',
                      style: TextStyle(fontFamily: sans, fontSize: 12, color: AppColors.muted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slide3 extends StatelessWidget {
  final String sans;
  const _Slide3({required this.sans});

  static const _jobs = [
    {'initial': 'S', 'company': 'Stripe', 'role': 'Senior Frontend Engineer', 'score': 94, 'color': 0xFF6366F1},
    {'initial': 'L', 'company': 'Linear', 'role': 'Product Engineer', 'score': 87, 'color': 0xFF6366F1},
    {'initial': 'V', 'company': 'Vercel', 'role': 'Infrastructure Engineer', 'score': 72, 'color': 0xFF1C1C1C},
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SlideLabel('JH · 03'),
            const SizedBox(height: 16),
            Text('Ship your\napplication.',
                style: TextStyle(fontFamily: sans, fontSize: 38,
                    fontWeight: FontWeight.w800, color: AppColors.ink, height: 1.1)),
            const SizedBox(height: 16),
            Text('Cover letters, interview prep, and a tracker — everything you need to land the role.',
                style: TextStyle(fontFamily: sans, fontSize: 16, color: AppColors.muted, height: 1.5)),
            const SizedBox(height: 32),
            ..._jobs.map((job) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(children: [
                _CompanyAvatar(initial: job['initial'] as String, color: Color(job['color'] as int)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(job['company'] as String, style: TextStyle(fontFamily: sans, fontSize: 15,
                      fontWeight: FontWeight.w700, color: AppColors.ink)),
                  Text(job['role'] as String, style: TextStyle(fontFamily: sans, fontSize: 13,
                      color: AppColors.muted)),
                ])),
                _ScoreBadge(score: job['score'] as int),
              ]),
            )),
          ],
        ),
      ),
    );
  }
}

// Shared widgets used across screens
class _CompanyAvatar extends StatelessWidget {
  final String initial;
  final Color color;
  const _CompanyAvatar({required this.initial, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44, height: 44,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      child: Center(child: Text(initial,
          style: const TextStyle(fontFamily: 'Inter', fontSize: 16,
              fontWeight: FontWeight.w700, color: Colors.white))),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  final int score;
  const _ScoreBadge({required this.score});

  Color get _color {
    if (score >= 75) return AppColors.scoreHigh;
    if (score >= 50) return AppColors.scoreMid;
    return AppColors.scoreLow;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: _color, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text('$score',
          style: TextStyle(fontFamily: 'Inter', fontSize: 13,
              fontWeight: FontWeight.w700, color: _color)),
    );
  }
}