import 'package:flutter_test/flutter_test.dart';
import 'package:roommate_finder/models/recommendation.dart';
import 'package:roommate_finder/services/mock/mock_connection_service.dart';

void main() {
  late MockConnectionService service;

  setUp(() => service = MockConnectionService(delay: Duration.zero));
  tearDown(() => service.dispose());

  test('seeds incoming, outgoing and accepted connections', () async {
    final incoming = await service.watchIncomingRequests().first;
    final outgoing = await service.watchOutgoingRequests().first;
    final chats = await service.watchChats().first;

    expect(incoming.map((c) => c.id), [
      'conn_elif',
      'conn_zeynep',
      'conn_lukas',
    ]);
    expect(outgoing.map((c) => c.id), ['conn_mehmet', 'conn_can']);
    expect(chats.map((c) => c.id), ['conn_deniz', 'conn_aylin', 'conn_selin']);

    for (final c in [...incoming, ...outgoing, ...chats]) {
      final other = c.otherSummary(service.currentUid);
      expect(other.photoUrl, startsWith('https://'), reason: c.id);
      expect(other.name, isNot(MockConnectionService.mySummary.name));
    }
    expect(chats.first.hasUnreadFor(service.currentUid), isTrue);
  });

  test('accept moves a request from Incoming to Chats', () async {
    final incoming = service.watchIncomingRequests().take(2).toList();
    final chats = service.watchChats().take(2).toList();
    await Future<void>.delayed(Duration.zero);

    await service.accept('conn_elif');

    expect(
      (await incoming).last.map((c) => c.id),
      isNot(contains('conn_elif')),
    );
    expect((await chats).last.map((c) => c.id), contains('conn_elif'));
  });

  test('decline and cancel remove the cards', () async {
    await service.decline('conn_zeynep');
    await service.cancel('conn_can');

    final incoming = await service.watchIncomingRequests().first;
    final outgoing = await service.watchOutgoingRequests().first;
    expect(incoming.map((c) => c.id), isNot(contains('conn_zeynep')));
    expect(outgoing.map((c) => c.id), isNot(contains('conn_can')));
  });

  test('requests can only be answered by the right side', () async {
    expect(() => service.accept('conn_mehmet'), throwsStateError);
    expect(() => service.cancel('conn_elif'), throwsStateError);
    expect(() => service.decline('missing'), throwsStateError);
  });

  test('sendRequest adds an outgoing request once', () async {
    const other = OtherSummary(name: 'Burak Aydın');
    final first = await service.sendRequest(
      otherUid: 'mock_burak',
      other: other,
      score: 40,
    );
    final again = await service.sendRequest(
      otherUid: 'mock_burak',
      other: other,
    );

    expect(again.id, first.id);
    final outgoing = await service.watchOutgoingRequests().first;
    expect(outgoing.first.id, first.id);
    expect(outgoing.first.otherSummary(service.currentUid), other);
    expect(outgoing, hasLength(3));
  });

  test('sendRequest to an existing chat partner returns that chat', () async {
    final c = await service.sendRequest(
      otherUid: 'mock_deniz',
      other: const OtherSummary(name: 'Deniz'),
    );
    expect(c.id, 'conn_deniz');
  });

  test('contact details appear only after both confirm', () async {
    final waiting = MockConnectionService(
      delay: Duration.zero,
      partnerAlwaysConfirms: false,
    );
    addTearDown(waiting.dispose);

    expect(await waiting.getPartnerContact('conn_deniz'), isNull);
    final half = await waiting.confirmRoommate('conn_deniz');
    expect(half.isConfirmed, isFalse);
    expect(await waiting.getPartnerContact('conn_deniz'), isNull);

    // Selin already confirmed, so my confirmation completes it.
    final done = await waiting.confirmRoommate('conn_selin');
    expect(done.isConfirmed, isTrue);
    expect((await waiting.getPartnerContact('conn_selin'))!.studentId, '35940');
  });

  test('by default the partner confirms too', () async {
    final c = await service.confirmRoommate('conn_aylin');
    expect(c.isConfirmed, isTrue);
    final contact = await service.getPartnerContact('conn_aylin');
    expect(contact!.instagram, '@aylinsahin');
  });

  test('only accepted connections can be confirmed', () async {
    expect(() => service.confirmRoommate('conn_elif'), throwsStateError);
  });

  test('markRead clears my unread count', () async {
    final updates = service.watchConnection('conn_deniz').take(2).toList();
    await Future<void>.delayed(Duration.zero);

    await service.markRead('conn_deniz');

    final states = await updates;
    expect(states.first!.hasUnreadFor(service.currentUid), isTrue);
    expect(states.last!.hasUnreadFor(service.currentUid), isFalse);
  });

  test('watchConnection emits null for an unknown id', () async {
    expect(await service.watchConnection('missing').first, isNull);
  });
}
