import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../theme/app_theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  // Disposable demo account for people trying the app / giving feedback.
  // Safe to be public: RLS scopes it to its own rows only.
  static const _demoEmail = 'demo@jobhero.app';
  static const _demoPassword = 'DemoUser2026!';

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;
  bool _isDemoLoading = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Enter your email and password to continue.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (_isLogin) {
        await supabase.auth.signInWithPassword(email: email, password: password);
      } else {
        await supabase.auth.signUp(email: email, password: password);
      }
      // AuthGate listens for the state change and routes from here.
    } catch (e) {
      setState(() => _error = 'Couldn\'t sign you in — check your details and try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _demoLogin() async {
    setState(() {
      _isDemoLoading = true;
      _error = null;
    });
    try {
      final res = await supabase.auth.signInWithPassword(
          email: _demoEmail, password: _demoPassword);
      debugPrint('Demo login: session=${res.session != null}, user=${res.user?.id}');
    } catch (e) {
      debugPrint('Demo login error: $e');
      setState(() => _error = 'Demo error: $e');
    } finally {
      if (mounted) setState(() => _isDemoLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = _isLoading || _isDemoLoading;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.pineLight,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.work_outline_rounded,
                      color: AppColors.pine, size: 28),
                ),
                const SizedBox(height: 24),
                Text('JobHero',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 30)),
                const SizedBox(height: 6),
                Text(
                  'Your AI-powered career agent',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.mail_outline, size: 20),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        size: 20,
                        color: AppColors.stone,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  obscureText: _obscurePassword,
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 20),
                if (_error != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.emberLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, size: 18, color: AppColors.ember),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_error!,
                              style: const TextStyle(color: AppColors.ember, fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                FilledButton(
                  onPressed: busy ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.paper),
                        )
                      : Text(_isLogin ? 'Log in' : 'Create account'),
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: busy
                        ? null
                        : () => setState(() {
                              _isLogin = !_isLogin;
                              _error = null;
                            }),
                    child: Text(
                      _isLogin ? "Don't have an account? Sign up" : 'Already have an account? Log in',
                      style: const TextStyle(color: AppColors.stone, fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Expanded(child: Divider(color: AppColors.sand)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('or',
                          style: const TextStyle(color: AppColors.stone, fontSize: 12)),
                    ),
                    const Expanded(child: Divider(color: AppColors.sand)),
                  ],
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: busy ? null : _demoLogin,
                  icon: _isDemoLoading
                      ? const SizedBox(
                          height: 18, width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.play_circle_outline_rounded, size: 20),
                  label: Text(_isDemoLoading ? 'Starting demo...' : 'Try the demo'),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    'No sign-up needed — explore with sample data',
                    style: const TextStyle(color: AppColors.stone, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}