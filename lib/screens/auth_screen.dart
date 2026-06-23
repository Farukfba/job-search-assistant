import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../theme/app_theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  static const _demoEmail = 'demo@jobhero.app';
  static const _demoPassword = 'DemoUser2026!';

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;
  bool _isDemoLoading = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please fill in all fields.');
      return;
    }
    setState(() { _isLoading = true; _error = null; });
    try {
      if (_isLogin) {
        await supabase.auth.signInWithPassword(email: email, password: password);
      } else {
        await supabase.auth.signUp(email: email, password: password);
      }
    } catch (e) {
      setState(() => _error = 'Couldn\'t sign you in — check your details and try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _demoLogin() async {
    setState(() { _isDemoLoading = true; _error = null; });
    try {
      await supabase.auth.signInWithPassword(email: _demoEmail, password: _demoPassword);
    } catch (e) {
      setState(() => _error = 'Couldn\'t start the demo — please try again.');
    } finally {
      if (mounted) setState(() => _isDemoLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sans = GoogleFonts.inter().fontFamily!;
    final busy = _isLoading || _isDemoLoading;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo
              Row(children: [
                Text('JH', style: TextStyle(fontFamily: sans, fontSize: 18,
                    fontWeight: FontWeight.w800, color: AppColors.green)),
                const SizedBox(width: 8),
                Text('JobHero', style: TextStyle(fontFamily: sans, fontSize: 18,
                    fontWeight: FontWeight.w700, color: AppColors.ink)),
              ]),
              const SizedBox(height: 32),
              // Title
              Text(_isLogin ? 'Welcome back' : 'Create account',
                  style: TextStyle(fontFamily: sans, fontSize: 32,
                      fontWeight: FontWeight.w800, color: AppColors.ink)),
              const SizedBox(height: 6),
              Text(_isLogin ? 'Sign in to your JobHero account' : 'Start tracking your job search',
                  style: TextStyle(fontFamily: sans, fontSize: 15, color: AppColors.muted)),
              const SizedBox(height: 32),

              // Fields
              if (!_isLogin) ...[
                _FieldLabel('FULL NAME', sans),
                const SizedBox(height: 6),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(hintText: 'Alex Chen'),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
              ],

              _FieldLabel('EMAIL', sans),
              const SizedBox(height: 6),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(hintText: 'alex@example.com'),
              ),
              const SizedBox(height: 16),

              _FieldLabel('PASSWORD', sans),
              const SizedBox(height: 6),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  hintText: 'Enter password',
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword
                        ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        size: 20, color: AppColors.muted),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.dangerLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline, size: 16, color: AppColors.danger),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error!,
                        style: TextStyle(fontFamily: sans, fontSize: 13, color: AppColors.danger))),
                  ]),
                ),
              ],

              FilledButton(
                onPressed: busy ? null : _submit,
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                    : Text(_isLogin ? 'Sign In' : 'Create Account'),
              ),

              const SizedBox(height: 16),
              if (_isLogin) ...[
                Center(
                  child: GestureDetector(
                    onTap: busy ? null : _demoLogin,
                    child: _isDemoLoading
                        ? const SizedBox(height: 18, width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.green))
                        : Text('Try Demo →',
                            style: TextStyle(fontFamily: sans, fontSize: 15,
                                fontWeight: FontWeight.w600, color: AppColors.ink)),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              Center(
                child: GestureDetector(
                  onTap: busy ? null : () => setState(() { _isLogin = !_isLogin; _error = null; }),
                  child: Text(
                    _isLogin ? 'Don\'t have an account? Sign up' : 'Already have an account? Sign in',
                    style: TextStyle(fontFamily: sans, fontSize: 15,
                        fontWeight: FontWeight.w600, color: AppColors.ink),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Center(
                child: Text('By continuing you agree to our Terms & Privacy Policy',
                    style: TextStyle(fontFamily: sans, fontSize: 12, color: AppColors.muted),
                    textAlign: TextAlign.center),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  final String sans;
  const _FieldLabel(this.text, this.sans);
  @override
  Widget build(BuildContext context) {
    return Text(text, style: TextStyle(fontFamily: sans, fontSize: 11,
        fontWeight: FontWeight.w600, color: AppColors.muted, letterSpacing: 0.5));
  }
}