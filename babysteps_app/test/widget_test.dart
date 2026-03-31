import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:babysteps_app/screens/onboarding_baby_screen.dart';
import 'package:babysteps_app/screens/onboarding_parent_concerns_screen.dart';
import 'package:babysteps_app/screens/onboarding_thank_you_screen.dart';
import 'package:babysteps_app/screens/login_screen.dart';
import 'package:babysteps_app/providers/auth_provider.dart';
import 'package:babysteps_app/providers/baby_provider.dart';
import 'package:babysteps_app/models/baby.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _FakeAuthAutoconfirm extends ChangeNotifier implements AuthProvider {
  bool signUpCalled = false;
  String? signUpEmail;

  @override
  Future<bool> signUp({required String email, required String password}) async {
    signUpCalled = true;
    signUpEmail = email;
    return true; // autoconfirm: session exists
  }

  @override
  bool get needsEmailConfirmation => false;
  @override
  String? get error => null;
  @override
  bool get isLoading => false;
  @override
  bool get isLoggedIn => false;
  @override
  supabase.User? get user => null;
  @override
  bool get isPaidUser => false;
  @override
  bool get isOnTrial => false;
  @override
  DateTime? get planStartedAt => null;
  @override
  String get planTier => 'free';
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

class _FakeAuthNeedsConfirmation extends _FakeAuthAutoconfirm {
  bool _needsConfirmation = false;

  @override
  Future<bool> signUp({required String email, required String password}) async {
    signUpCalled = true;
    signUpEmail = email;
    _needsConfirmation = true;
    notifyListeners();
    return false; // no session
  }

  @override
  bool get needsEmailConfirmation => _needsConfirmation;
}

class _FakeBabyProvider extends ChangeNotifier implements BabyProvider {
  @override
  Future<bool> hasPendingOnboardingData() async => true; // Go to AppContainer, not SplashScreen
  @override
  Future<bool> persistPendingOnboardingData() async => true;
  @override
  List<Baby> get babies => [];
  @override
  Baby? get selectedBaby => null;
  @override
  bool get isLoading => false;
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  testWidgets('OnboardingBabyScreen shows birthday prompt', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: OnboardingBabyScreen()));
    await tester.pump();
    expect(find.text('When was your baby born?'), findsOneWidget);
    expect(find.text('Select Date'), findsOneWidget);
  });

  testWidgets('OnboardingParentConcernsScreen shows header', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: OnboardingParentConcernsScreen()));
    await tester.pump();
    expect(find.text('What keeps you'), findsOneWidget);
    expect(find.text('up at night?'), findsOneWidget);
  });

  testWidgets('OnboardingThankYouScreen shows continue button', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: OnboardingThankYouScreen()));
    await tester.pump();
    expect(find.text('Thank You for\nTrusting Us'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Leave a Review'), findsOneWidget);
  });

  group('Sign-up flow', () {
    late _FakeBabyProvider fakeBaby;

    setUp(() {
      fakeBaby = _FakeBabyProvider();
    });

    Future<void> fillAndSubmitSignUp(WidgetTester tester) async {
      await tester.enterText(find.byType(TextFormField).at(0), 'test@gmail.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      await tester.enterText(find.byType(TextFormField).at(2), 'password123');
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -300));
      await tester.pump();
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      await tester.tap(find.text('Sign Up with Email'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    }

    testWidgets('autoconfirm: signUp called, no confirmation dialog shown', (WidgetTester tester) async {
      final fakeAuth = _FakeAuthAutoconfirm();

      tester.view.physicalSize = const Size(400, 1200);
      tester.view.devicePixelRatio = 1.0;

      // Suppress overflow errors from AppContainer rendering in narrow test viewport
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
          child: const MaterialApp(home: LoginScreen(initialIsLoginView: false)),
        ),
      );
      await tester.pump();
      expect(find.text('Create Account'), findsOneWidget);

      await fillAndSubmitSignUp(tester);

      // signUp was called with correct email
      expect(fakeAuth.signUpCalled, isTrue);
      expect(fakeAuth.signUpEmail, 'test@gmail.com');

      // No email confirmation dialog (autoconfirm means straight to app)
      expect(find.text('Check Your Email'), findsNothing);
    });

    testWidgets('no autoconfirm: shows email confirmation dialog with correct email', (WidgetTester tester) async {
      final fakeAuth = _FakeAuthNeedsConfirmation();

      tester.view.physicalSize = const Size(400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: fakeAuth),
            ChangeNotifierProvider<BabyProvider>.value(value: fakeBaby),
          ],
          child: const MaterialApp(home: LoginScreen(initialIsLoginView: false)),
        ),
      );
      await tester.pump();

      await fillAndSubmitSignUp(tester);

      // signUp was called
      expect(fakeAuth.signUpCalled, isTrue);

      // Email confirmation dialog appears with the user's email
      expect(find.text('Check Your Email'), findsOneWidget);
      expect(find.textContaining('test@gmail.com'), findsWidgets);
      expect(find.text('Got It'), findsOneWidget);

      // Tap "Got It" - should dismiss dialog and switch to login view
      await tester.tap(find.text('Got It'));
      await tester.pumpAndSettle();

      // Dialog dismissed
      expect(find.text('Check Your Email'), findsNothing);
      // Now on login view (not sign-up)
      expect(find.text('Welcome Back!'), findsOneWidget);
    });
  });
}
