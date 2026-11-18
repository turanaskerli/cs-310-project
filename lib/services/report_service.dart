import '../models/report.dart';

/// Reporting and blocking other students.
///
/// Screens depend on this interface only. Use `MockReportService` until the
/// Firebase version exists.
abstract class ReportService {
  /// Sends a report about [reportedUid]. When [block] is true the student is
  /// blocked too, in the same step.
  Future<Report> submitReport({
    required String reportedUid,
    required ReportReason reason,
    String details = '',
    bool block = false,
  });

  /// Blocks [uid] without reporting. Blocked students no longer appear in
  /// Matches, Requests or Chats, and cannot contact the user.
  Future<void> block(String uid);

  /// Undoes [block].
  Future<void> unblock(String uid);

  /// The uids the user has blocked. Emits again whenever the set changes.
  Stream<Set<String>> watchBlocked();
}
