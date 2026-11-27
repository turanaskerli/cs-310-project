import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roommate_finder/models/answer_set.dart';
import 'package:roommate_finder/screens/questionnaire/dealbreakers_screen.dart';
import 'package:roommate_finder/services/mock/mock_questionnaire_service.dart';
import 'package:roommate_finder/utils/app_routes.dart';
import 'package:roommate_finder/utils/app_theme.dart';

import '../helpers/test_data.dart';

void main() {
  late MockQuestionnaireService service;

  setUp(
    () => service = MockQuestionnaireService(
      bundle: FileAssetBundle(),
      delay: Duration.zero,
    ),
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
        home: DealbreakersScreen(service: service),
        routes: {
          AppRoutes.reviewSubmit: (_) =>
              const Scaffold(body: Text('Review page')),
        },
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Scrolls the list until [finder] is built and on screen, then taps it.
  /// The list only builds the cards that are visible.
  Future<void> scrollAndTap(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pump();
  }

  Future<void> tapText(WidgetTester tester, String text) =>
      scrollAndTap(tester, find.text(text));

  /// Taps [option] inside the card of the question that starts with [question].
  Future<void> answer(WidgetTester tester, String question, String option) =>
      scrollAndTap(
        tester,
        find.descendant(
          of: find.ancestor(
            of: find.textContaining(question),
            matching: find.byType(Card),
          ),
          matching: find.text(option),
        ),
      );

  /// What the service has stored. The mock waits on a timer, so this runs
  /// outside the test's fake clock.
  Future<AnswerSet?> savedAnswers(WidgetTester tester) =>
      tester.runAsync<AnswerSet?>(service.getMyAnswers);

  FilledButton nextButton(WidgetTester tester) =>
      tester.widget(find.widgetWithText(FilledButton, 'Next'));

  /// Answers "No" / "Never" to the three required attribute questions.
  Future<void> answerAttributes(WidgetTester tester) async {
    await answer(tester, 'Do you smoke', 'No');
    await answer(tester, 'Do you use a vape', 'No');
    await answer(tester, 'How often would you have a guest', 'Never');
  }

  testWidgets('shows the last section and starts locked', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Dealbreakers'), findsOneWidget);
    expect(find.text('Section 9 of 9'), findsOneWidget);
    expect(nextButton(tester).onPressed, isNull);
  });

  testWidgets('"None of these" completes the page and clears other choices', (
    tester,
  ) async {
    await pumpScreen(tester);
    await answerAttributes(tester);
    expect(nextButton(tester).onPressed, isNull);

    await tapText(tester, 'A roommate who smokes');
    expect(nextButton(tester).onPressed, isNotNull);

    await tapText(tester, 'None of these');
    final smokes = tester.widget<Icon>(
      find
          .descendant(
            of: find.ancestor(
              of: find.text('A roommate who smokes'),
              matching: find.byType(Row),
            ),
            matching: find.byType(Icon),
          )
          .first,
    );
    expect(smokes.icon, Icons.check_box_outline_blank);
    expect(nextButton(tester).onPressed, isNotNull);
  });

  testWidgets('Next saves and opens Review and submit', (tester) async {
    await pumpScreen(tester);
    await answerAttributes(tester);
    await tapText(tester, 'A roommate who vapes');

    await tester.tap(find.widgetWithText(FilledButton, 'Next'));
    await tester.pumpAndSettle();

    expect(find.text('Review page'), findsOneWidget);
  });

  testWidgets('choices are saved when the screen closes', (tester) async {
    await pumpScreen(tester);
    await answer(tester, 'Do you smoke', 'No');
    await tapText(tester, 'A roommate who vapes');

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();

    final saved = await savedAnswers(tester);
    expect(saved!.isDraft, isTrue);
    expect(saved.answers.keys, ['db_smoke']);
    expect(saved.dealbreakers, ['vaping']);
  });

  testWidgets('saved choices are filled in again', (tester) async {
    await tester.runAsync(
      () => service.saveDraft({'db_smoke': 0}, dealbreakers: ['smoking']),
    );
    await pumpScreen(tester);

    await tester.scrollUntilVisible(
      find.text('A roommate who smokes'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    final smokes = tester.widget<Icon>(
      find
          .descendant(
            of: find.ancestor(
              of: find.text('A roommate who smokes'),
              matching: find.byType(Row),
            ),
            matching: find.byType(Icon),
          )
          .first,
    );
    expect(smokes.icon, isNot(Icons.check_box_outline_blank));
  });

  testWidgets('no overflow on a large phone', (tester) async {
    await pumpScreen(tester, size: const Size(430, 932));

    expect(find.text('Section 9 of 9'), findsOneWidget);
  });
}
