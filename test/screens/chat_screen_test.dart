import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roommate_finder/models/connection.dart';
import 'package:roommate_finder/screens/chat/chat_screen.dart';
import 'package:roommate_finder/services/mock/mock_chat_service.dart';
import 'package:roommate_finder/services/mock/mock_connection_service.dart';
import 'package:roommate_finder/utils/app_routes.dart';
import 'package:roommate_finder/utils/app_theme.dart';

void main() {
  late MockConnectionService connections;
  late MockChatService chat;

  void createServices({bool partnerAlwaysConfirms = true}) {
    connections = MockConnectionService(
      delay: Duration.zero,
      partnerAlwaysConfirms: partnerAlwaysConfirms,
    );
    chat = MockChatService(connections: connections, delay: Duration.zero);
  }

  setUp(createServices);
  tearDown(() {
    chat.dispose();
    connections.dispose();
  });

  /// Opens Chat the way the Chats list does: as a route with the connection
  /// as its argument.
  Future<void> openChat(
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
                builder: (_) => ChatScreen(
                  connectionService: connections,
                  chatService: chat,
                ),
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

  Connection connection(String id) => connections.findById(id)!;

  testWidgets('shows the conversation and marks it read', (tester) async {
    expect(
      connection('conn_deniz').hasUnreadFor(MockConnectionService.myUid),
      isTrue,
    );

    await openChat(tester, connection('conn_deniz'));

    expect(find.text('Deniz Yılmaz'), findsOneWidget);
    expect(
      find.text('Do you want to meet at the library tomorrow?'),
      findsOneWidget,
    );
    expect(find.text('Ready to apply for the dorm together?'), findsOneWidget);
    expect(
      connection('conn_deniz').hasUnreadFor(MockConnectionService.myUid),
      isFalse,
    );
  });

  testWidgets('Send is off until something is typed, then sends', (
    tester,
  ) async {
    await openChat(tester, connection('conn_deniz'));

    IconButton send() =>
        tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.send));
    expect(send().onPressed, isNull);

    await tester.enterText(find.byType(TextField), '   ');
    await tester.pump();
    expect(send().onPressed, isNull);

    await tester.enterText(find.byType(TextField), '  Sure, 10:00?  ');
    await tester.pump();
    await tester.tap(find.byTooltip('Send'));
    await tester.pumpAndSettle();

    expect(find.text('Sure, 10:00?'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
    expect(connection('conn_deniz').lastMessage, 'Sure, 10:00?');
  });

  testWidgets("We're roommates asks first; Not yet changes nothing", (
    tester,
  ) async {
    await openChat(tester, connection('conn_deniz'));

    await tester.tap(find.text("We're roommates"));
    await tester.pumpAndSettle();
    expect(find.text('Room with Deniz?'), findsOneWidget);

    await tester.tap(find.text('Not yet'));
    await tester.pumpAndSettle();
    expect(connection('conn_deniz').confirmedBy, isEmpty);
  });

  testWidgets('confirming when both agree opens Roommate confirmed', (
    tester,
  ) async {
    await openChat(tester, connection('conn_selin'));
    expect(find.text('Selin wants to room with you.'), findsOneWidget);

    await tester.tap(find.text("We're roommates"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Yes, we're roommates"));
    await tester.pumpAndSettle();

    expect(find.text('route ${AppRoutes.roommateConfirmed}'), findsOneWidget);
    expect(connection('conn_selin').isConfirmed, isTrue);
  });

  testWidgets('confirming first waits for the partner', (tester) async {
    createServices(partnerAlwaysConfirms: false);
    await openChat(tester, connection('conn_deniz'));

    await tester.tap(find.text("We're roommates"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Yes, we're roommates"));
    await tester.pumpAndSettle();

    expect(find.text('Waiting for Deniz to confirm.'), findsOneWidget);
    expect(find.text("We're roommates"), findsNothing);
    expect(find.textContaining("You'll see their student ID"), findsOneWidget);
  });

  testWidgets('without a connection it says the chat is gone', (tester) async {
    await openChat(tester, null);
    expect(find.text('This chat is no longer available.'), findsOneWidget);
  });

  testWidgets('fits a small phone with the keyboard open', (tester) async {
    await openChat(
      tester,
      connection('conn_selin'),
      size: const Size(320, 568),
    );
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
