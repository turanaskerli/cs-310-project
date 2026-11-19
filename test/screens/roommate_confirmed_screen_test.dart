import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roommate_finder/models/connection.dart';
import 'package:roommate_finder/screens/chat/roommate_confirmed_screen.dart';
import 'package:roommate_finder/services/mock/mock_connection_service.dart';
import 'package:roommate_finder/utils/app_routes.dart';
import 'package:roommate_finder/utils/app_theme.dart';

void main() {
  late MockConnectionService service;

  setUp(() => service = MockConnectionService(delay: Duration.zero));
  tearDown(() => service.dispose());

  Future<void> openScreen(
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
                builder: (_) => RoommateConfirmedScreen(service: service),
              ),
            ),
            child: const Text('open'),
          ),
        ),
        onGenerateRoute: (settings) => MaterialPageRoute(
          settings: settings,
          builder: (_) => Scaffold(body: Text('route ${settings.name}')),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<Connection> confirmed(WidgetTester tester, String id) async =>
      (await tester.runAsync(() => service.confirmRoommate(id)))!;

  testWidgets("shows the partner's student ID, phone and Instagram", (
    tester,
  ) async {
    await openScreen(tester, await confirmed(tester, 'conn_deniz'));

    expect(find.text('You and Deniz are roommates!'), findsOneWidget);
    expect(find.text('35102'), findsOneWidget);
    expect(find.text('+90 532 555 01 02'), findsOneWidget);
    expect(find.text('@deniz.ylmz'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('student ID (35102)'),
      200,
      // The selectable texts are scrollables too; scroll the page itself.
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('student ID (35102)'), findsOneWidget);
  });

  testWidgets('leaves out contacts the partner did not share', (tester) async {
    await openScreen(tester, await confirmed(tester, 'conn_selin'));

    expect(find.text('35940'), findsOneWidget);
    expect(find.text('Instagram'), findsNothing);
  });

  testWidgets('Copy puts the student ID on the clipboard', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await openScreen(tester, await confirmed(tester, 'conn_deniz'));

    await tester.tap(find.byTooltip('Copy Student ID'));
    await tester.pumpAndSettle();

    expect(copied, '35102');
    expect(find.text('Student ID copied'), findsOneWidget);
  });

  testWidgets('hides the details until both confirm', (tester) async {
    await openScreen(tester, service.findById('conn_aylin'));

    expect(find.textContaining('once you both confirm'), findsOneWidget);
    expect(find.text('35877'), findsNothing);
  });

  testWidgets('Back to home clears the history', (tester) async {
    await openScreen(tester, await confirmed(tester, 'conn_deniz'));

    await tester.tap(find.text('Back to home'));
    await tester.pumpAndSettle();

    expect(find.text('route ${AppRoutes.home}'), findsOneWidget);
    expect(find.text('open'), findsNothing);
  });

  testWidgets('fits a small phone', (tester) async {
    await openScreen(
      tester,
      await confirmed(tester, 'conn_deniz'),
      size: const Size(320, 568),
    );
    expect(tester.takeException(), isNull);
  });
}
