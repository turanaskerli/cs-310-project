import '../models/connection.dart';
import '../models/recommendation.dart';

/// Roommate requests between the current user and other students, and the
/// roommate confirmation at the end.
///
/// Screens and providers depend on this interface only. Use
/// `MockConnectionService` until the Firebase version exists.
abstract class ConnectionService {
  /// The signed-in student's uid, used with the viewer-dependent helpers on
  /// [Connection].
  String get currentUid;

  /// Pending requests other students sent me, newest first.
  Stream<List<Connection>> watchIncomingRequests();

  /// Pending requests I sent, newest first.
  Stream<List<Connection>> watchOutgoingRequests();

  /// Accepted connections for the Chats list, latest message first.
  Stream<List<Connection>> watchChats();

  /// One connection, e.g. for the Chat screen's "We're roommates" state.
  /// Emits null if it does not exist.
  Stream<Connection?> watchConnection(String connectionId);

  /// Sends a request to [otherUid]. If a pending or accepted connection with
  /// them already exists, returns that one instead of creating a second.
  Future<Connection> sendRequest({
    required String otherUid,
    required OtherSummary other,
    int? score,
  });

  /// Accepts an incoming request, which opens the chat.
  Future<void> accept(String connectionId);

  /// Declines an incoming request; it leaves the Incoming tab.
  Future<void> decline(String connectionId);

  /// Takes back an outgoing request; it leaves the Outgoing tab.
  Future<void> cancel(String connectionId);

  /// Records that I confirmed the partner as my roommate. Returns the updated
  /// connection; check [Connection.isConfirmed] to see if both have.
  Future<Connection> confirmRoommate(String connectionId);

  /// The partner's student ID and contacts, or null until both students
  /// confirmed.
  Future<RoommateContact?> getPartnerContact(String connectionId);

  /// Clears my unread count, called when I open the chat.
  Future<void> markRead(String connectionId);
}
