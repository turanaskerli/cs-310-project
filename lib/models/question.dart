import 'package:collection/collection.dart';

/// How a question is presented and answered.
enum QuestionType {
  /// Pick exactly one option.
  single,

  /// A 1–5 slider or row of buttons.
  scale,

  /// Pick one of two trade-offs.
  forced,

  /// Pick any number of options (used for the dealbreaker selection).
  multi;

  static QuestionType fromName(String name) => QuestionType.values.firstWhere(
    (t) => t.name == name,
    orElse: () => throw FormatException('Unknown question type: $name'),
  );
}

/// What a question measures.
///
/// For behavior-vs-tolerance traits (cleanliness, noise, guests) the scale is
/// "impact on the roommate": a `self` value of 5 means "I produce a lot of
/// mess/noise/guests", and a `tolerance` value of 5 means "I can accept a lot".
enum QuestionDirection {
  /// The user's own behavior.
  self,

  /// What the user accepts from a roommate.
  tolerance,

  /// A yes/no-style fact used by dealbreaker filters (e.g. "I smoke").
  attribute,

  /// The user's list of dealbreakers; stored in `AnswerSet.dealbreakers`.
  selection;

  static QuestionDirection fromName(String name) =>
      QuestionDirection.values.firstWhere(
        (d) => d.name == name,
        orElse: () => throw FormatException('Unknown direction: $name'),
      );
}

/// One answer choice.
///
/// [value] is a number on the trait scale (1–5) for scored questions, a small
/// number for attribute questions (0 = no), a dealbreaker key string for the
/// selection question, or null for "Prefer not to say".
class QuestionOption {
  final String label;
  final Object? value;

  /// If true, choosing this option clears all others (e.g. "None of these").
  final bool exclusive;

  const QuestionOption({
    required this.label,
    required this.value,
    this.exclusive = false,
  });

  num? get numValue => value is num ? value as num : null;
  String? get stringValue => value is String ? value as String : null;

  factory QuestionOption.fromMap(Map<String, dynamic> map) => QuestionOption(
    label: map['label'] as String,
    value: map['value'],
    exclusive: map['exclusive'] as bool? ?? false,
  );

  Map<String, dynamic> toMap() => {
    'label': label,
    'value': value,
    if (exclusive) 'exclusive': true,
  };

  @override
  bool operator ==(Object other) =>
      other is QuestionOption &&
      other.label == label &&
      other.value == value &&
      other.exclusive == exclusive;

  @override
  int get hashCode => Object.hash(label, value, exclusive);
}

/// A question from the `questions` collection.
class Question {
  final String id;
  final String section;

  /// Copied onto each question by the seed script so one query can sort the
  /// whole questionnaire.
  final String sectionTitle;
  final int sectionOrder;

  /// Position inside the section.
  final int order;
  final String text;
  final QuestionType type;
  final List<QuestionOption> options;
  final String trait;
  final QuestionDirection direction;

  /// Weight of this question inside its trait.
  final double weight;
  final bool active;

  /// Optional questions may be skipped.
  final bool optional;

  /// For attribute questions: the dealbreaker key this answer can trigger.
  final String? flag;

  /// For attribute questions: answers >= this value set [flag].
  final num? flagMinValue;

  const Question({
    required this.id,
    required this.section,
    this.sectionTitle = '',
    this.sectionOrder = 0,
    required this.order,
    required this.text,
    required this.type,
    required this.options,
    required this.trait,
    required this.direction,
    this.weight = 1,
    this.active = true,
    this.optional = false,
    this.flag,
    this.flagMinValue,
  });

  /// Whether this question feeds a trait score.
  bool get isScored =>
      weight > 0 &&
      (direction == QuestionDirection.self ||
          direction == QuestionDirection.tolerance);

  bool get isDealbreakerSelection => direction == QuestionDirection.selection;

  QuestionOption? optionFor(Object? value) =>
      options.firstWhereOrNull((o) => o.value == value);

  /// [id] falls back to `map['id']` so the same code reads Firestore docs and
  /// the seed JSON.
  factory Question.fromMap(Map<String, dynamic> map, {String? id}) => Question(
    id: id ?? map['id'] as String,
    section: map['section'] as String,
    sectionTitle: map['sectionTitle'] as String? ?? '',
    sectionOrder: (map['sectionOrder'] as num?)?.toInt() ?? 0,
    order: (map['order'] as num).toInt(),
    text: map['text'] as String,
    type: QuestionType.fromName(map['type'] as String),
    options: (map['options'] as List)
        .map((o) => QuestionOption.fromMap(Map<String, dynamic>.from(o)))
        .toList(),
    trait: map['trait'] as String,
    direction: QuestionDirection.fromName(map['direction'] as String),
    weight: (map['weight'] as num?)?.toDouble() ?? 1,
    active: map['active'] as bool? ?? true,
    optional: map['optional'] as bool? ?? false,
    flag: map['flag'] as String?,
    flagMinValue: map['flagMinValue'] as num?,
  );

  Map<String, dynamic> toMap() => {
    'section': section,
    'sectionTitle': sectionTitle,
    'sectionOrder': sectionOrder,
    'order': order,
    'text': text,
    'type': type.name,
    'options': options.map((o) => o.toMap()).toList(),
    'trait': trait,
    'direction': direction.name,
    'weight': weight,
    'active': active,
    'optional': optional,
    if (flag != null) 'flag': flag,
    if (flagMinValue != null) 'flagMinValue': flagMinValue,
  };

  @override
  bool operator ==(Object other) =>
      other is Question &&
      other.id == id &&
      other.section == section &&
      other.sectionTitle == sectionTitle &&
      other.sectionOrder == sectionOrder &&
      other.order == order &&
      other.text == text &&
      other.type == type &&
      const ListEquality<QuestionOption>().equals(other.options, options) &&
      other.trait == trait &&
      other.direction == direction &&
      other.weight == weight &&
      other.active == active &&
      other.optional == optional &&
      other.flag == flag &&
      other.flagMinValue == flagMinValue;

  @override
  int get hashCode => Object.hash(
    id,
    section,
    order,
    text,
    type,
    trait,
    direction,
    weight,
    active,
    Object.hashAll(options),
  );
}

/// One screen of the questionnaire.
class QuestionSection {
  final String id;
  final String title;
  final int order;
  final List<Question> questions;

  const QuestionSection({
    required this.id,
    required this.title,
    required this.order,
    required this.questions,
  });

  /// Groups active questions into sections, sorted by section and question
  /// order.
  static List<QuestionSection> group(Iterable<Question> questions) {
    final bySection = groupBy(
      questions.where((q) => q.active),
      (Question q) => q.section,
    );
    final sections = bySection.entries.map((e) {
      final sorted = [...e.value]..sort((a, b) => a.order.compareTo(b.order));
      final first = sorted.first;
      return QuestionSection(
        id: e.key,
        title: first.sectionTitle.isEmpty ? e.key : first.sectionTitle,
        order: first.sectionOrder,
        questions: sorted,
      );
    }).toList()..sort((a, b) => a.order.compareTo(b.order));
    return sections;
  }
}
