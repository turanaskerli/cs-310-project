import 'package:flutter_test/flutter_test.dart';
import 'package:roommate_finder/models/report.dart';

void main() {
  final report = Report(
    id: 'r1',
    reporterUid: 'me',
    reportedUid: 'them',
    reason: ReportReason.harassment,
    details: 'Rude messages',
    blocked: true,
    createdAt: DateTime.utc(2026, 11, 18),
  );

  test('round trip', () {
    expect(Report.fromMap(report.toMap()), report);
  });

  test('document id wins and unknown reasons fall back to other', () {
    final map = report.toMap()..['reason'] = 'nope';
    final parsed = Report.fromMap(map, id: 'doc');
    expect(parsed.id, 'doc');
    expect(parsed.reason, ReportReason.other);
  });
}
