import 'package:flutter_test/flutter_test.dart';
import 'package:roommate_finder/models/answer_set.dart';
import 'package:roommate_finder/models/question.dart';

void main() {
  Question make(
    String id, {
    bool optional = false,
    QuestionDirection direction = QuestionDirection.self,
  }) => Question(
    id: id,
    section: 's',
    order: 1,
    text: id,
    type: QuestionType.single,
    options: const [],
    trait: 't',
    direction: direction,
    optional: optional,
  );

  test('round trip keeps "prefer not to say" (null) answers', () {
    const set = AnswerSet(
      answers: {'sleep_1': 2, 'db_alcohol': null},
      dealbreakers: ['smoking'],
      isDraft: false,
    );
    final back = AnswerSet.fromMap(set.toMap());
    expect(back, set);
    expect(back.isAnswered('db_alcohol'), isTrue);
    expect(back.isAnswered('sleep_2'), isFalse);
  });

  test('fromMap drops "none" and reads timestamp-like dates', () {
    final set = AnswerSet.fromMap({
      'answers': {'a': 1},
      'dealbreakers': ['none'],
      'updatedAt': _FakeTimestamp(DateTime(2026, 10, 30)),
    });
    expect(set.dealbreakers, isEmpty);
    expect(set.updatedAt, DateTime(2026, 10, 30));
    expect(set.isDraft, isTrue);
  });

  test('isComplete ignores optional and dealbreaker selection questions', () {
    final questions = [
      make('q1'),
      make('q2', optional: true),
      make('db_select', direction: QuestionDirection.selection),
    ];
    expect(const AnswerSet().isComplete(questions), isFalse);
    expect(const AnswerSet().withAnswer('q1', 3).isComplete(questions), isTrue);
  });
}

/// Stands in for Firestore's Timestamp, which has a toDate() method.
class _FakeTimestamp {
  final DateTime date;
  _FakeTimestamp(this.date);
  DateTime toDate() => date;
}
