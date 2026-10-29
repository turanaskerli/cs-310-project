import 'package:collection/collection.dart';

import '../utils/date_parsing.dart';
import 'question.dart';

/// A user's questionnaire answers, stored at `answers/{uid}`.
class AnswerSet {
  /// questionId → chosen option value. A key with a null value means the user
  /// answered "Prefer not to say"; a missing key means not answered yet.
  final Map<String, num?> answers;

  /// Dealbreaker keys the user refuses (e.g. 'smoking'). Never contains
  /// 'none'; an empty list is a valid answer.
  final List<String> dealbreakers;

  /// Drafts do not trigger matching.
  final bool isDraft;

  /// Set by the server; [toMap] leaves it out so the service can write a
  /// server timestamp.
  final DateTime? updatedAt;

  const AnswerSet({
    this.answers = const {},
    this.dealbreakers = const [],
    this.isDraft = true,
    this.updatedAt,
  });

  bool isAnswered(String questionId) => answers.containsKey(questionId);

  /// True when every active, non-optional question that belongs in [answers]
  /// has been answered. The dealbreaker selection is always complete, because
  /// "none" is a valid choice.
  bool isComplete(Iterable<Question> questions) => questions
      .where((q) => q.active && !q.optional && !q.isDealbreakerSelection)
      .every((q) => isAnswered(q.id));

  AnswerSet withAnswer(String questionId, num? value) =>
      copyWith(answers: {...answers, questionId: value});

  AnswerSet copyWith({
    Map<String, num?>? answers,
    List<String>? dealbreakers,
    bool? isDraft,
    DateTime? updatedAt,
  }) => AnswerSet(
    answers: answers ?? this.answers,
    dealbreakers: dealbreakers ?? this.dealbreakers,
    isDraft: isDraft ?? this.isDraft,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  factory AnswerSet.fromMap(Map<String, dynamic> map) => AnswerSet(
    answers: (map['answers'] as Map? ?? const {}).map(
      (k, v) => MapEntry(k as String, v as num?),
    ),
    dealbreakers: (map['dealbreakers'] as List? ?? const [])
        .cast<String>()
        .where((d) => d != 'none')
        .toList(),
    isDraft: map['isDraft'] as bool? ?? true,
    updatedAt: parseDate(map['updatedAt']),
  );

  Map<String, dynamic> toMap() => {
    'answers': answers,
    'dealbreakers': dealbreakers,
    'isDraft': isDraft,
  };

  @override
  bool operator ==(Object other) =>
      other is AnswerSet &&
      const MapEquality<String, num?>().equals(other.answers, answers) &&
      const ListEquality<String>().equals(other.dealbreakers, dealbreakers) &&
      other.isDraft == isDraft &&
      other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(
    const MapEquality<String, num?>().hash(answers),
    Object.hashAll(dealbreakers),
    isDraft,
    updatedAt,
  );
}
