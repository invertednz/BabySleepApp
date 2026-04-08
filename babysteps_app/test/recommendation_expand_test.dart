import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';

import 'package:babysteps_app/screens/home_screen.dart';
import 'package:babysteps_app/providers/auth_provider.dart';
import 'package:babysteps_app/providers/baby_provider.dart';
import 'package:babysteps_app/models/baby.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

// ---------------------------------------------------------------------------
// Fakes - minimal implementations to render HomeScreen
// ---------------------------------------------------------------------------

class _FakeAuthProvider extends ChangeNotifier implements AuthProvider {
  @override
  bool get isPaidUser => true;
  @override
  bool get isOnTrial => false;
  @override
  bool get isLoggedIn => true;
  @override
  bool get isLoading => false;
  @override
  String? get error => null;
  @override
  bool get needsEmailConfirmation => false;
  @override
  supabase.User? get user => null;
  @override
  DateTime? get planStartedAt => null;
  @override
  String get planTier => 'paid';
  @override
  Future<bool> signUp({required String email, required String password}) async => true;
  @override
  Future<bool> signIn({required String email, required String password}) async => true;
  @override
  Future<void> initialize() async {}
  @override
  Future<void> signOut() async {}
  @override
  Future<bool> signInWithGoogle({String? redirectUrl}) async => false;
  @override
  Future<bool> signInWithApple({String? redirectUrl}) async => false;
  @override
  Future<void> applyPendingPlanUpgradeIfAny() async {}
  @override
  void updatePlanStatus({required bool isPaid, required bool isOnTrial, DateTime? planStartedAt}) {}
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeBabyProvider extends ChangeNotifier implements BabyProvider {
  @override
  List<Baby> get babies => [];
  @override
  Baby? get selectedBaby => null;
  @override
  bool get isLoading => false;
  @override
  Future<int> getUserStreak() async => 5;
  @override
  Future<List<Map<String, dynamic>>> getMilestoneAssessmentsForBaby(String babyId, {bool includeDiscounted = false}) async => [];
  @override
  Future<Map<String, dynamic>?> generateWeeklyAdvicePlan({bool forceRefresh = false}) async => null;
  @override
  Future<bool> hasPendingOnboardingData() async => false;
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('Recommendation cards expand/collapse', () {
    late _FakeAuthProvider fakeAuth;
    late _FakeBabyProvider fakeBaby;

    setUp(() {
      fakeAuth = _FakeAuthProvider();
      fakeBaby = _FakeBabyProvider();
    });

    Future<void> pumpHomeScreen(WidgetTester tester) async {
      // Use a large viewport to avoid overflow issues
      tester.view.physicalSize = const Size(400, 1200);
      tester.view.devicePixelRatio = 1.0;

      // Suppress overflow errors from test viewport
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.toString().contains('overflowed')) return;
        originalOnError?.call(details);
      };

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        FlutterError.onError = originalOnError;
      });

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: fakeAuth),
            ChangeNotifierProvider<BabyProvider>.value(value: fakeBaby),
          ],
          child: const MaterialApp(home: HomeScreen(showBottomNav: false)),
        ),
      );
      // Allow async loads (streak, milestones, advice) to complete
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
    }

    testWidgets('recommendation cards are visible with chevron-down icon', (WidgetTester tester) async {
      await pumpHomeScreen(tester);

      // The featured recommendations should be visible (from RecommendationService)
      // Look for the Recommendations header
      expect(find.text('Recommendations'), findsOneWidget);

      // Should show chevron-down icons (collapsed state) for each recommendation
      expect(find.byIcon(FeatherIcons.chevronDown), findsWidgets);
      // Should not show chevron-up icons yet (nothing expanded)
      expect(find.byIcon(FeatherIcons.chevronUp), findsNothing);
      // Should not show "Read full article" link yet
      expect(find.text('Read full article'), findsNothing);
    });

    testWidgets('tapping a recommendation card expands it', (WidgetTester tester) async {
      await pumpHomeScreen(tester);

      // Find the first recommendation card title - "Tummy Time" is the first featured
      // (activity category comes first in getFeaturedRecommendations)
      final firstCardTitle = find.text('Tummy Time');
      expect(firstCardTitle, findsOneWidget);

      // Tap on the recommendation card to expand it
      await tester.tap(firstCardTitle);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250)); // wait for animation

      // After expansion: should show at least one chevron-up icon
      expect(find.byIcon(FeatherIcons.chevronUp), findsOneWidget);
      // Should show "Read full article" link
      expect(find.text('Read full article'), findsOneWidget);
    });

    testWidgets('tapping an expanded recommendation card collapses it', (WidgetTester tester) async {
      await pumpHomeScreen(tester);

      final firstCardTitle = find.text('Tummy Time');
      expect(firstCardTitle, findsOneWidget);

      // Tap to expand
      await tester.tap(firstCardTitle);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      // Verify expanded
      expect(find.text('Read full article'), findsOneWidget);
      expect(find.byIcon(FeatherIcons.chevronUp), findsOneWidget);

      // Tap again to collapse
      await tester.tap(firstCardTitle);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      // Verify collapsed
      expect(find.text('Read full article'), findsNothing);
      expect(find.byIcon(FeatherIcons.chevronUp), findsNothing);
    });

    testWidgets('dismiss button still works on recommendation cards', (WidgetTester tester) async {
      await pumpHomeScreen(tester);

      final firstCardTitle = find.text('Tummy Time');
      expect(firstCardTitle, findsOneWidget);

      // Find the dismiss (close) button tooltips
      final dismissButtons = find.byTooltip('Dismiss');
      expect(dismissButtons, findsWidgets);

      // Tap the first dismiss button
      await tester.tap(dismissButtons.first);
      await tester.pump();

      // The "Tummy Time" card should be dismissed (gone)
      expect(find.text('Tummy Time'), findsNothing);
    });
  });
}
