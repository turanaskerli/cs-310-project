import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roommate_finder/screens/settings/settings_screen.dart';
import 'package:roommate_finder/utils/app_routes.dart';
import 'package:roommate_finder/utils/app_theme.dart';

void main() {
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
        // Opened over another screen, as from Profile, so Welcome ('/') is
        // a separate route.
        initialRoute: AppRoutes.settings,
        onGenerateRoute: (settings) => MaterialPageRoute(
          settings: settings,
          builder: (_) => settings.name == AppRoutes.settings
              ? const SettingsScreen()
              : Scaffold(body: Text('route ${settings.name}')),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  bool switchValue(WidgetTester tester, String title) => tester
      .widget<SwitchListTile>(find.widgetWithText(SwitchListTile, title))
      .value;

  testWidgets('Hide my profile toggles and says so', (tester) async {
    await pumpScreen(tester);
    expect(switchValue(tester, 'Hide my profile'), isFalse);

    await tester.tap(find.text('Hide my profile'));
    await tester.pumpAndSettle();

    expect(switchValue(tester, 'Hide my profile'), isTrue);
    expect(
      find.text('Your profile is hidden from new matches'),
      findsOneWidget,
    );
  });

  testWidgets('notification switches start on and turn off', (tester) async {
    await pumpScreen(tester);
    expect(switchValue(tester, 'Messages'), isTrue);

    await tester.tap(find.text('Messages'));
    await tester.pumpAndSettle();

    expect(switchValue(tester, 'Messages'), isFalse);
    expect(switchValue(tester, 'Roommate requests'), isTrue);
  });

  testWidgets('a blocked student can be unblocked', (tester) async {
    await pumpScreen(tester);
    expect(find.text('1 student'), findsOneWidget);

    await tester.tap(find.text('Blocked users'));
    await tester.pumpAndSettle();
    expect(find.text('Emre Çelik'), findsOneWidget);

    await tester.tap(find.text('Unblock'));
    await tester.pumpAndSettle();
    expect(find.text("You haven't blocked anyone."), findsOneWidget);

    await tester.tapAt(const Offset(180, 20));
    await tester.pumpAndSettle();
    expect(find.text('Nobody blocked'), findsOneWidget);
  });

  testWidgets('Log out asks first, then returns to Welcome', (tester) async {
    await pumpScreen(tester);
    await tester.scrollUntilVisible(find.text('Log out'), 200);

    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();
    expect(find.text('Log out?'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Log out'));
    await tester.pumpAndSettle();
    expect(find.text('route ${AppRoutes.welcome}'), findsOneWidget);
  });

  testWidgets('Delete account needs DELETE typed exactly', (tester) async {
    await pumpScreen(tester);
    await tester.scrollUntilVisible(find.text('Delete account'), 200);

    await tester.tap(find.text('Delete account'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(
      find.text('Type DELETE in capital letters to confirm'),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextFormField), 'delete');
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'DELETE');
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(find.text('route ${AppRoutes.welcome}'), findsOneWidget);
  });

  testWidgets('Cancel keeps the account', (tester) async {
    await pumpScreen(tester);
    await tester.scrollUntilVisible(find.text('Delete account'), 200);
    await tester.tap(find.text('Delete account'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Delete your account?'), findsNothing);
    expect(find.byType(SettingsScreen), findsOneWidget);
  });

  testWidgets('fits a small phone', (tester) async {
    await pumpScreen(tester, size: const Size(320, 568));
    expect(tester.takeException(), isNull);
  });
}
