import '../utils/date_parsing.dart';

/// One chat message, stored at `connections/{connectionId}/messages/{id}`.
class Message {
  final String id;
  final String connectionId;
  final String senderUid;
  final String text;
  final DateTime sentAt;

  const Message({
    required this.id,
    required this.connectionId,
    required this.senderUid,
    required this.text,
    required this.sentAt,
  });

  /// Mine go on the right, theirs on the left.
  bool isMine(String myUid) => senderUid == myUid;

  /// [id] is the document id; falls back to `map['id']`. A message still
  /// waiting for its server timestamp gets the current time.
  factory Message.fromMap(Map<String, dynamic> map, {String? id}) => Message(
    id: id ?? map['id'] as String,
    connectionId: map['connectionId'] as String? ?? '',
    senderUid: map['senderUid'] as String,
    text: map['text'] as String? ?? '',
    sentAt: parseDate(map['sentAt']) ?? DateTime.now(),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'connectionId': connectionId,
    'senderUid': senderUid,
    'text': text,
    'sentAt': sentAt.toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      other is Message &&
      other.id == id &&
      other.connectionId == connectionId &&
      other.senderUid == senderUid &&
      other.text == text &&
      other.sentAt == sentAt;

  @override
  int get hashCode => Object.hash(id, connectionId, senderUid, text, sentAt);
}
