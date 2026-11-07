import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roommate_finder/screens/matches/matches_screen.dart';
import 'package:roommate_finder/services/mock/mock_match_service.dart';
import 'package:roommate_finder/utils/app_routes.dart';
import 'package:roommate_finder/utils/app_theme.dart';

void main() {
  late MockMatchService service;

  setUp(() => service = MockMatchService(delay: Duration.zero));
  tearDown(() => service.dispose());

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
        home: MatchesScreen(service: service),
        routes: {
          AppRoutes.matchDetail: (context) => Scaffold(
            body: Text(
              'Detail for ${ModalRoute.of(context)!.settings.arguments.runtimeType}',
            ),
          ),
        },
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the best match first with score and reasons', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(
      find.text('10 suggested roommates, best match first'),
      findsOneWidget,
    );
    expect(find.text('Deniz Yılmaz'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);
    expect(find.text('You keep similar sleep hours'), findsWidgets);
  });

  testWidgets('tapping ✕ removes the card', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byTooltip('Hide').first);
    await tester.pumpAndSettle();

    expect(find.text('Deniz Yılmaz'), findsNothing);
    expect(
      find.text('9 suggested roommates, best match first'),
      findsOneWidget,
    );
    expect(
      find.text('Deniz Yılmaz is hidden from your matches'),
      findsOneWidget,
    );
  });

  testWidgets('swiping a card removes it', (tester) async {
    await pumpScreen(tester);

    await tester.drag(find.text('Deniz Yılmaz'), const Offset(-600, 0));
    await tester.pumpAndSettle();

    expect(find.text('Deniz Yılmaz'), findsNothing);
    expect(find.text('Elif Kaya'), findsOneWidget);
  });

  testWidgets('View profile opens Match detail with the match', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.widgetWithText(OutlinedButton, 'View profile').first);
    await tester.pumpAndSettle();

    expect(find.text('Detail for Recommendation'), findsOneWidget);
  });

  testWidgets('empty state when every match is hidden', (tester) async {
    for (final id in [
      'mock_deniz',
      'mock_elif',
      'mock_mehmet',
      'mock_zeynep',
      'mock_can',
      'mock_aylin',
      'mock_emre',
      'mock_selin',
      'mock_lukas',
      'mock_burak',
    ]) {
      await service.dismiss(id);
    }
    await pumpScreen(tester);

    expect(find.text('No matches left'), findsOneWidget);
  });

  testWidgets('no overflow on a large phone', (tester) async {
    await pumpScreen(tester, size: const Size(430, 932));

    expect(find.text('Deniz Yılmaz'), findsOneWidget);
  });
}
