import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roommate_finder/screens/onboarding/basic_profile_screen.dart';
import 'package:roommate_finder/services/app_services.dart';
import 'package:roommate_finder/services/mock/mock_user_service.dart';
import 'package:roommate_finder/utils/app_routes.dart';
import 'package:roommate_finder/utils/app_theme.dart';

void main() {
  late MockUserService users;

  setUp(() {
    users = MockUserService(delay: Duration.zero);
    AppServices.users = users;
  });

  /// Starts on a page with an Open button that pushes Basic profile with
  /// [argument], so both sign-up mode and Edit profile mode can be tested.
  Future<void> pumpScreen(
    WidgetTester tester, {
    Object? argument,
    Size size = const Size(360, 640),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.pushNamed(
                  context,
                  AppRoutes.basicProfile,
                  arguments: argument,
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
        routes: {
          AppRoutes.basicProfile: (_) => const BasicProfileScreen(),
          AppRoutes.honestyIntro: (_) =>
              const Scaffold(body: Text('Honesty intro page')),
        },
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  Future<void> choose(WidgetTester tester, String key, String option) async {
    await tester.ensureVisible(find.byKey(ValueKey(key)));
    await tester.tap(find.byKey(ValueKey(key)));
    await tester.pumpAndSettle();
    await tester.tap(find.text(option).last);
    await tester.pumpAndSettle();
  }

  Future<void> tapButton(WidgetTester tester, String label) async {
    await tester.tap(find.widgetWithText(FilledButton, label));
    await tester.pumpAndSettle();
  }

  testWidgets('sign-up mode starts empty and shows every required error', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.text('Create your profile'), findsOneWidget);
    expect(find.text('Add photo'), findsOneWidget);

    await tapButton(tester, 'Continue');

    expect(find.text('Name is required'), findsOneWidget);
    expect(find.text('Please choose your gender'), findsOneWidget);
    expect(find.text('Please choose your program'), findsOneWidget);
    expect(find.text('Please choose your year'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('profileStudentId')));
    expect(find.text('Student ID is required'), findsOneWidget);
    expect(find.text('Honesty intro page'), findsNothing);
  });

  testWidgets('rejects a student ID that is not 5 or 6 digits', (tester) async {
    await pumpScreen(tester);
    await tester.enterText(
      find.byKey(const ValueKey('profileStudentId')),
      '12ab',
    );

    await tapButton(tester, 'Continue');
    await tester.ensureVisible(find.byKey(const ValueKey('profileStudentId')));

    expect(find.text('Student ID must be 5 or 6 digits'), findsOneWidget);
  });

  testWidgets('bio stops at 300 characters', (tester) async {
    await pumpScreen(tester);

    await tester.enterText(find.byKey(const ValueKey('profileBio')), 'a' * 350);
    await tester.pump();

    expect(find.text('300/300'), findsOneWidget);
  });

  testWidgets('a valid profile is saved and Continue opens Honesty intro', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.enterText(
      find.byKey(const ValueKey('profileName')),
      'Ayse Yilmaz',
    );
    await choose(tester, 'profileGender', 'Female');
    await choose(tester, 'profileProgram', 'Computer Science and Engineering');
    await choose(tester, 'profileYear', 'Prep');
    await tester.enterText(
      find.byKey(const ValueKey('profileBio')),
      'Quiet and tidy.',
    );
    await tester.enterText(
      find.byKey(const ValueKey('profileStudentId')),
      '34567',
    );

    await tapButton(tester, 'Continue');

    expect(find.text('Honesty intro page'), findsOneWidget);
    final saved = await tester.runAsync(users.getCurrentUser);
    expect(saved!.name, 'Ayse Yilmaz');
    expect(saved.gender, 'Female');
    expect(saved.year, 0);
    expect(saved.studentId, '34567');
    expect(saved.bio, 'Quiet and tidy.');
  });

  testWidgets('edit mode is filled with the current profile and Save goes '
      'back', (tester) async {
    await pumpScreen(tester, argument: BasicProfileScreen.editArgument);

    expect(find.text('Edit profile'), findsOneWidget);
    expect(find.text(MockUserService.fakeUser.name), findsOneWidget);
    expect(find.text('Change photo'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('profileName')),
      'Bassam K.',
    );
    await tapButton(tester, 'Save');

    expect(find.text('Open'), findsOneWidget);
    expect(find.text('Profile saved'), findsOneWidget);
    final saved = await tester.runAsync(users.getCurrentUser);
    expect(saved!.name, 'Bassam K.');
    expect(saved.studentId, MockUserService.fakeUser.studentId);
    expect(saved.photoUrl, MockUserService.fakeUser.photoUrl);
  });

  testWidgets('no overflow on a large phone in edit mode', (tester) async {
    await pumpScreen(
      tester,
      argument: BasicProfileScreen.editArgument,
      size: const Size(430, 932),
    );

    expect(find.text('Save'), findsOneWidget);
  });
}
