import 'package:collection/collection.dart';

import '../utils/date_parsing.dart';
import 'recommendation.dart';

/// Where a roommate request stands.
enum ConnectionStatus {
  /// Sent, waiting for the other student to answer.
  pending,

  /// Accepted: the two students can chat.
  accepted,

  /// The receiver said no.
  declined,

  /// The sender took the request back before it was answered.
  cancelled;

  static ConnectionStatus fromName(String? name) =>
      ConnectionStatus.values.firstWhereOrNull((s) => s.name == name) ??
      ConnectionStatus.pending;
}

/// A roommate request between two students, stored at
/// `connections/{id}`. Once accepted it also holds the chat summary, so the
/// Chats list loads in one query.
///
/// The same document is shared by both students, so the helpers that depend
/// on who is looking take the viewer's uid.
class Connection {
  final String id;

  /// The student who sent the request.
  final String fromUid;

  /// The student who received it.
  final String toUid;

  /// Public info of both students, copied in so the lists need no extra
  /// reads.
  final OtherSummary fromSummary;
  final OtherSummary toSummary;

  final ConnectionStatus status;

  /// Compatibility score from the recommendation, 0–100, if known.
  final int? score;

  /// Students who pressed "We're roommates". Contact details are shown only
  /// when both have.
  final List<String> confirmedBy;

  final String? lastMessage;
  final String? lastMessageSenderUid;
  final DateTime? lastMessageAt;

  /// Messages each student has not read yet, by uid.
  final Map<String, int> unreadCount;

  final DateTime? createdAt;

  /// When the request was accepted, declined or cancelled.
  final DateTime? respondedAt;

  const Connection({
    required this.id,
    required this.fromUid,
    required this.toUid,
    required this.fromSummary,
    required this.toSummary,
    this.status = ConnectionStatus.pending,
    this.score,
    this.confirmedBy = const [],
    this.lastMessage,
    this.lastMessageSenderUid,
    this.lastMessageAt,
    this.unreadCount = const {},
    this.createdAt,
    this.respondedAt,
  });

  List<String> get members => [fromUid, toUid];

  bool get isPending => status == ConnectionStatus.pending;
  bool get isAccepted => status == ConnectionStatus.accepted;

  /// Both students confirmed each other as roommates.
  bool get isConfirmed =>
      isAccepted &&
      confirmedBy.contains(fromUid) &&
      confirmedBy.contains(toUid);

  /// The request was sent to [myUid] (shown in the Incoming tab).
  bool isIncomingFor(String myUid) => toUid == myUid;

  String otherUid(String myUid) => myUid == fromUid ? toUid : fromUid;

  OtherSummary otherSummary(String myUid) =>
      myUid == fromUid ? toSummary : fromSummary;

  bool hasConfirmed(String uid) => confirmedBy.contains(uid);

  /// Shows the unread dot on the Chats list.
  bool hasUnreadFor(String myUid) => (unreadCount[myUid] ?? 0) > 0;

  /// [id] is the document id; falls back to `map['id']`.
  factory Connection.fromMap(Map<String, dynamic> map, {String? id}) =>
      Connection(
        id: id ?? map['id'] as String,
        fromUid: map['fromUid'] as String,
        toUid: map['toUid'] as String,
        fromSummary: OtherSummary.fromMap(
          Map<String, dynamic>.from(map['fromSummary'] as Map? ?? const {}),
        ),
        toSummary: OtherSummary.fromMap(
          Map<String, dynamic>.from(map['toSummary'] as Map? ?? const {}),
        ),
        status: ConnectionStatus.fromName(map['status'] as String?),
        score: (map['score'] as num?)?.toInt(),
        confirmedBy: (map['confirmedBy'] as List? ?? const []).cast<String>(),
        lastMessage: map['lastMessage'] as String?,
        lastMessageSenderUid: map['lastMessageSenderUid'] as String?,
        lastMessageAt: parseDate(map['lastMessageAt']),
        unreadCount: {
          for (final e in (map['unreadCount'] as Map? ?? const {}).entries)
            e.key as String: (e.value as num).toInt(),
        },
        createdAt: parseDate(map['createdAt']),
        respondedAt: parseDate(map['respondedAt']),
      );

