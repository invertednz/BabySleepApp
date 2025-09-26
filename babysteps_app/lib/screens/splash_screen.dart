import 'package:flutter/material.dart';
import 'package:babysteps_app/providers/baby_provider.dart';
import 'package:babysteps_app/screens/app_container.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:babysteps_app/screens/login_screen.dart';
import 'package:babysteps_app/screens/onboarding_baby_screen.dart';
import 'package:babysteps_app/screens/onboarding_gender_screen.dart';
import 'package:babysteps_app/screens/onboarding_milestones_screen.dart';
import 'package:babysteps_app/screens/onboarding_concerns_screen.dart';
import 'package:babysteps_app/screens/onboarding_nurture_priorities_screen.dart';
import 'package:babysteps_app/screens/onboarding_short_term_focus_screen.dart';
import 'package:babysteps_app/screens/onboarding_parenting_style_screen.dart';
import 'package:babysteps_app/screens/onboarding_nurture_global_screen.dart';
import 'package:babysteps_app/screens/onboarding_goals_screen.dart';
import 'package:babysteps_app/screens/onboarding_activities_loves_hates_screen.dart';

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
      // User is logged in, evaluate onboarding status based on baby data
      final babyProvider = provider.Provider.of<BabyProvider>(context, listen: false);
      await babyProvider.initialize();

      if (!mounted) return;

      final babies = babyProvider.babies;
      // Global steps first
      // 0) Parenting Style (global, multi)
      final prefs = await babyProvider.getUserPreferences();
      final parentingStyles = List<String>.from(prefs['parenting_styles'] ?? <String>[]);
      if (parentingStyles.isEmpty) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => OnboardingParentingStyleScreen(babies: const [])),
        );
        return;
      }

      // 1) Nurture (global, multi)
      final nurtureGlobals = List<String>.from(prefs['nurture_priorities'] ?? <String>[]);
      if (nurtureGlobals.isEmpty) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const OnboardingNurtureGlobalScreen()),
        );
        return;
      }

      // 2) Goals (global, multi)
      final goals = List<String>.from(prefs['goals'] ?? <String>[]);
      if (goals.isEmpty) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const OnboardingGoalsScreen()),
        );
        return;
      }

      // 3) Add Baby if none exist
      if (babies.isEmpty) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const OnboardingBabyScreen()),
        );
        return;
      }

      // Per-baby steps
      // 4) Concerns: require at least 1 concern across all babies
      bool hasAnyConcern = false;
      for (final b in babies) {
        babyProvider.selectBaby(b.id);
        final concerns = await babyProvider.getConcerns();
        if (concerns.isNotEmpty) { hasAnyConcern = true; break; }
      }
      if (!hasAnyConcern) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => OnboardingConcernsScreen(babies: babies)),
        );
        return;
      }

      // 5) Gender
      final needsGender = babies.any((b) => (b.gender == null || b.gender!.isEmpty));
      if (needsGender) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => OnboardingGenderScreen(babies: babies)),
        );
        return;
      }

      // 6) Milestones: if any baby has no completed milestones, go to milestones
      // 6) Activities Loves & Hates: require at least one selection across loves/hates for each baby
      bool needsActivities = false;
      for (final b in babies) {
        final map = await babyProvider.getBabyActivities(babyId: b.id);
        final loves = map['loves'] ?? <String>[];
        final hates = map['hates'] ?? <String>[];
        if (loves.isEmpty && hates.isEmpty) { needsActivities = true; break; }
      }
      if (needsActivities) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => OnboardingActivitiesLovesHatesScreen(babies: babies)),
        );
        return;
      }

      // 7) Milestones: if any baby has no completed milestones, go to milestones
      final needsMilestones = babies.any((b) => (b.completedMilestones.isEmpty));
      if (needsMilestones) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => OnboardingMilestonesScreen(babies: babies)),
        );
        return;
      }

      // 8) Short-Term Focus (after milestones)
      bool needsFocus = false;
      for (final b in babies) {
        final items = await babyProvider.getShortTermFocus(babyId: b.id);
        if (items.isEmpty) { needsFocus = true; break; }
      }
      if (needsFocus) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => OnboardingShortTermFocusScreen(babies: babies)),
        );
        return;
      }

      // All onboarding steps complete: go to main app (start on home page)
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AppContainer(initialIndex: 4)),
      );
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
