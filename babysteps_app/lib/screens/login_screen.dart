import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:babysteps_app/theme/app_theme.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:babysteps_app/screens/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:babysteps_app/providers/auth_provider.dart';
import 'package:babysteps_app/providers/baby_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoginView = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _toggleView() {
    setState(() {
      _isLoginView = !_isLoginView;
      _formKey.currentState?.reset();
    });
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final babyProvider = Provider.of<BabyProvider>(context, listen: false);
      bool success = false;
      String? errorMessage;

      try {
        if (_isLoginView) {
          success = await authProvider.signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
        } else {
          success = await authProvider.signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
        }

        if (success) {
          // After login or sign up, redirect to splash screen which handles onboarding flow
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const SplashScreen()),
          );
        } else {
          errorMessage = authProvider.error ?? (_isLoginView ? 'Login failed' : 'Sign up failed');
        }
      } catch (e) {
        errorMessage = e.toString();
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
        }
      }
    }
  }

  void _signInWithGoogle() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      // TODO: Implement Google Sign-In with Supabase
      print('Sign in with Google');
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google Sign-In Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _signInWithApple() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      // TODO: Implement Apple Sign-In with Supabase
      print('Sign in with Apple');
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Apple Sign-In Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine if we should show Apple sign-in (only on native iOS/macOS, not on web)
    final platform = Theme.of(context).platform;
    final showApple = !kIsWeb && (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                // Logo Placeholder
                const Icon(FeatherIcons.sunrise, size: 60, color: AppTheme.primaryPurple),
                const SizedBox(height: 16),
                Text(
                  _isLoginView ? 'Welcome Back!' : 'Create Account',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 8),
                Text(
                  _isLoginView ? 'Log in to continue' : 'Sign up to get started',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 40),
                _buildEmailField(),
                const SizedBox(height: 16),
                _buildPasswordField(),
                if (!_isLoginView) ...[
                  const SizedBox(height: 16),
                  _buildConfirmPasswordField(),
                ],
                const SizedBox(height: 16),
                if (_isLoginView)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () { /* TODO: Implement Forgot Password */ },
                      child: const Text('Forgot Password?', style: TextStyle(color: AppTheme.primaryPurple)),
                    ),
                  ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryPurple,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _isLoginView ? 'Log In' : 'Sign Up',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
                const SizedBox(height: 24),
                _buildDivider(),
                const SizedBox(height: 24),
                _buildSocialLoginButton(
                  icon: FontAwesomeIcons.google,
                  text: 'Continue with Google',
                  onPressed: _signInWithGoogle,
                ),
                if (showApple) ...[
                  const SizedBox(height: 16),
                  _buildSocialLoginButton(
                    icon: FontAwesomeIcons.apple,
                    text: 'Continue with Apple',
                    onPressed: _signInWithApple,
                    isApple: true,
                  ),
                ],
                const SizedBox(height: 32),
                _buildBottomText(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      decoration: const InputDecoration(labelText: 'Email'),
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value == null || value.isEmpty || !value.contains('@')) {
          return 'Please enter a valid email';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        labelText: 'Password',
        suffixIcon: IconButton(
          icon: Icon(_obscurePassword ? FeatherIcons.eyeOff : FeatherIcons.eye),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty || value.length < 6) {
          return 'Password must be at least 6 characters';
        }
        return null;
      },
    );
  }

  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: _confirmPasswordController,
      obscureText: _obscureConfirmPassword,
      decoration: InputDecoration(
        labelText: 'Confirm Password',
        suffixIcon: IconButton(
          icon: Icon(_obscureConfirmPassword ? FeatherIcons.eyeOff : FeatherIcons.eye),
          onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
        ),
      ),
      validator: (value) {
        if (value != _passwordController.text) {
          return 'Passwords do not match';
        }
        return null;
      },
    );
  }

  Widget _buildDivider() {
    return const Row(
      children: [
        Expanded(child: Divider(thickness: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text('OR', style: TextStyle(color: AppTheme.textSecondary)),
        ),
        Expanded(child: Divider(thickness: 1)),
      ],
    );
  }

  Widget _buildSocialLoginButton({
    required IconData icon,
    required String text,
    required VoidCallback onPressed,
    bool isApple = false,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: isApple ? Colors.white : AppTheme.textPrimary),
      label: Text(text, style: TextStyle(color: isApple ? Colors.white : AppTheme.textPrimary)),
      style: OutlinedButton.styleFrom(
        backgroundColor: isApple ? Colors.black : Colors.white,
        foregroundColor: isApple ? Colors.white : AppTheme.textPrimary,
        side: const BorderSide(color: Color(0xFFE2E8F0)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildBottomText() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 4,
        children: [
          Text(
            _isLoginView ? 'Don\'t have an account? ' : 'Already have an account? ',
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
          TextButton(
            onPressed: _toggleView,
            child: Text(
              _isLoginView ? 'Sign Up' : 'Log In',
              style: const TextStyle(color: AppTheme.primaryPurple, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
