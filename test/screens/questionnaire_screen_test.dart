import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roommate_finder/models/answer_set.dart';
import 'package:roommate_finder/screens/questionnaire/questionnaire_screen.dart';
import 'package:roommate_finder/services/mock/mock_questionnaire_service.dart';
import 'package:roommate_finder/utils/app_routes.dart';
import 'package:roommate_finder/utils/app_theme.dart';

import '../helpers/test_data.dart';

void main() {
  Future<void> pumpScreen(
    WidgetTester tester, {
    AnswerSet? saved,
    Size size = const Size(360, 640),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final service = MockQuestionnaireService(
      bundle: FileAssetBundle(),
      delay: Duration.zero,
      initialAnswers: saved,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: QuestionnaireScreen(service: service),
        routes: {
          AppRoutes.dealbreakers: (_) =>
              const Scaffold(body: Text('Dealbreakers page')),
        },
      ),
    );
    await tester.pumpAndSettle();
  }

  FilledButton nextButton(WidgetTester tester) =>
      tester.widget(find.widgetWithText(FilledButton, 'Next'));

  testWidgets('first page shows the sleep section and progress', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.text('Sleep schedule'), findsOneWidget);
    expect(find.text('Section 1 of 8'), findsOneWidget);
    expect(find.text('Back'), findsNothing);
    expect(nextButton(tester).onPressed, isNull);
  });

  testWidgets('Next unlocks once every question is answered', (tester) async {
    await pumpScreen(tester);

    for (final label in [
      'Before 23:00',
      'Before 08:00',
      'Asleep for a while already',
    ]) {
      await tester.ensureVisible(find.text(label));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label));
      await tester.pump();
    }
    expect(nextButton(tester).onPressed, isNotNull);

    await tester.tap(find.widgetWithText(FilledButton, 'Next'));
    await tester.pumpAndSettle();
    expect(find.text('Cleanliness'), findsOneWidget);
    expect(find.text('Section 2 of 8'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Back'));
    await tester.pumpAndSettle();
    expect(find.text('Sleep schedule'), findsOneWidget);
    expect(nextButton(tester).onPressed, isNotNull);
  });

  testWidgets('Save draft confirms with a message', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Save draft'));
    await tester.pumpAndSettle();

    expect(find.text('Draft saved'), findsOneWidget);
  });

  testWidgets('saved answers are filled in and the last page opens '
      'Dealbreakers', (tester) async {
    await pumpScreen(tester, saved: AnswerSet(answers: firstOptionAnswers()));

    for (var page = 1; page <= 8; page++) {
      expect(find.text('Section $page of 8'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Next'));
      await tester.pumpAndSettle();
    }

    expect(find.text('Dealbreakers page'), findsOneWidget);
  });

  testWidgets('no overflow on a large phone', (tester) async {
    await pumpScreen(tester, size: const Size(430, 932));

    expect(find.text('Sleep schedule'), findsOneWidget);
  });
}
