import 'package:flutter_test/flutter_test.dart';
import 'package:roommate_finder/models/report.dart';
import 'package:roommate_finder/services/mock/mock_report_service.dart';

void main() {
  late MockReportService service;

  setUp(
    () => service = MockReportService(
      delay: Duration.zero,
      clock: () => DateTime.utc(2026, 11, 18),
    ),
  );
  tearDown(() => service.dispose());

  test('submitReport stores the report and can block', () async {
    final report = await service.submitReport(
      reportedUid: 'mock_can',
      reason: ReportReason.spam,
      details: '  links  ',
      block: true,
    );

    expect(report.reporterUid, MockReportService.myUid);
    expect(report.details, 'links');
    expect(report.createdAt, DateTime.utc(2026, 11, 18));
    expect(service.reports, [report]);
    expect(await service.watchBlocked().first, {'mock_can'});
  });

  test('"other" needs details', () {
    expect(
      () => service.submitReport(
        reportedUid: 'mock_can',
        reason: ReportReason.other,
        details: ' ',
      ),
      throwsArgumentError,
    );
  });

  test('block and unblock update watchBlocked', () async {
    final states = service.watchBlocked().take(3).toList();
    await Future<void>.delayed(Duration.zero);

    await service.block('mock_elif');
    await service.unblock('mock_elif');

    expect(await states, [
      <String>{},
      {'mock_elif'},
      <String>{},
    ]);
  });
}
