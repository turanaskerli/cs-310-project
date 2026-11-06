import '../models/message.dart';

/// Messages between two students whose request was accepted.
///
/// Screens and providers depend on this interface only. Use `MockChatService`
/// until the Firebase version exists.
abstract class ChatService {
  /// The signed-in student's uid, for [Message.isMine].
  String get currentUid;

  /// All messages of a connection, oldest first. Emits again on every new
  /// message.
  Stream<List<Message>> watchMessages(String connectionId);

  /// Sends [text] (trimmed) as the current user and returns the stored
  /// message. Throws [ArgumentError] for empty text and [StateError] if the
  /// connection is not accepted.
  Future<Message> sendMessage(String connectionId, String text);
}
