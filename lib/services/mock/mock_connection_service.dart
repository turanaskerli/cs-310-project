import 'dart:async';

import 'package:collection/collection.dart';

import '../../models/connection.dart';
import '../../models/message.dart';
import '../../models/recommendation.dart';
import '../connection_service.dart';

/// Fake requests and chats, so the Requests, Chats, Chat and Roommate
/// confirmed screens work without Firebase.
///
/// Uses the same fake students as `MockMatchService`, so a request sent from
/// Match detail shows the same name and photo. Changes live in memory only.
class MockConnectionService implements ConnectionService {
  static const myUid = 'mock_me';

  static const mySummary = OtherSummary(
    name: 'Arda Terzi',
    photoUrl: 'https://i.pravatar.cc/300?img=8',
    program: 'Computer Science and Engineering',
    year: 1,
  );

  /// Simulated network delay, so screens show their loading state.
  final Duration delay;

  /// When true, the partner confirms at the same moment I do, so the
  /// "We're roommates" flow reaches the Roommate confirmed screen. Set to
  /// false to see the "waiting for them" state.
  final bool partnerAlwaysConfirms;

  final DateTime Function() _now;
  final _changes = StreamController<List<Connection>>.broadcast();
  late List<Connection> _all = _seed(_now());
  int _nextId = 1;

  MockConnectionService({
    this.delay = const Duration(milliseconds: 300),
    this.partnerAlwaysConfirms = true,
    DateTime Function()? clock,
  }) : _now = clock ?? DateTime.now;

  @override
  String get currentUid => myUid;

  @override
  Stream<List<Connection>> watchIncomingRequests() => _watch(
    (all) =>
        _newestFirst(all.where((c) => c.isPending && c.isIncomingFor(myUid))),
  );

  @override
  Stream<List<Connection>> watchOutgoingRequests() => _watch(
    (all) =>
        _newestFirst(all.where((c) => c.isPending && !c.isIncomingFor(myUid))),
  );

  @override
  Stream<List<Connection>> watchChats() => _watch(
    (all) =>
        all.where((c) => c.isAccepted).toList()
          ..sort((a, b) => _lastActivity(b).compareTo(_lastActivity(a))),
  );

  @override
  Stream<Connection?> watchConnection(String connectionId) =>
      _watch((all) => all.firstWhereOrNull((c) => c.id == connectionId));

  @override
  Future<Connection> sendRequest({
    required String otherUid,
    required OtherSummary other,
    int? score,
  }) async {
    await Future<void>.delayed(delay);
    final existing = _all.firstWhereOrNull(
      (c) =>
          (c.isPending || c.isAccepted) &&
          c.members.contains(otherUid) &&
          c.members.contains(myUid),
    );
    if (existing != null) return existing;

    final created = Connection(
      id: 'conn_new_${_nextId++}',
      fromUid: myUid,
      toUid: otherUid,
      fromSummary: mySummary,
      toSummary: other,
      score: score,
      createdAt: _now(),
    );
    _all = [..._all, created];
    _emit();
    return created;
  }

  @override
  Future<void> accept(String connectionId) async {
    _replace(
      _incomingPending(connectionId)
          .copyWith(status: ConnectionStatus.accepted, respondedAt: _now()),
    );
  }

  @override
  Future<void> decline(String connectionId) async {
    _replace(
      _incomingPending(connectionId)
          .copyWith(status: ConnectionStatus.declined, respondedAt: _now()),
    );
  }

  @override
  Future<void> cancel(String connectionId) async {
    final c = _find(connectionId);
    if (!c.isPending || c.fromUid != myUid) {
      throw StateError('Only my own pending requests can be cancelled');
    }
    _replace(
      c.copyWith(status: ConnectionStatus.cancelled, respondedAt: _now()),
    );
  }

  @override
  Future<Connection> confirmRoommate(String connectionId) async {
    await Future<void>.delayed(delay);
    final c = _find(connectionId);
    if (!c.isAccepted) {
      throw StateError('Only accepted connections can be confirmed');
    }
    final updated = c.copyWith(
      confirmedBy: {
        ...c.confirmedBy,
        myUid,
        if (partnerAlwaysConfirms) c.otherUid(myUid),
      }.toList(),
    );
    _replace(updated);
    return updated;
  }

