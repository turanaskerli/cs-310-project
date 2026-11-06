import 'package:flutter_test/flutter_test.dart';
import 'package:roommate_finder/services/mock/mock_chat_service.dart';
import 'package:roommate_finder/services/mock/mock_connection_service.dart';

void main() {
  late MockConnectionService connections;
  late MockChatService chat;

  setUp(() {
    connections = MockConnectionService(delay: Duration.zero);
    chat = MockChatService(connections: connections, delay: Duration.zero);
  });
  tearDown(() {
    chat.dispose();
    connections.dispose();
  });

  test('seeded chats match their connection summary', () async {
    final chats = await connections.watchChats().first;

    for (final c in chats) {
      final messages = await chat.watchMessages(c.id).first;
      expect(messages, isNotEmpty, reason: c.id);
      expect(messages.last.text, c.lastMessage, reason: c.id);
      expect(messages.last.senderUid, c.lastMessageSenderUid, reason: c.id);
      final times = messages.map((m) => m.sentAt).toList();
      expect(times, [...times]..sort(), reason: '${c.id} oldest first');
    }
  });

  test('sending adds the message and updates the Chats list', () async {
    final messages = chat.watchMessages('conn_aylin').take(2).toList();
    final chats = connections.watchChats().take(2).toList();
    await Future<void>.delayed(Duration.zero);

    final sent = await chat.sendMessage('conn_aylin', '  See you at dinner  ');

    expect(sent.text, 'See you at dinner');
    expect(sent.isMine(chat.currentUid), isTrue);
    final lists = await messages;
    expect(lists.last.length, lists.first.length + 1);
    expect(lists.last.last, sent);

    final latest = (await chats).last;
    expect(latest.first.id, 'conn_aylin', reason: 'newest chat moves to top');
    expect(latest.first.lastMessage, 'See you at dinner');
    expect(latest.first.hasUnreadFor('mock_aylin'), isTrue);
    expect(latest.first.hasUnreadFor(chat.currentUid), isFalse);
  });

  test('messages for other chats are not emitted', () async {
    final deniz = chat.watchMessages('conn_deniz');
    final first = await deniz.first;
    await chat.sendMessage('conn_aylin', 'Hi');
    expect(await chat.watchMessages('conn_deniz').first, first);
  });

  test('empty text and unaccepted connections are rejected', () async {
    expect(() => chat.sendMessage('conn_deniz', '   '), throwsArgumentError);
    expect(() => chat.sendMessage('conn_elif', 'Hi'), throwsStateError);
    expect(() => chat.sendMessage('missing', 'Hi'), throwsStateError);
  });

  test('an accepted request can start chatting', () async {
    await connections.accept('conn_elif');
    await chat.sendMessage('conn_elif', 'Hi Elif!');

    final messages = await chat.watchMessages('conn_elif').first;
    expect(messages.single.text, 'Hi Elif!');
  });
}
