import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roommate_finder/screens/auth/sign_up_screen.dart';
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
        home: const SignUpScreen(),
        onGenerateRoute: (settings) => MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Text('${settings.name} ${settings.arguments ?? ''}'),
          ),
        ),
      ),
    );
  }

  Future<void> fillForm(
    WidgetTester tester, {
    String email = 'bassam@sabanciuniv.edu',
    String password = 'secret123',
    String confirm = 'secret123',
    bool acceptTerms = true,
  }) async {
    await tester.enterText(find.byKey(const ValueKey('signUpEmail')), email);
    await tester.enterText(
      find.byKey(const ValueKey('signUpPassword')),
      password,
    );
    await tester.enterText(
      find.byKey(const ValueKey('signUpConfirm')),
      confirm,
    );
    if (acceptTerms) {
      await tester.ensureVisible(find.byKey(const ValueKey('signUpTerms')));
      await tester.tap(find.byKey(const ValueKey('signUpTerms')));
    }
    await tester.pump();
  }

  Future<void> tapCreate(WidgetTester tester) async {
    final button = find.widgetWithText(FilledButton, 'Create account');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  testWidgets('empty submit shows an inline error under every field', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tapCreate(tester);

    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
    expect(find.text('Please confirm your password'), findsOneWidget);
    expect(
      find.text('You must accept the terms to create an account'),
      findsOneWidget,
    );
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('rejects a non-university email and mismatched passwords', (
    tester,
  ) async {
    await pumpScreen(tester);
    await fillForm(
      tester,
      email: 'someone@gmail.com',
      password: 'short',
      confirm: 'different',
    );

    await tapCreate(tester);

    expect(
      find.text('Use your university email (@sabanciuniv.edu)'),
      findsOneWidget,
    );
    expect(find.text('Password must be at least 8 characters'), findsOneWidget);
    expect(find.text('Passwords do not match'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('errors update as the user fixes a field', (tester) async {
    await pumpScreen(tester);
    await tapCreate(tester);
    expect(find.text('Email is required'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('signUpEmail')),
      'bassam@sabanciuniv.edu',
    );
    await tester.pump();

    expect(find.text('Email is required'), findsNothing);
  });

  testWidgets('valid form shows the confirmation dialog, then Verify email', (
    tester,
  ) async {
    await pumpScreen(tester);
    await fillForm(tester);

    await tapCreate(tester);
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.textContaining('bassam@sabanciuniv.edu'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Confirm'));
    await tester.pumpAndSettle();

    expect(
      find.text('${AppRoutes.verifyEmail} bassam@sabanciuniv.edu'),
      findsOneWidget,
    );
  });

  testWidgets('Edit email closes the dialog and stays on the form', (
    tester,
  ) async {
    await pumpScreen(tester);
    await fillForm(tester);
    await tapCreate(tester);

    await tester.tap(find.text('Edit email'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Create your account'), findsOneWidget);
  });

  testWidgets('no overflow on a large phone with every error showing', (
    tester,
  ) async {
    await pumpScreen(tester, size: const Size(430, 932));
    await tapCreate(tester);

    expect(find.text('Email is required'), findsOneWidget);
  });
}
