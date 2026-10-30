import 'package:collection/collection.dart';

import '../utils/date_parsing.dart';

/// The other student's public info, copied into the recommendation so the
/// match list loads in one query.
class OtherSummary {
  final String name;
  final String? photoUrl;
  final String program;
  final int year;

  const OtherSummary({
    required this.name,
    this.photoUrl,
    this.program = '',
    this.year = 0,
  });

  factory OtherSummary.fromMap(Map<String, dynamic> map) => OtherSummary(
    name: map['name'] as String? ?? '',
    photoUrl: map['photoUrl'] as String?,
    program: map['program'] as String? ?? '',
    year: (map['year'] as num?)?.toInt() ?? 0,
  );

  Map<String, dynamic> toMap() => {
    'name': name,
    'photoUrl': photoUrl,
    'program': program,
    'year': year,
  };

  @override
  bool operator ==(Object other) =>
      other is OtherSummary &&
      other.name == name &&
      other.photoUrl == photoUrl &&
      other.program == program &&
      other.year == year;

  @override
  int get hashCode => Object.hash(name, photoUrl, program, year);
}

/// One row of the side-by-side comparison on the match detail screen.
///
/// Computed by the matching function and stored in the recommendation,
/// because the other user's `traits` document is not readable from the app.
class TraitComparison {
  final String trait;

  /// Human-readable trait name, e.g. 'Sleep schedule'.
  final String label;

  /// Both users' `self` scores, 1–5.
  final double mine;
  final double theirs;

  /// How well this trait fits for the pair, 0–1.
  final double fit;

  const TraitComparison({
    required this.trait,
    required this.label,
    required this.mine,
    required this.theirs,
    required this.fit,
  });

  factory TraitComparison.fromMap(Map<String, dynamic> map) => TraitComparison(
    trait: map['trait'] as String,
    label: map['label'] as String? ?? map['trait'] as String,
    mine: (map['mine'] as num).toDouble(),
    theirs: (map['theirs'] as num).toDouble(),
    fit: (map['fit'] as num).toDouble(),
  );

  Map<String, dynamic> toMap() => {
    'trait': trait,
    'label': label,
    'mine': mine,
    'theirs': theirs,
    'fit': fit,
  };

  @override
  bool operator ==(Object other) =>
      other is TraitComparison &&
      other.trait == trait &&
      other.label == label &&
      other.mine == mine &&
      other.theirs == theirs &&
      other.fit == fit;

  @override
  int get hashCode => Object.hash(trait, label, mine, theirs, fit);
}

/// A suggested roommate, stored at
/// `recommendations/{uid}/candidates/{otherUid}`. Written by Cloud Functions;
/// the owner may only change [dismissed].
class Recommendation {
  final String otherUid;

  /// Final compatibility score, 0–100.
  final int score;

  /// Up to 3 positive reasons, plus at most one heads-up.
  final List<String> reasons;
  final OtherSummary otherSummary;
  final List<TraitComparison> comparison;
  final bool dismissed;
  final DateTime? computedAt;

  const Recommendation({
    required this.otherUid,
    required this.score,
    required this.reasons,
    required this.otherSummary,
    this.comparison = const [],
    this.dismissed = false,
    this.computedAt,
  });

  /// [id] is the document id (the other user's uid); falls back to
  /// `map['otherUid']`.
  factory Recommendation.fromMap(Map<String, dynamic> map, {String? id}) =>
      Recommendation(
        otherUid: id ?? map['otherUid'] as String,
        score: (map['score'] as num).toInt(),
        reasons: (map['reasons'] as List? ?? const []).cast<String>(),
        otherSummary: OtherSummary.fromMap(
          Map<String, dynamic>.from(map['otherSummary'] as Map? ?? const {}),
        ),
        comparison: (map['comparison'] as List? ?? const [])
            .map((c) => TraitComparison.fromMap(Map<String, dynamic>.from(c)))
            .toList(),
        dismissed: map['dismissed'] as bool? ?? false,
        computedAt: parseDate(map['computedAt']),
      );

  Map<String, dynamic> toMap() => {
    'otherUid': otherUid,
    'score': score,
    'reasons': reasons,
    'otherSummary': otherSummary.toMap(),
    'comparison': comparison.map((c) => c.toMap()).toList(),
    'dismissed': dismissed,
    if (computedAt != null) 'computedAt': computedAt!.toIso8601String(),
  };

  Recommendation copyWith({bool? dismissed}) => Recommendation(
    otherUid: otherUid,
    score: score,
    reasons: reasons,
    otherSummary: otherSummary,
    comparison: comparison,
    dismissed: dismissed ?? this.dismissed,
    computedAt: computedAt,
  );

  @override
  bool operator ==(Object other) =>
      other is Recommendation &&
      other.otherUid == otherUid &&
      other.score == score &&
      const ListEquality<String>().equals(other.reasons, reasons) &&
      other.otherSummary == otherSummary &&
      const ListEquality<TraitComparison>().equals(
        other.comparison,
        comparison,
      ) &&
      other.dismissed == dismissed &&
      other.computedAt == computedAt;

  @override
  int get hashCode => Object.hash(
    otherUid,
    score,
    Object.hashAll(reasons),
    otherSummary,
    Object.hashAll(comparison),
    dismissed,
    computedAt,
  );
}
