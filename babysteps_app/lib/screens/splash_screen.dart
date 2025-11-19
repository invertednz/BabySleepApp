import 'package:flutter/material.dart';
import 'package:babysteps_app/providers/baby_provider.dart';
import 'package:babysteps_app/screens/app_container.dart';
import 'package:provider/provider.dart' as provider;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:babysteps_app/screens/login_screen.dart';
import 'package:babysteps_app/screens/onboarding_welcome_screen.dart';
import 'package:babysteps_app/screens/onboarding_baby_screen.dart';
import 'package:babysteps_app/screens/onboarding_gender_screen.dart';
import 'package:babysteps_app/screens/onboarding_milestones_screen.dart';
import 'package:babysteps_app/screens/onboarding_short_term_focus_screen.dart';
import 'package:babysteps_app/screens/onboarding_parenting_style_screen.dart';
import 'package:babysteps_app/screens/onboarding_nurture_global_screen.dart';
import 'package:babysteps_app/screens/onboarding_app_tour_screen.dart';
import 'package:babysteps_app/screens/onboarding_activities_loves_hates_screen.dart';
import 'package:babysteps_app/screens/onboarding_progress_preview_screen.dart';
import 'package:babysteps_app/providers/milestone_provider.dart';

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
      // User is logged in, ensure core data is loaded (babies + milestones)
      final babyProvider = provider.Provider.of<BabyProvider>(context, listen: false);
      final milestoneProvider = provider.Provider.of<MilestoneProvider>(context, listen: false);

      // Load babies and, importantly, reload milestones now that we have an authenticated session.
      // The initial MilestoneProvider.loadMilestones() call in main() may have run before auth
      // and been blocked by RLS, leaving the list empty.
      await babyProvider.initialize();
      await milestoneProvider.loadMilestones();

      if (!mounted) return;

      final prefs = await babyProvider.getUserPreferences();
      final babies = babyProvider.babies;

      // Check if user has seen welcome (use notification_time as proxy for new onboarding flow)
      final notificationTime = prefs['notification_time'] as String?;
      if (notificationTime == null || notificationTime.isEmpty) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const OnboardingWelcomeScreen()),
        );
        return;
      }

      // Check parenting styles (comes after notifications in new flow)
      final parentingStyles = List<String>.from(prefs['parenting_styles'] ?? <String>[]);
      if (parentingStyles.isEmpty) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => OnboardingParentingStyleScreen(babies: const [])),
        );
        return;
      }

      // Check nurture priorities
      final nurtureGlobals = List<String>.from(prefs['nurture_priorities'] ?? <String>[]);
      if (nurtureGlobals.isEmpty) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const OnboardingNurtureGlobalScreen()),
        );
        return;
      }

      // Check if they've seen the app tour (use baby existence as proxy)
      if (babies.isEmpty) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const OnboardingAppTourScreen()),
        );
        return;
      }

      // Check gender
      final needsGender = babies.any((b) => (b.gender == null || b.gender!.isEmpty));
      if (needsGender) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => OnboardingGenderScreen(babies: babies)),
        );
        return;
      }

      // Check activities
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

      // Check milestones
      final needsMilestones = babies.any((b) => (b.completedMilestones.isEmpty));
      if (needsMilestones) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => OnboardingMilestonesScreen(babies: babies)),
        );
        return;
      }

      // Check short-term focus
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

      // Show progress preview screen (Your Journey Starts Now)
      final planTier = prefs['plan_tier'] as String?;
      if (planTier == null || planTier.isEmpty) {
        final milestoneProvider = provider.Provider.of<MilestoneProvider>(context, listen: false);
        final currentBaby = babies.isNotEmpty ? babies.first : null;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => OnboardingProgressPreviewScreen(
            baby: currentBaby,
            milestones: milestoneProvider.milestones,
          )),
        );
        return;
      }

      // All onboarding complete: go to main app
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AppContainer(initialIndex: 2)),
      );
    } else {
      // User is not logged in
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const OnboardingWelcomeScreen()),
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
