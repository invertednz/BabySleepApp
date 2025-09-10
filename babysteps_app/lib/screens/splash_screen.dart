import 'package:flutter/material.dart';
import 'package:babysteps_app/providers/baby_provider.dart';
import 'package:babysteps_app/screens/app_container.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:babysteps_app/screens/login_screen.dart';
import 'package:babysteps_app/screens/onboarding_baby_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _redirect();
  }

  Future<void> _redirect() async {
    // Wait for the widget to be fully built before navigating
    await Future.delayed(Duration.zero);

    if (!mounted) return;

    final session = Supabase.instance.client.auth.currentSession;

    if (session != null) {
      // User is logged in, check for babies to determine onboarding status
      final babyProvider = provider.Provider.of<BabyProvider>(context, listen: false);
      await babyProvider.initialize();

      if (!mounted) return;

      if (babyProvider.babies.isNotEmpty) {
        // Onboarding complete
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AppContainer()),
        );
      } else {
        // Onboarding not complete
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const OnboardingBabyScreen()),
        );
      }
    } else {
      // User is not logged in
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
