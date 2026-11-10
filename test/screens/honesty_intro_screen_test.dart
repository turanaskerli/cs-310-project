import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roommate_finder/screens/questionnaire/honesty_intro_screen.dart';
import 'package:roommate_finder/utils/app_routes.dart';
import 'package:roommate_finder/utils/app_theme.dart';

void main() {
  Future<void> pumpScreen(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const HonestyIntroScreen(),
        routes: {
          AppRoutes.questionnaire: (_) =>
              const Scaffold(body: Text('Questionnaire page')),
        },
      ),
    );
  }

  testWidgets('explains honest answers and lists the three points', (
    tester,
  ) async {
    await pumpScreen(tester, const Size(360, 640));

    expect(find.text('Be honest, get better matches'), findsOneWidget);
    expect(find.textContaining('9 short sections'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsNWidgets(4));
  });

  testWidgets('Start opens the questionnaire', (tester) async {
    await pumpScreen(tester, const Size(360, 640));

    await tester.tap(find.widgetWithText(FilledButton, 'Start'));
    await tester.pumpAndSettle();

    expect(find.text('Questionnaire page'), findsOneWidget);
  });

  testWidgets('no overflow on a large phone', (tester) async {
    await pumpScreen(tester, const Size(430, 932));

    expect(find.text('Start'), findsOneWidget);
  });
}
