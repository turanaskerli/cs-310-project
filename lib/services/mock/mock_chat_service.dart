import 'dart:async';

import '../../models/message.dart';
import '../chat_service.dart';
import 'mock_connection_service.dart';

/// Keeps chat messages in memory, so the Chat screen works without Firebase.
///
/// Sending a message adds it to the list and updates the connection's last
/// message and unread count in [connections], so the Chats list follows.
class MockChatService implements ChatService {
  final MockConnectionService connections;

  /// Simulated network delay, so screens show their loading state.
  final Duration delay;

  final DateTime Function() _now;
  final _changes = StreamController<String>.broadcast();
  late final Map<String, List<Message>> _messages = _seed(_now());
  int _nextId = 1;

  MockChatService({
    required this.connections,
    this.delay = const Duration(milliseconds: 300),
    DateTime Function()? clock,
  }) : _now = clock ?? DateTime.now;

  @override
  String get currentUid => connections.currentUid;

  @override
  Stream<List<Message>> watchMessages(String connectionId) {
    StreamSubscription<String>? changes;
    late final StreamController<List<Message>> controller;
    controller = StreamController(
      onListen: () async {
        await Future<void>.delayed(delay);
        if (controller.isClosed) return;
        // Take the current list and subscribe in the same step, so a message
        // sent while loading is never lost.
        controller.add(_list(connectionId));
        changes = _changes.stream
            .where((id) => id == connectionId)
            .listen((id) => controller.add(_list(id)));
      },
      onCancel: () async {
        await changes?.cancel();
        await controller.close();
      },
    );
    return controller.stream;
  }

  @override
  Future<Message> sendMessage(String connectionId, String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(text, 'text', 'Message is empty');
    }
    final connection = connections.findById(connectionId);
    if (connection == null || !connection.isAccepted) {
      throw StateError('Can only chat in an accepted connection');
    }

    final message = Message(
      id: 'msg_new_${_nextId++}',
      connectionId: connectionId,
      senderUid: currentUid,
      text: trimmed,
      sentAt: _now(),
    );
    _messages.update(
      connectionId,
      (list) => [...list, message],
      ifAbsent: () => [message],
    );
    connections.recordMessage(message);
    _changes.add(connectionId);
    return message;
  }

  /// Closes the change stream. Call when the service is no longer used.
  void dispose() => _changes.close();

  List<Message> _list(String connectionId) =>
      List.unmodifiable(_messages[connectionId] ?? const <Message>[]);
}

/// Conversations for the accepted connections in `MockConnectionService`.
/// The last message of each matches that connection's `lastMessage`.
Map<String, List<Message>> _seed(DateTime now) {
  const me = MockConnectionService.myUid;

  List<Message> chat(
    String connectionId,
    String partner,
    DateTime last,
    List<(bool mine, String text)> lines,
  ) => [
    for (final (i, (mine, text)) in lines.indexed)
      Message(
        id: '${connectionId}_$i',
        connectionId: connectionId,
        senderUid: mine ? me : partner,
        text: text,
        // Two minutes apart, ending at the connection's last message time.
        sentAt: last.subtract(Duration(minutes: 2 * (lines.length - 1 - i))),
      ),
  ];

  return {
    'conn_deniz': chat(
      'conn_deniz',
      'mock_deniz',
      now.subtract(const Duration(minutes: 12)),
      [
        (true, 'Hi Deniz! We got a 100% match, that has to mean something 😄'),
        (false, 'Haha hi! I saw that too. Do you also sleep before midnight?'),
        (true, 'Usually around 23:30, and I like the room quiet when I study.'),
        (false, 'Same here. I keep things tidy as well.'),
        (false, 'Do you want to meet at the library tomorrow?'),
      ],
    ),
    'conn_aylin': chat(
      'conn_aylin',
      'mock_aylin',
      now.subtract(const Duration(hours: 20)),
      [
        (false, 'Hey! Thanks for accepting.'),
        (true, 'Hi Aylin, nice to meet you!'),
        (false, 'I often have friends over on weekends, is that okay?'),
        (true, 'Sometimes is fine, maybe not during exam weeks.'),
        (false, 'Totally fair. Let me think about it.'),
        (true, 'Sounds good, talk later!'),
      ],
    ),
    'conn_selin': chat(
      'conn_selin',
      'mock_selin',
      now.subtract(const Duration(days: 2)),
      [
        (true, 'So, should we apply together?'),
        (false, 'Yes! We have talked enough, I think we will be fine.'),
        (false, "I pressed We're roommates, your turn :)"),
      ],
    ),
  };
}
