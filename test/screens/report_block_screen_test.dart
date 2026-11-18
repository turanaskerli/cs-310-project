import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roommate_finder/models/recommendation.dart';
import 'package:roommate_finder/models/report.dart';
import 'package:roommate_finder/screens/matches/report_block_screen.dart';
import 'package:roommate_finder/services/mock/mock_report_service.dart';
import 'package:roommate_finder/utils/app_theme.dart';

void main() {
  late MockReportService service;
  Object? popped;

  const match = Recommendation(
    otherUid: 'mock_deniz',
    score: 92,
    reasons: ['You keep similar sleep hours'],
    otherSummary: OtherSummary(name: 'Deniz Yılmaz'),
  );

  setUp(() {
    service = MockReportService(delay: Duration.zero);
    popped = null;
  });
  tearDown(() => service.dispose());

  Future<void> openScreen(
    WidgetTester tester, {
    Object? argument = match,
    Size size = const Size(360, 640),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              popped = await Navigator.push<Object?>(
                context,
                MaterialPageRoute<Object?>(
                  settings: RouteSettings(arguments: argument),
                  builder: (_) => ReportBlockScreen(service: service),
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  /// Taps [finder], scrolling the form to it first if it is off screen.
  Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
    if (finder.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        finder,
        200,
        scrollable: find.byType(Scrollable).first,
      );
    }
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('lists every reason and needs one before submitting', (
    tester,
  ) async {
    await openScreen(tester);

    expect(find.text('Why are you reporting Deniz?'), findsOneWidget);
    final submit = find.widgetWithText(FilledButton, 'Submit report');
    expect(tester.widget<FilledButton>(submit).onPressed, isNull);

    await tapAndSettle(tester, find.text('Fake profile'));
    expect(tester.widget<FilledButton>(submit).onPressed, isNotNull);

    for (final reason in ReportReason.values) {
      await tester.scrollUntilVisible(
        find.text(reason.label),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(reason.label), findsOneWidget);
    }
  });

  testWidgets('report and block: confirm, success, returns the result', (
    tester,
  ) async {
    await openScreen(tester);

    await tapAndSettle(tester, find.text('Fake profile'));
    await tapAndSettle(
      tester,
      find.widgetWithText(FilledButton, 'Submit report'),
    );

    expect(find.text('Report Deniz?'), findsOneWidget);
    await tapAndSettle(tester, find.text('Report and block'));

    expect(find.text('Report sent and Deniz blocked'), findsOneWidget);
    expect(service.reports.single.reason, ReportReason.fakeProfile);
    expect(service.reports.single.blocked, isTrue);
    expect(await service.watchBlocked().first, {'mock_deniz'});

    await tapAndSettle(tester, find.text('Done'));
    expect(popped, ReportBlockResult.reportedAndBlocked);
  });

  testWidgets('"Something else" needs details', (tester) async {
    await openScreen(tester);

    await tapAndSettle(tester, find.text('Something else'));
    await tapAndSettle(tester, find.text('Also block Deniz'));
    await tapAndSettle(
      tester,
      find.widgetWithText(FilledButton, 'Submit report'),
    );

    expect(find.text('Tell us what happened'), findsWidgets);
    expect(find.text('Report Deniz?'), findsNothing);

    await tester.enterText(find.byType(TextFormField), 'Asked for my password');
    await tapAndSettle(
      tester,
      find.widgetWithText(FilledButton, 'Submit report'),
    );
    await tapAndSettle(tester, find.widgetWithText(TextButton, 'Report'));

    expect(find.text('Report sent'), findsOneWidget);
    expect(service.reports.single.details, 'Asked for my password');
    expect(service.reports.single.blocked, isFalse);
    expect(await service.watchBlocked().first, isEmpty);
  });

  testWidgets('cancelling the dialog sends nothing', (tester) async {
    await openScreen(tester);

    await tapAndSettle(tester, find.text('Spam or scam'));
    await tapAndSettle(
      tester,
      find.widgetWithText(FilledButton, 'Submit report'),
    );
    await tapAndSettle(tester, find.text('Cancel'));

    expect(service.reports, isEmpty);
    expect(find.text('Report Deniz?'), findsNothing);
    expect(find.text('Submit report'), findsOneWidget);
  });

  testWidgets('block without reporting', (tester) async {
    await openScreen(tester);

    await tapAndSettle(tester, find.text('Block without reporting'));
    expect(find.text('Block Deniz?'), findsOneWidget);
    await tapAndSettle(tester, find.widgetWithText(TextButton, 'Block'));

    expect(find.text('Deniz is blocked'), findsOneWidget);
    expect(service.reports, isEmpty);
    expect(await service.watchBlocked().first, {'mock_deniz'});

    await tapAndSettle(tester, find.text('Done'));
    expect(popped, ReportBlockResult.blocked);
  });

  testWidgets('without a student it shows a message instead of crashing', (
    tester,
  ) async {
    await openScreen(tester, argument: null);

    expect(find.text('This student is no longer available.'), findsOneWidget);
  });

  testWidgets('no overflow on a large phone', (tester) async {
    await openScreen(tester, size: const Size(430, 932));

    expect(find.text('Submit report'), findsOneWidget);
  });
}
