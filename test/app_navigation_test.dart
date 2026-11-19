import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roommate_finder/app.dart';
import 'package:roommate_finder/models/answer_set.dart';
import 'package:roommate_finder/screens/matches/matches_screen.dart';
import 'package:roommate_finder/services/app_services.dart';
import 'package:roommate_finder/services/mock/mock_connection_service.dart';
import 'package:roommate_finder/services/mock/mock_match_service.dart';
import 'package:roommate_finder/services/mock/mock_questionnaire_service.dart';
import 'package:roommate_finder/services/mock/mock_user_service.dart';

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
    AppServices.connections = MockConnectionService(delay: Duration.zero);
    AppServices.users = MockUserService(delay: Duration.zero);
  });

  testWidgets('Welcome -> Log in -> main tabs, and tabs switch', (
    tester,
  ) async {
    await tester.pumpWidget(const RoommateFinderApp());
    expect(find.text('Roommate Finder'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Log in'));
    await tester.pumpAndSettle();
    expect(find.text('Forgot password?'), findsOneWidget);

    // Log in now validates the form, so fill it in first.
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'murad@sabanciuniv.edu');
    await tester.enterText(fields.at(1), 'password123');
    await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(MatchesScreen), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Edit profile'), findsOneWidget);
  });

  testWidgets('Sign-up flow reaches the main tabs', (tester) async {
    AppServices.users = MockUserService(delay: Duration.zero, startEmpty: true);
    await tester.pumpWidget(const RoommateFinderApp());

    Future<void> tapFilled(String label) async {
      final button = find.widgetWithText(FilledButton, label);
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
    }

    Future<void> choose(String key, String option) async {
      await tester.ensureVisible(find.byKey(ValueKey(key)));
      await tester.tap(find.byKey(ValueKey(key)));
      await tester.pumpAndSettle();
      await tester.tap(find.text(option).last);
      await tester.pumpAndSettle();
    }

    // Sign up: the form must be valid before the confirmation dialog.
    await tapFilled('Sign up');
    await tester.enterText(
      find.byKey(const ValueKey('signUpEmail')),
      'new.student@sabanciuniv.edu',
    );
    await tester.enterText(
      find.byKey(const ValueKey('signUpPassword')),
      'secret123',
    );
    await tester.enterText(
      find.byKey(const ValueKey('signUpConfirm')),
      'secret123',
    );
    await tester.ensureVisible(find.byKey(const ValueKey('signUpTerms')));
    await tester.tap(find.byKey(const ValueKey('signUpTerms')));
    await tester.pump();
    await tapFilled('Create account');
    await tapFilled('Confirm');

    await tapFilled("I've verified");
    await tapFilled('Agree');

    // Basic profile: fill every required field.
    await tester.enterText(
      find.byKey(const ValueKey('profileName')),
      'New Student',
    );
    await choose('profileGender', 'Female');
    await choose('profileProgram', 'Economics');
    await choose('profileYear', 'Year 1');
    await tester.enterText(
      find.byKey(const ValueKey('profileStudentId')),
      '34567',
    );
    await tapFilled('Continue');

    const steps = [
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
    // Review asks before submitting.
    await tester.tap(find.widgetWithText(TextButton, 'Submit'));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
