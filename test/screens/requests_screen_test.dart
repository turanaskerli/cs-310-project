import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roommate_finder/screens/requests/requests_screen.dart';
import 'package:roommate_finder/services/mock/mock_connection_service.dart';
import 'package:roommate_finder/utils/app_theme.dart';

/// Accepting always fails, as if the device were offline.
class _OfflineConnectionService extends MockConnectionService {
  _OfflineConnectionService() : super(delay: Duration.zero);

  @override
  Future<void> accept(String connectionId) async => throw StateError('offline');
}

void main() {
  late MockConnectionService service;

  setUp(() => service = MockConnectionService(delay: Duration.zero));
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
        home: RequestsScreen(service: service),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapButton(WidgetTester tester, String label) async {
    await tester.tap(find.text(label).first);
    await tester.pumpAndSettle();
  }

  testWidgets('shows incoming requests newest first with counts', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.text('Incoming (3)'), findsOneWidget);
    expect(find.text('Outgoing (2)'), findsOneWidget);
    expect(find.text('Elif Kaya'), findsOneWidget);
    expect(find.text('89%'), findsOneWidget);
    expect(find.text('Sent 2 h ago'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Elif Kaya')).dy,
      lessThan(tester.getTopLeft(find.text('Zeynep Arslan')).dy),
    );
  });

  testWidgets('Accept removes the card and says the chat is open', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tapButton(tester, 'Accept');

    expect(find.text('Elif Kaya'), findsNothing);
    expect(find.text('Incoming (2)'), findsOneWidget);
    expect(
      find.text('You and Elif Kaya are connected. Say hi in Chats!'),
      findsOneWidget,
    );
  });

  testWidgets('Decline asks first; Keep leaves the request', (tester) async {
    await pumpScreen(tester);

    await tapButton(tester, 'Decline');
    expect(find.text("Decline Elif Kaya's request?"), findsOneWidget);

    await tester.tap(find.text('Keep'));
    await tester.pumpAndSettle();
    expect(find.text('Elif Kaya'), findsOneWidget);
    expect(find.text('Incoming (3)'), findsOneWidget);
  });

  testWidgets('confirming Decline removes the request', (tester) async {
    await pumpScreen(tester);

    await tapButton(tester, 'Decline');
    await tester.tap(find.widgetWithText(TextButton, 'Decline'));
    await tester.pumpAndSettle();

    expect(find.text('Elif Kaya'), findsNothing);
    expect(find.text('Incoming (2)'), findsOneWidget);
    expect(find.text('Request from Elif Kaya declined'), findsOneWidget);
  });

  testWidgets('swiping an incoming card declines it after confirming', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.drag(find.text('Elif Kaya'), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(find.text("Decline Elif Kaya's request?"), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Decline'));
    await tester.pumpAndSettle();
    expect(find.text('Elif Kaya'), findsNothing);
    expect(find.text('Zeynep Arslan'), findsOneWidget);
  });

  testWidgets('Outgoing tab cancels a request after confirming', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Outgoing (2)'));
    await tester.pumpAndSettle();
    expect(find.text('Mehmet Demir'), findsOneWidget);
    expect(find.text('Waiting for a reply'), findsNWidgets(2));

    await tapButton(tester, 'Cancel request');
    expect(find.text('Cancel your request to Mehmet Demir?'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Cancel request'));
    await tester.pumpAndSettle();

    expect(find.text('Mehmet Demir'), findsNothing);
    expect(find.text('Outgoing (1)'), findsOneWidget);
    expect(find.text('Request to Mehmet Demir cancelled'), findsOneWidget);
  });

  testWidgets('empty state when there are no incoming requests', (
    tester,
  ) async {
    for (final id in ['conn_elif', 'conn_zeynep', 'conn_lukas']) {
      await service.decline(id);
    }
    await pumpScreen(tester);

    expect(find.text('Incoming'), findsOneWidget);
    expect(find.text('No new requests'), findsOneWidget);
  });

  testWidgets('a failed Accept puts the card back', (tester) async {
    service = _OfflineConnectionService();
    await pumpScreen(tester);

    await tapButton(tester, 'Accept');

    expect(find.text('Elif Kaya'), findsOneWidget);
    expect(find.text('Incoming (3)'), findsOneWidget);
    expect(
      find.text('Could not accept the request. Try again.'),
      findsOneWidget,
    );
  });

  testWidgets('no overflow on a small or a large phone', (tester) async {
    await pumpScreen(tester, size: const Size(320, 568));
    expect(find.text('Elif Kaya'), findsOneWidget);

    await pumpScreen(tester, size: const Size(430, 932));
    expect(find.text('Elif Kaya'), findsOneWidget);
  });

  test('sentAgo', () {
    final now = DateTime(2026, 11, 20, 12);
    expect(sentAgo(null, now), isNull);
    expect(sentAgo(now, now), 'Sent just now');
    expect(
      sentAgo(now.subtract(const Duration(minutes: 5)), now),
      'Sent 5 min ago',
    );
    expect(
      sentAgo(now.subtract(const Duration(hours: 3)), now),
      'Sent 3 h ago',
    );
    expect(
      sentAgo(now.subtract(const Duration(hours: 30)), now),
      'Sent yesterday',
    );
    expect(
      sentAgo(now.subtract(const Duration(days: 3)), now),
      'Sent 3 days ago',
    );
    expect(sentAgo(DateTime(2026, 11, 2), now), 'Sent 2 Nov');
  });
}