  Map<String, dynamic> toMap() => {
    'id': id,
    'fromUid': fromUid,
    'toUid': toUid,
    // Lets Firestore find every connection of a user with one
    // `array-contains` query.
    'members': members,
    'fromSummary': fromSummary.toMap(),
    'toSummary': toSummary.toMap(),
    'status': status.name,
    if (score != null) 'score': score,
    'confirmedBy': confirmedBy,
    if (lastMessage != null) 'lastMessage': lastMessage,
    if (lastMessageSenderUid != null)
      'lastMessageSenderUid': lastMessageSenderUid,
    if (lastMessageAt != null)
      'lastMessageAt': lastMessageAt!.toIso8601String(),
    'unreadCount': unreadCount,
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    if (respondedAt != null) 'respondedAt': respondedAt!.toIso8601String(),
  };

  Connection copyWith({
    ConnectionStatus? status,
    List<String>? confirmedBy,
    String? lastMessage,
    String? lastMessageSenderUid,
    DateTime? lastMessageAt,
    Map<String, int>? unreadCount,
    DateTime? respondedAt,
  }) => Connection(
    id: id,
    fromUid: fromUid,
    toUid: toUid,
    fromSummary: fromSummary,
    toSummary: toSummary,
    status: status ?? this.status,
    score: score,
    confirmedBy: confirmedBy ?? this.confirmedBy,
    lastMessage: lastMessage ?? this.lastMessage,
    lastMessageSenderUid: lastMessageSenderUid ?? this.lastMessageSenderUid,
    lastMessageAt: lastMessageAt ?? this.lastMessageAt,
    unreadCount: unreadCount ?? this.unreadCount,
    createdAt: createdAt,
    respondedAt: respondedAt ?? this.respondedAt,
  );

  @override
  bool operator ==(Object other) =>
      other is Connection &&
      other.id == id &&
      other.fromUid == fromUid &&
      other.toUid == toUid &&
      other.fromSummary == fromSummary &&
      other.toSummary == toSummary &&
      other.status == status &&
      other.score == score &&
      const ListEquality<String>().equals(other.confirmedBy, confirmedBy) &&
      other.lastMessage == lastMessage &&
      other.lastMessageSenderUid == lastMessageSenderUid &&
      other.lastMessageAt == lastMessageAt &&
      const MapEquality<String, int>().equals(other.unreadCount, unreadCount) &&
      other.createdAt == createdAt &&
      other.respondedAt == respondedAt;

  @override
  int get hashCode => Object.hash(
    id,
    fromUid,
    toUid,
    fromSummary,
    toSummary,
    status,
    score,
    Object.hashAll(confirmedBy),
    lastMessage,
    lastMessageSenderUid,
    lastMessageAt,
    Object.hashAllUnordered(
      unreadCount.entries.map((e) => Object.hash(e.key, e.value)),
    ),
    createdAt,
    respondedAt,
  );
}

/// The partner's private details, shown on the Roommate confirmed screen only
/// after both students confirm. Stored apart from the profile so nobody else
/// can read them.
class RoommateContact {
  /// Entered in the dorm application to request each other.
  final String studentId;
  final String? phone;
  final String? instagram;

  const RoommateContact({required this.studentId, this.phone, this.instagram});

  factory RoommateContact.fromMap(Map<String, dynamic> map) => RoommateContact(
    studentId: map['studentId'] as String? ?? '',
    phone: map['phone'] as String?,
    instagram: map['instagram'] as String?,
  );

  Map<String, dynamic> toMap() => {
    'studentId': studentId,
    'phone': phone,
    'instagram': instagram,
  };

  @override
  bool operator ==(Object other) =>
      other is RoommateContact &&
      other.studentId == studentId &&
      other.phone == phone &&
      other.instagram == instagram;

  @override
  int get hashCode => Object.hash(studentId, phone, instagram);
}
