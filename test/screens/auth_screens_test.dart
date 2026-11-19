import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roommate_finder/app.dart';
import 'package:roommate_finder/screens/auth/welcome_screen.dart';
import 'package:roommate_finder/screens/home/main_shell.dart';
import 'package:roommate_finder/screens/home/not_found_screen.dart';
import 'package:roommate_finder/services/app_services.dart';
import 'package:roommate_finder/services/mock/mock_connection_service.dart';
import 'package:roommate_finder/services/mock/mock_match_service.dart';

void main() {
  setUp(() {
    AppServices.matches = MockMatchService(delay: Duration.zero);
    AppServices.connections = MockConnectionService(delay: Duration.zero);
  });

  /// Opens the Log in screen from Welcome.
  Future<void> openLogin(WidgetTester tester) async {
    await tester.pumpWidget(const RoommateFinderApp());
    await tester.tap(find.widgetWithText(OutlinedButton, 'Log in'));
    await tester.pumpAndSettle();
  }

  Finder field(int index) => find.byType(TextFormField).at(index);

  testWidgets('Welcome shows the local image and both buttons', (tester) async {
    await tester.pumpWidget(const RoommateFinderApp());
    final image = tester.widget<Image>(find.byType(Image));
    expect(
      (image.image as AssetImage).assetName,
      WelcomeScreen.illustrationAsset,
    );
    expect(find.text('Roommate Finder'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Sign up'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Log in'), findsOneWidget);
  });

  testWidgets('Log in shows inline errors and stays on the screen', (
    tester,
  ) async {
    await openLogin(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
    await tester.pumpAndSettle();
    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);

    await tester.enterText(field(0), 'murad@gmail.com');
    await tester.enterText(field(1), 'short');
    await tester.pumpAndSettle();
    expect(
      find.text('Use your university email (@sabanciuniv.edu)'),
      findsOneWidget,
    );
    expect(find.text('Password must be at least 8 characters'), findsOneWidget);
    expect(find.byType(MainShell), findsNothing);
  });

  testWidgets('Password can be shown and hidden', (tester) async {
    await openLogin(tester);
    EditableText passwordText() => tester.widget<EditableText>(
      find.descendant(of: field(1), matching: find.byType(EditableText)),
    );

    expect(passwordText().obscureText, isTrue);
    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();
    expect(passwordText().obscureText, isFalse);
  });

  testWidgets('Valid log in opens the main tabs and clears the history', (
    tester,
  ) async {
    await openLogin(tester);
    await tester.enterText(field(0), 'murad@sabanciuniv.edu');
    await tester.enterText(field(1), 'password123');
    await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.byType(MainShell), findsOneWidget);
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    expect(navigator.canPop(), isFalse);
  });

  testWidgets('Forgot password reuses the typed email and confirms', (
    tester,
  ) async {
    await openLogin(tester);
    await tester.enterText(field(0), 'murad@sabanciuniv.edu');
    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();

    expect(find.text('Reset your password'), findsOneWidget);
    expect(find.text('murad@sabanciuniv.edu'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Send reset link'));
    await tester.pumpAndSettle();
    expect(find.text('Check your inbox'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Back to log in'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('Back on another tab returns to Matches first', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MainShell()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chats'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      2,
    );

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      0,
    );
  });

  testWidgets('An unknown route shows Page not found', (tester) async {
    await tester.pumpWidget(const RoommateFinderApp());
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pushNamed('/does-not-exist');
    await tester.pumpAndSettle();
    expect(find.byType(NotFoundScreen), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Go to start'));
    await tester.pumpAndSettle();
    expect(find.byType(WelcomeScreen), findsOneWidget);
  });

  testWidgets('Auth screens fit a small 360x640 phone without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await openLogin(tester); // Welcome, then Log in
    await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
    await tester.pumpAndSettle(); // Log in with errors showing
    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
