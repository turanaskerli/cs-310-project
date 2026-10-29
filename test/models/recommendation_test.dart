import 'package:flutter_test/flutter_test.dart';
import 'package:roommate_finder/models/recommendation.dart';

void main() {
  final rec = Recommendation(
    otherUid: 'u2',
    score: 87,
    reasons: ['You both usually sleep before midnight'],
    otherSummary: const OtherSummary(
      name: 'Ayşe',
      program: 'Computer Science',
      year: 1,
    ),
    comparison: const [
      TraitComparison(
        trait: 'sleep',
        label: 'Sleep schedule',
        mine: 2,
        theirs: 2.5,
        fit: 0.875,
      ),
    ],
    computedAt: DateTime.utc(2026, 10, 30, 12),
  );

  test('round trip', () {
    expect(Recommendation.fromMap(rec.toMap()), rec);
  });

  test('document id wins over the otherUid field', () {
    expect(Recommendation.fromMap(rec.toMap(), id: 'docId').otherUid, 'docId');
  });

  test('missing optional fields get defaults', () {
    final r = Recommendation.fromMap({'score': 50}, id: 'u3');
    expect(r.reasons, isEmpty);
    expect(r.comparison, isEmpty);
    expect(r.dismissed, isFalse);
    expect(r.otherSummary.name, '');
  });

  test('copyWith only changes dismissed', () {
    final d = rec.copyWith(dismissed: true);
    expect(d.dismissed, isTrue);
    expect(d.copyWith(dismissed: false), rec);
  });
}
