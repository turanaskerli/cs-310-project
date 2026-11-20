import 'dart:async';

import '../../models/report.dart';
import '../report_service.dart';

/// Keeps reports and blocks in memory, so the Report or block screen works
/// without Firebase.
class MockReportService implements ReportService {
  static const myUid = 'mock_me';

  /// Simulated network delay, so the screen shows its sending state.
  final Duration delay;

  final DateTime Function() _now;
  final _changes = StreamController<Set<String>>.broadcast();
  final List<Report> _reports = [];
  final Set<String> _blocked = {};
  int _nextId = 1;

  MockReportService({
    this.delay = const Duration(milliseconds: 300),
    DateTime Function()? clock,
  }) : _now = clock ?? DateTime.now;

  /// Every report sent so far, oldest first.
  List<Report> get reports => List.unmodifiable(_reports);

  @override
  Future<Report> submitReport({
    required String reportedUid,
    required ReportReason reason,
    String details = '',
    bool block = false,
  }) async {
    final text = details.trim();
    if (reason == ReportReason.other && text.isEmpty) {
      throw ArgumentError.value(details, 'details', 'required for "other"');
    }
    await Future<void>.delayed(delay);
    final report = Report(
      id: 'report_${_nextId++}',
      reporterUid: myUid,
      reportedUid: reportedUid,
      reason: reason,
      details: text,
      blocked: block,
      createdAt: _now(),
    );
    _reports.add(report);
    if (block) _setBlocked(reportedUid, true);
    return report;
  }

  @override
  Future<void> block(String uid) async {
    await Future<void>.delayed(delay);
    _setBlocked(uid, true);
  }

  @override
  Future<void> unblock(String uid) async {
    await Future<void>.delayed(delay);
    _setBlocked(uid, false);
  }

  @override
  Stream<Set<String>> watchBlocked() async* {
    yield Set.unmodifiable(_blocked);
    yield* _changes.stream;
  }

  /// Closes the change stream. Call when the service is no longer used.
  void dispose() => _changes.close();

  void _setBlocked(String uid, bool blocked) {
    final changed = blocked ? _blocked.add(uid) : _blocked.remove(uid);
    if (changed) _changes.add(Set.unmodifiable(_blocked));
  }
}
