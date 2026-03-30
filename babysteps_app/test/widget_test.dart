// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:babysteps_app/screens/onboarding_baby_screen.dart';
import 'package:babysteps_app/screens/onboarding_parent_concerns_screen.dart';
import 'package:babysteps_app/screens/onboarding_thank_you_screen.dart';

void main() {
  testWidgets('OnboardingBabyScreen shows birthday prompt', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: OnboardingBabyScreen()),
    );
    await tester.pump();

    expect(find.text('When was your baby born?'), findsOneWidget);
    expect(find.text('Select Date'), findsOneWidget);
  });

  testWidgets('OnboardingParentConcernsScreen shows header', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: OnboardingParentConcernsScreen()),
    );
    await tester.pump();

    expect(find.text('What keeps you'), findsOneWidget);
    expect(find.text('up at night?'), findsOneWidget);
  });

  testWidgets('OnboardingThankYouScreen shows continue button', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: OnboardingThankYouScreen()),
    );
    await tester.pump();

    expect(find.text('Thank You for\nTrusting Us'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Leave a Review'), findsOneWidget);
  });
}