  @override
  Future<RoommateContact?> getPartnerContact(String connectionId) async {
    await Future<void>.delayed(delay);
    final c = _all.firstWhereOrNull((c) => c.id == connectionId);
    if (c == null || !c.isConfirmed) return null;
    return _contacts[c.otherUid(myUid)] ??
        const RoommateContact(studentId: '00000');
  }

  @override
  Future<void> markRead(String connectionId) async {
    final c = _find(connectionId);
    if (!c.hasUnreadFor(myUid)) return;
    _replace(c.copyWith(unreadCount: {...c.unreadCount, myUid: 0}));
  }

  /// Updates the chat summary after a message is sent. Called by
  /// `MockChatService`; in Firebase a Cloud Function does this.
  void recordMessage(Message message) {
    final c = _find(message.connectionId);
    final receiver = c.otherUid(message.senderUid);
    _replace(
      c.copyWith(
        lastMessage: message.text,
        lastMessageSenderUid: message.senderUid,
        lastMessageAt: message.sentAt,
        unreadCount: {
          ...c.unreadCount,
          receiver: (c.unreadCount[receiver] ?? 0) + 1,
        },
      ),
    );
  }

  /// The connection with [connectionId], or null. For the mock chat service.
  Connection? findById(String connectionId) =>
      _all.firstWhereOrNull((c) => c.id == connectionId);

  /// Closes the change stream. Call when the service is no longer used.
  void dispose() => _changes.close();

  Stream<T> _watch<T>(T Function(List<Connection> all) select) {
    StreamSubscription<List<Connection>>? changes;
    late final StreamController<T> controller;
    controller = StreamController(
      onListen: () async {
        await Future<void>.delayed(delay);
        if (controller.isClosed) return;
        // Take the current list and subscribe in the same step, so a change
        // made while loading is never lost.
        controller.add(select(_all));
        changes = _changes.stream.listen((all) => controller.add(select(all)));
      },
      onCancel: () async {
        await changes?.cancel();
        await controller.close();
      },
    );
    return controller.stream;
  }

  Connection _find(String connectionId) =>
      findById(connectionId) ??
      (throw StateError('No connection with id $connectionId'));

  Connection _incomingPending(String connectionId) {
    final c = _find(connectionId);
    if (!c.isPending || !c.isIncomingFor(myUid)) {
      throw StateError('Only pending requests sent to me can be answered');
    }
    return c;
  }

  void _replace(Connection updated) {
    _all = [for (final c in _all) c.id == updated.id ? updated : c];
    _emit();
  }

  void _emit() => _changes.add(List.unmodifiable(_all));

  static List<Connection> _newestFirst(Iterable<Connection> connections) =>
      connections.toList()..sort(
        (a, b) =>
            (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)),
      );

  static DateTime _lastActivity(Connection c) =>
      c.lastMessageAt ?? c.respondedAt ?? c.createdAt ?? DateTime(0);
}

OtherSummary _student(String name, String program, int year, int photo) =>
    OtherSummary(
      name: name,
      photoUrl: 'https://i.pravatar.cc/300?img=$photo',
      program: program,
      year: year,
    );

/// Same people, programs and photos as in `MockMatchService`.
final _deniz = _student(
  'Deniz Yılmaz',
  'Computer Science and Engineering',
  1,
  11,
);
final _elif = _student('Elif Kaya', 'Economics', 1, 5);
final _mehmet = _student('Mehmet Demir', 'Industrial Engineering', 1, 12);
final _zeynep = _student(
  'Zeynep Arslan',
  'Molecular Biology, Genetics and Bioengineering',
  1,
  9,
);
final _can = _student('Can Öztürk', 'Mechatronics Engineering', 2, 13);
final _aylin = _student('Aylin Şahin', 'Political Science', 1, 16);
final _selin = _student(
  'Selin Koç',
  'Visual Arts and Visual Communication Design',
  1,
  20,
);
final _lukas = _student('Lukas Weber', 'Computer Science (exchange)', 3, 15);

