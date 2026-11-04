import 'package:flutter_test/flutter_test.dart';
import 'package:roommate_finder/services/mock/mock_match_service.dart';

void main() {
  late MockMatchService service;

  setUp(() => service = MockMatchService(delay: Duration.zero));
  tearDown(() => service.dispose());

  test('emits ten matches, best score first', () async {
    final matches = await service.watchRecommendations().first;

    expect(matches, hasLength(10));
    final scores = matches.map((m) => m.score).toList();
    expect(scores, [...scores]..sort((a, b) => b.compareTo(a)));
    expect(scores.every((s) => s >= 0 && s <= 100), isTrue);
    expect(matches.first.otherUid, 'mock_deniz');
    expect(matches.first.score, 100);
  });

  test('every match has a photo, reasons and 8 compared traits', () async {
    final matches = await service.watchRecommendations().first;

    for (final m in matches) {
      expect(
        m.otherSummary.photoUrl,
        startsWith('https://'),
        reason: m.otherUid,
      );
      expect(m.reasons, isNotEmpty, reason: m.otherUid);
      expect(m.reasons.length, lessThanOrEqualTo(4), reason: m.otherUid);
      expect(m.comparison, hasLength(8), reason: m.otherUid);
    }
  });

  test('a very different student gets a heads-up reason', () async {
    final matches = await service.watchRecommendations().first;
    final burak = matches.singleWhere((m) => m.otherUid == 'mock_burak');

    expect(burak.score, lessThan(50));
    expect(burak.reasons.last, contains('talk about it in chat'));
  });

  test('dismiss removes the match from the stream', () async {
    final emitted = service.watchRecommendations().take(2).toList();
    await Future<void>.delayed(Duration.zero);
    await service.dismiss('mock_deniz');

    final lists = await emitted;
    expect(lists.first, hasLength(10));
    expect(lists.last, hasLength(9));
    expect(lists.last.map((m) => m.otherUid), isNot(contains('mock_deniz')));
  });

  test('getComparison returns the stored comparison', () async {
    final comparison = await service.getComparison('mock_elif');

    expect(comparison.map((c) => c.trait).first, 'sleep');
    expect(comparison.every((c) => c.fit >= 0 && c.fit <= 1), isTrue);
    expect(await service.getComparison('unknown'), isEmpty);
  });
}
