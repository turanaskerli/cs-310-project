import 'package:flutter_test/flutter_test.dart';
import 'package:roommate_finder/models/connection.dart';
import 'package:roommate_finder/models/recommendation.dart';

void main() {
  const me = 'me';
  const them = 'them';
  final connection = Connection(
    id: 'c1',
    fromUid: them,
    toUid: me,
    fromSummary: const OtherSummary(name: 'Elif', program: 'Economics'),
    toSummary: const OtherSummary(name: 'Arda'),
    status: ConnectionStatus.accepted,
    score: 89,
    confirmedBy: const [them],
    lastMessage: 'Hi!',
    lastMessageSenderUid: them,
    lastMessageAt: DateTime.utc(2026, 11, 5, 10),
    unreadCount: const {me: 2},
    createdAt: DateTime.utc(2026, 11, 4),
    respondedAt: DateTime.utc(2026, 11, 4, 1),
  );

  test('round trip', () {
    expect(Connection.fromMap(connection.toMap()), connection);
  });

  test('toMap stores both members for array-contains queries', () {
    expect(connection.toMap()['members'], [them, me]);
  });

  test('document id wins over the id field', () {
    expect(Connection.fromMap(connection.toMap(), id: 'doc').id, 'doc');
  });

  test('viewer-dependent helpers', () {
    expect(connection.isIncomingFor(me), isTrue);
    expect(connection.isIncomingFor(them), isFalse);
    expect(connection.otherUid(me), them);
    expect(connection.otherSummary(me).name, 'Elif');
    expect(connection.otherSummary(them).name, 'Arda');
    expect(connection.hasUnreadFor(me), isTrue);
    expect(connection.hasUnreadFor(them), isFalse);
  });

  test('confirmed only when both members confirmed', () {
    expect(connection.isConfirmed, isFalse);
    expect(connection.copyWith(confirmedBy: [them, me]).isConfirmed, isTrue);
    expect(
      connection
          .copyWith(status: ConnectionStatus.pending, confirmedBy: [them, me])
          .isConfirmed,
      isFalse,
    );
  });

  test('missing optional fields get defaults', () {
    final c = Connection.fromMap({'fromUid': 'a', 'toUid': 'b'}, id: 'x');
    expect(c.status, ConnectionStatus.pending);
    expect(c.confirmedBy, isEmpty);
    expect(c.unreadCount, isEmpty);
    expect(c.score, isNull);
    expect(c.fromSummary.name, '');
  });

  test('unknown status falls back to pending', () {
    expect(ConnectionStatus.fromName('weird'), ConnectionStatus.pending);
    expect(ConnectionStatus.fromName('declined'), ConnectionStatus.declined);
  });

  test('roommate contact round trip', () {
    const contact = RoommateContact(
      studentId: '35266',
      phone: '+90 500 000 00 00',
      instagram: '@arda',
    );
    expect(RoommateContact.fromMap(contact.toMap()), contact);
  });
}
