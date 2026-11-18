import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roommate_finder/models/connection.dart';
import 'package:roommate_finder/screens/chat/chats_screen.dart';
import 'package:roommate_finder/services/mock/mock_connection_service.dart';
import 'package:roommate_finder/utils/app_routes.dart';
import 'package:roommate_finder/utils/app_theme.dart';

/// No accepted connections yet.
class _NoChatsService extends MockConnectionService {
  _NoChatsService() : super(delay: Duration.zero);

  @override
  Stream<List<Connection>> watchChats() => Stream.value(const []);
}

void main() {
  late MockConnectionService service;

  setUp(() => service = MockConnectionService(delay: Duration.zero));
  tearDown(() => service.dispose());

  Future<void> pumpScreen(
    WidgetTester tester, {
    MockConnectionService? using,
    Size size = const Size(360, 640),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: ChatsScreen(service: using ?? service),
        onGenerateRoute: (settings) => MaterialPageRoute(
          settings: settings,
          builder: (_) => Scaffold(
            body: Text(
              'route ${settings.name} '
              '${(settings.arguments as Connection?)?.id}',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('lists chats latest first with previews and unread counts', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.text('Deniz Yılmaz'), findsOneWidget);
    expect(
      find.text('Do you want to meet at the library tomorrow?'),
      findsOneWidget,
    );
    // My own last message gets a "You:" prefix.
    expect(find.text('You: Sounds good, talk later!'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Deniz Yılmaz')).dy,
      lessThan(tester.getTopLeft(find.text('Aylin Şahin')).dy),
    );
    expect(
      tester.getTopLeft(find.text('Aylin Şahin')).dy,
      lessThan(tester.getTopLeft(find.text('Selin Koç')).dy),
    );
  });

  testWidgets('tapping a chat opens Chat with the connection', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Aylin Şahin'));
    await tester.pumpAndSettle();

    expect(find.text('route ${AppRoutes.chat} conn_aylin'), findsOneWidget);
  });

  testWidgets('a newly accepted request shows up at the top', (tester) async {
    await pumpScreen(tester);

    await tester.runAsync(() => service.accept('conn_elif'));
    await tester.pumpAndSettle();

    expect(find.text('Elif Kaya'), findsOneWidget);
    expect(find.text('Say hi to start the conversation 👋'), findsOneWidget);
  });

  testWidgets('shows an empty message without chats', (tester) async {
    final empty = _NoChatsService();
    addTearDown(empty.dispose);
    await pumpScreen(tester, using: empty);

    expect(find.text('No chats yet'), findsOneWidget);
  });

  testWidgets('long names and messages fit on a small phone', (tester) async {
    await pumpScreen(tester, size: const Size(320, 568));
    expect(tester.takeException(), isNull);
  });
}
