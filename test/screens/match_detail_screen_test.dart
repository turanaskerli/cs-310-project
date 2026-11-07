import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roommate_finder/models/recommendation.dart';
import 'package:roommate_finder/screens/matches/match_detail_screen.dart';
import 'package:roommate_finder/services/mock/mock_match_service.dart';
import 'package:roommate_finder/utils/app_theme.dart';

void main() {
  late MockMatchService service;

  setUp(() => service = MockMatchService(delay: Duration.zero));
  tearDown(() => service.dispose());

  /// Opens Match detail the way the Matches screen does: as a route with the
  /// recommendation as its argument.
  Future<void> openDetail(
    WidgetTester tester,
    Object? argument, {
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
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                settings: RouteSettings(arguments: argument),
                builder: (_) => MatchDetailScreen(service: service),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<Recommendation> firstMatch() async =>
      (await service.watchRecommendations().first).first;

  testWidgets('shows the profile, score, reasons and comparison', (
    tester,
  ) async {
    final match = await tester.runAsync(firstMatch);
    await openDetail(tester, match);

    expect(find.text('Deniz Yılmaz'), findsOneWidget);
    expect(find.text('100% match'), findsOneWidget);
    expect(find.text('Why you match'), findsOneWidget);
    expect(find.text('You keep similar sleep hours'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('How you compare'), 200);
    expect(find.text('Sleep schedule'), findsOneWidget);
    expect(find.text('Deniz'), findsOneWidget);
  });

  testWidgets('Send request confirms with a message', (tester) async {
    final match = await tester.runAsync(firstMatch);
    await openDetail(tester, match);

    await tester.tap(find.widgetWithText(FilledButton, 'Send request'));
    await tester.pump();

    expect(find.text('Request sent to Deniz Yılmaz'), findsOneWidget);
  });

  testWidgets('without a match it shows a message instead of crashing', (
    tester,
  ) async {
    await openDetail(tester, null);

    expect(find.text('This match is no longer available.'), findsOneWidget);
  });

  testWidgets('no overflow on a large phone', (tester) async {
    final match = await tester.runAsync(firstMatch);
    await openDetail(tester, match, size: const Size(430, 932));

    expect(find.text('Send request'), findsOneWidget);
  });
}
