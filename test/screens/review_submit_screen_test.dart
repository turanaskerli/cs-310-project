import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roommate_finder/models/answer_set.dart';
import 'package:roommate_finder/screens/questionnaire/review_submit_screen.dart';
import 'package:roommate_finder/services/mock/mock_questionnaire_service.dart';
import 'package:roommate_finder/utils/app_routes.dart';
import 'package:roommate_finder/utils/app_theme.dart';

import '../helpers/test_data.dart';

void main() {
  late MockQuestionnaireService service;

  void createService(AnswerSet? answers) => service = MockQuestionnaireService(
    bundle: FileAssetBundle(),
    delay: Duration.zero,
    initialAnswers: answers,
  );

  Future<void> pumpScreen(
    WidgetTester tester, {
    Size size = const Size(360, 640),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: ReviewSubmitScreen(service: service),
        onGenerateRoute: (settings) => MaterialPageRoute(
          settings: settings,
          builder: (_) => Scaffold(body: Text('route ${settings.name}')),
        ),
      ),
    );
    // The question bank is read from disk, outside the fake clock.
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
  }

  FilledButton submitButton(WidgetTester tester) =>
      tester.widget(find.widgetWithText(FilledButton, 'Submit'));

  testWidgets('shows every section with its answers', (tester) async {
    createService(
      AnswerSet(answers: firstOptionAnswers(), dealbreakers: const ['smoking']),
    );
    await pumpScreen(tester);

    expect(find.text('Sleep schedule'), findsOneWidget);
    expect(find.text('Not answered'), findsNothing);
    expect(submitButton(tester).onPressed, isNotNull);

    await tester.scrollUntilVisible(find.text('Dealbreakers'), 300);
    expect(find.textContaining('Edit'), findsWidgets);
  });

  testWidgets('Submit confirms, saves the final answers and opens home', (
    tester,
  ) async {
    createService(AnswerSet(answers: firstOptionAnswers()));
    await pumpScreen(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Submit'));
    await tester.pumpAndSettle();
    expect(find.text('Submit your answers?'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Submit'));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();

    expect(find.text('route ${AppRoutes.home}'), findsOneWidget);
    final saved = await tester.runAsync(service.getMyAnswers);
    expect(saved!.isDraft, isFalse);
  });

  testWidgets('Keep reviewing leaves the answers as a draft', (tester) async {
    createService(AnswerSet(answers: firstOptionAnswers()));
    await pumpScreen(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Submit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keep reviewing'));
    await tester.pumpAndSettle();

    expect(find.byType(ReviewSubmitScreen), findsOneWidget);
    final saved = await tester.runAsync(service.getMyAnswers);
    expect(saved!.isDraft, isTrue);
  });

  testWidgets('missing answers are marked and block Submit', (tester) async {
    final answers = firstOptionAnswers()..remove('sleep_1');
    createService(AnswerSet(answers: answers));
    await pumpScreen(tester);

    expect(find.text('Not answered'), findsOneWidget);
    expect(find.textContaining('not answered yet'), findsOneWidget);
    expect(submitButton(tester).onPressed, isNull);
  });

  testWidgets('Edit opens the questionnaire', (tester) async {
    createService(AnswerSet(answers: firstOptionAnswers()));
    await pumpScreen(tester);

    await tester.tap(find.bySemanticsLabel('Edit Sleep schedule'));
    await tester.pumpAndSettle();

    expect(find.text('route ${AppRoutes.questionnaire}'), findsOneWidget);
  });

  testWidgets('fits a small phone', (tester) async {
    createService(AnswerSet(answers: firstOptionAnswers()));
    await pumpScreen(tester, size: const Size(320, 568));
    expect(tester.takeException(), isNull);
  });
}
