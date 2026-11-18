import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roommate_finder/screens/auth/verify_email_screen.dart';
import 'package:roommate_finder/screens/onboarding/consent_screen.dart';
import 'package:roommate_finder/utils/app_routes.dart';
import 'package:roommate_finder/utils/app_theme.dart';

void main() {
  /// Opens [screen] as a pushed route (so it can receive an argument), with
  /// every other route showing its own name.
  Future<void> pumpRoute(
    WidgetTester tester,
    Widget screen, {
    Object? argument,
    Size size = const Size(360, 640),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        initialRoute: '/screen',
        onGenerateRoute: (settings) => MaterialPageRoute(
          settings: RouteSettings(
            name: settings.name,
            arguments: settings.name == '/screen' ? argument : null,
          ),
          builder: (_) => settings.name == '/screen'
              ? screen
              : Scaffold(body: Text('route ${settings.name}')),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('VerifyEmailScreen', () {
    testWidgets('shows the email from Sign up', (tester) async {
      await pumpRoute(
        tester,
        const VerifyEmailScreen(),
        argument: 'bassam@sabanciuniv.edu',
      );

      expect(find.text('Check your inbox'), findsOneWidget);
      expect(
        find.textContaining('bassam@sabanciuniv.edu', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('Resend shows a confirmation message', (tester) async {
      await pumpRoute(
        tester,
        const VerifyEmailScreen(),
        argument: 'bassam@sabanciuniv.edu',
      );

      await tester.tap(find.widgetWithText(OutlinedButton, 'Resend email'));
      await tester.pump();

      expect(
        find.text('We sent a new link to bassam@sabanciuniv.edu'),
        findsOneWidget,
      );
    });

    testWidgets("I've verified opens Consent", (tester) async {
      await pumpRoute(tester, const VerifyEmailScreen());

      await tester.tap(find.widgetWithText(FilledButton, "I've verified"));
      await tester.pumpAndSettle();

      expect(find.text('route ${AppRoutes.consent}'), findsOneWidget);
    });

    testWidgets('no overflow on a large phone', (tester) async {
      await pumpRoute(
        tester,
        const VerifyEmailScreen(),
        size: const Size(430, 932),
      );

      expect(find.text('Check your inbox'), findsOneWidget);
    });
  });

  group('ConsentScreen', () {
    testWidgets('explains what is collected and who sees it', (tester) async {
      await pumpRoute(tester, const ConsentScreen());

      expect(find.text('What we collect'), findsOneWidget);
      expect(find.text('Who sees your profile'), findsOneWidget);
    });

    testWidgets('Agree opens Basic profile', (tester) async {
      await pumpRoute(tester, const ConsentScreen());

      await tester.tap(find.widgetWithText(FilledButton, 'Agree'));
      await tester.pumpAndSettle();

      expect(find.text('route ${AppRoutes.basicProfile}'), findsOneWidget);
    });

    testWidgets('Not now returns to Welcome', (tester) async {
      await pumpRoute(tester, const ConsentScreen());

      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();

      expect(find.text('route ${AppRoutes.welcome}'), findsOneWidget);
    });

    testWidgets('no overflow on a large phone', (tester) async {
      await pumpRoute(
        tester,
        const ConsentScreen(),
        size: const Size(430, 932),
      );

      expect(find.text('Agree'), findsOneWidget);
    });
  });
}
