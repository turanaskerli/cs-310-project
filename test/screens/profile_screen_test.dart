import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roommate_finder/screens/onboarding/basic_profile_screen.dart';
import 'package:roommate_finder/screens/profile/profile_screen.dart';
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
        home: const ProfileScreen(),
        onGenerateRoute: (settings) => MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Text('${settings.name} ${settings.arguments ?? ''}'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapLabel(WidgetTester tester, String label) async {
    // The list builds lazily, so scroll until the button exists on screen.
    await tester.scrollUntilVisible(
      find.text(label),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  testWidgets('shows my name, program, year, bio and private student ID', (
    tester,
  ) async {
    await pumpScreen(tester);
    const me = MockUserService.fakeUser;

    expect(find.text(me.name), findsOneWidget);
    expect(find.text('${me.program} · Year ${me.year}'), findsOneWidget);
    expect(find.text(me.bio), findsOneWidget);
    expect(find.text('Student ID ${me.studentId}'), findsOneWidget);
  });

  testWidgets('Edit profile opens Basic profile in edit mode', (tester) async {
    await pumpScreen(tester);

    await tapLabel(tester, 'Edit profile');

    expect(
      find.text('${AppRoutes.basicProfile} ${BasicProfileScreen.editArgument}'),
      findsOneWidget,
    );
  });

  testWidgets('Edit answers and Settings open their screens', (tester) async {
    await pumpScreen(tester);

    await tapLabel(tester, 'Edit answers');
    expect(find.text('${AppRoutes.questionnaire} '), findsOneWidget);

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    await tapLabel(tester, 'Settings');
    expect(find.text('${AppRoutes.settings} '), findsOneWidget);
  });

  testWidgets('updates when the profile is saved', (tester) async {
    await pumpScreen(tester);

    await tester.runAsync(
      () => users.saveProfile(
        MockUserService.fakeUser.copyWith(name: 'Renamed Student'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Renamed Student'), findsOneWidget);
  });

  testWidgets('without a profile, offers to create one', (tester) async {
    AppServices.users = MockUserService(delay: Duration.zero, startEmpty: true);
    await pumpScreen(tester);

    expect(find.text('No profile yet'), findsOneWidget);
    await tapLabel(tester, 'Create profile');
    expect(find.text('${AppRoutes.basicProfile} '), findsOneWidget);
  });

  testWidgets('no overflow on a large phone', (tester) async {
    await pumpScreen(tester, size: const Size(430, 932));

    expect(find.text('Edit profile'), findsOneWidget);
  });
}
