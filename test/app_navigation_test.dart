import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roommate_finder/app.dart';
import 'package:roommate_finder/models/answer_set.dart';
import 'package:roommate_finder/screens/matches/matches_screen.dart';
import 'package:roommate_finder/services/app_services.dart';
import 'package:roommate_finder/services/mock/mock_match_service.dart';
import 'package:roommate_finder/services/mock/mock_questionnaire_service.dart';

import 'helpers/test_data.dart';

void main() {
  setUp(() {
    // The questionnaire starts fully answered, so the sign-up flow can tap
    // straight through its pages.
    AppServices.questionnaire = MockQuestionnaireService(
      bundle: FileAssetBundle(),
      delay: Duration.zero,
      initialAnswers: AnswerSet(answers: firstOptionAnswers()),
    );
    AppServices.matches = MockMatchService(delay: Duration.zero);
  });

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
    expect(find.byType(MatchesScreen), findsOneWidget);

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
      // One Next per questionnaire section (8), then Dealbreakers.
      'Next', 'Next', 'Next', 'Next', 'Next', 'Next', 'Next', 'Next',
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
