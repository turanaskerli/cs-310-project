import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roommate_finder/app.dart';

void main() {
  testWidgets('Welcome -> Log in -> main tabs, and tabs switch', (
    tester,
  ) async {
    await tester.pumpWidget(const RoommateFinderApp());
    expect(find.text('Welcome'), findsWidgets);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Log in'));
    await tester.pumpAndSettle();
    expect(find.text('Forgot password?'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Open a match'), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Edit profile'), findsOneWidget);
  });

  testWidgets('Sign-up flow reaches the main tabs', (tester) async {
    await tester.pumpWidget(const RoommateFinderApp());
    const steps = [
      'Sign up',
      'Create account',
      "I've verified",
      'Agree',
      'Continue',
      'Start',
      'Next',
      'Next',
      'Submit',
    ];
    for (final label in steps) {
      await tester.tap(find.widgetWithText(FilledButton, label));
      await tester.pumpAndSettle();
    }
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
