import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/auth_screen.dart';
import 'screens/cv_upload_screen.dart';
import 'screens/main_shell.dart';
import 'screens/onboarding_screen.dart';
import 'theme/app_theme.dart';

const _onboardingSeenKey = 'onboarding_seen';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://gcpehptjtojzauhlsmov.supabase.co',
    publishableKey: 'sb_publishable_A52KoaM3cRK3hM1CxElEYQ_LvUwEbor',
  );

  runApp(const ProviderScope(child: MyApp()));
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JobHero',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const StartupGate(),
    );
  }
}

/// A real splash screen shown the instant the app launches — no white
/// flash. Decides, once per fresh install, whether to show onboarding
/// before handing off to AuthGate.
class StartupGate extends StatefulWidget {
  const StartupGate({super.key});

  @override
  State<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<StartupGate> {
  bool? _onboardingSeen;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool(_onboardingSeenKey) ?? false;
    if (!seen) {
      await prefs.setBool(_onboardingSeenKey, true);
    }
    if (mounted) setState(() => _onboardingSeen = seen);
  }

  @override
  Widget build(BuildContext context) {
    if (_onboardingSeen == null) {
      return const _SplashScreen();
    }
    if (_onboardingSeen == false) {
      return const OnboardingScreen();
    }
    return const AuthGate();
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.pineLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.work_outline_rounded, color: AppColors.pine, size: 34),
            ),
            const SizedBox(height: 20),
            Text('JobHero', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 24),
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.pine),
            ),
          ],
        ),
      ),
    );
  }
}

/// AuthGate is the single source of truth for top-level navigation
/// once onboarding is done. It listens to auth state AND profile
/// existence, and decides whether to show AuthScreen, CvUploadScreen,
/// or MainShell. No screen should ever Navigator.push its way "out"
/// of this widget. Screens call back into AuthGate (via the
/// onProfileSaved callback) to signal a state change instead.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool? _hasProfile;
  String? _checkedForUserId;

  @override
  void initState() {
    super.initState();
    debugPrint('AuthGate initState — currentSession: ${supabase.auth.currentSession != null}');
  }

  Future<void> _checkProfile(String userId) async {
    if (_checkedForUserId == userId && _hasProfile != null) return;
    try {
      final data = await supabase
          .from('profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      if (mounted) {
        setState(() {
          _hasProfile = data != null;
          _checkedForUserId = userId;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _hasProfile = false;
          _checkedForUserId = userId;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        debugPrint(
            'AuthGate StreamBuilder rebuild — event: ${snapshot.data?.event}, hasSession: ${supabase.auth.currentSession != null}');
        final session = supabase.auth.currentSession;

        if (session == null) {
          _hasProfile = null;
          _checkedForUserId = null;
          return const AuthScreen();
        }

        final userId = session.user.id;

        if (_checkedForUserId != userId || _hasProfile == null) {
          _checkProfile(userId);
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (_hasProfile == true) {
          return const MainShell();
        }

        return CvUploadScreen(
          onProfileSaved: () => setState(() => _hasProfile = true),
        );
      },
    );
  }
}