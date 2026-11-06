import 'package:flutter_test/flutter_test.dart';
import 'package:roommate_finder/models/message.dart';

void main() {
  final message = Message(
    id: 'm1',
    connectionId: 'c1',
    senderUid: 'me',
    text: 'Hello',
    sentAt: DateTime.utc(2026, 11, 5, 9, 30),
  );

  test('round trip', () {
    expect(Message.fromMap(message.toMap()), message);
  });

  test('isMine compares the sender', () {
    expect(message.isMine('me'), isTrue);
    expect(message.isMine('them'), isFalse);
  });

  test('a message without a timestamp yet gets the current time', () {
    final m = Message.fromMap({'senderUid': 'me', 'text': 'Hi'}, id: 'm2');
    expect(m.id, 'm2');
    expect(DateTime.now().difference(m.sentAt).inSeconds, lessThan(5));
  });
}