/// Shown only after both students confirm.
const _contacts = {
  'mock_deniz': RoommateContact(
    studentId: '35102',
    phone: '+90 532 555 01 02',
    instagram: '@deniz.ylmz',
  ),
  'mock_aylin': RoommateContact(
    studentId: '35877',
    phone: '+90 541 555 08 77',
    instagram: '@aylinsahin',
  ),
  'mock_selin': RoommateContact(studentId: '35940', phone: '+90 505 555 09 40'),
};

/// Three incoming, two outgoing and three accepted connections. Selin has
/// already pressed "We're roommates", so confirming her finishes at once.
List<Connection> _seed(DateTime now) => [
  Connection(
    id: 'conn_elif',
    fromUid: 'mock_elif',
    toUid: MockConnectionService.myUid,
    fromSummary: _elif,
    toSummary: MockConnectionService.mySummary,
    score: 89,
    createdAt: now.subtract(const Duration(hours: 2)),
  ),
  Connection(
    id: 'conn_zeynep',
    fromUid: 'mock_zeynep',
    toUid: MockConnectionService.myUid,
    fromSummary: _zeynep,
    toSummary: MockConnectionService.mySummary,
    score: 77,
    createdAt: now.subtract(const Duration(days: 1)),
  ),
  Connection(
    id: 'conn_lukas',
    fromUid: 'mock_lukas',
    toUid: MockConnectionService.myUid,
    fromSummary: _lukas,
    toSummary: MockConnectionService.mySummary,
    score: 71,
    createdAt: now.subtract(const Duration(days: 3)),
  ),
  Connection(
    id: 'conn_mehmet',
    fromUid: MockConnectionService.myUid,
    toUid: 'mock_mehmet',
    fromSummary: MockConnectionService.mySummary,
    toSummary: _mehmet,
    score: 88,
    createdAt: now.subtract(const Duration(hours: 5)),
  ),
  Connection(
    id: 'conn_can',
    fromUid: MockConnectionService.myUid,
    toUid: 'mock_can',
    fromSummary: MockConnectionService.mySummary,
    toSummary: _can,
    score: 79,
    createdAt: now.subtract(const Duration(days: 2)),
  ),
  Connection(
    id: 'conn_deniz',
    fromUid: MockConnectionService.myUid,
    toUid: 'mock_deniz',
    fromSummary: MockConnectionService.mySummary,
    toSummary: _deniz,
    status: ConnectionStatus.accepted,
    score: 100,
    lastMessage: 'Do you want to meet at the library tomorrow?',
    lastMessageSenderUid: 'mock_deniz',
    lastMessageAt: now.subtract(const Duration(minutes: 12)),
    unreadCount: const {'mock_deniz': 0, MockConnectionService.myUid: 2},
    createdAt: now.subtract(const Duration(days: 4)),
    respondedAt: now.subtract(const Duration(days: 3, hours: 23)),
  ),
  Connection(
    id: 'conn_aylin',
    fromUid: 'mock_aylin',
    toUid: MockConnectionService.myUid,
    fromSummary: _aylin,
    toSummary: MockConnectionService.mySummary,
    status: ConnectionStatus.accepted,
    score: 74,
    lastMessage: 'Sounds good, talk later!',
    lastMessageSenderUid: MockConnectionService.myUid,
    lastMessageAt: now.subtract(const Duration(hours: 20)),
    createdAt: now.subtract(const Duration(days: 5)),
    respondedAt: now.subtract(const Duration(days: 5)),
  ),
  Connection(
    id: 'conn_selin',
    fromUid: 'mock_selin',
    toUid: MockConnectionService.myUid,
    fromSummary: _selin,
    toSummary: MockConnectionService.mySummary,
    status: ConnectionStatus.accepted,
    score: 68,
    confirmedBy: const ['mock_selin'],
    lastMessage: "I pressed We're roommates, your turn :)",
    lastMessageSenderUid: 'mock_selin',
    lastMessageAt: now.subtract(const Duration(days: 2)),
    unreadCount: const {MockConnectionService.myUid: 1},
    createdAt: now.subtract(const Duration(days: 8)),
    respondedAt: now.subtract(const Duration(days: 7)),
  ),
];
