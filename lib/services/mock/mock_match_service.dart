import 'dart:async';

import 'package:collection/collection.dart';

import '../../models/recommendation.dart';
import '../match_service.dart';

/// Ten fake students, so the Matches and Match detail screens work without
/// Firebase.
///
/// Scores, reasons and comparisons are worked out from made-up trait values
/// with a simplified version of the real scoring, so they agree with each
/// other on screen. The real engine runs in Cloud Functions.
class MockMatchService implements MatchService {
  /// Simulated network delay, so screens show their loading state.
  final Duration delay;

  final _changes = StreamController<List<Recommendation>>.broadcast();
  late List<Recommendation> _all = _fakeStudents.map(_build).toList();

  MockMatchService({this.delay = const Duration(milliseconds: 300)});

  @override
  Stream<List<Recommendation>> watchRecommendations() {
    StreamSubscription<List<Recommendation>>? changes;
    late final StreamController<List<Recommendation>> controller;
    controller = StreamController(
      onListen: () async {
        await Future<void>.delayed(delay);
        if (controller.isClosed) return;
        // Take the current list and subscribe in the same step, so a change
        // made while loading is never lost.
        controller.add(_visible());
        changes = _changes.stream.listen(controller.add);
      },
      onCancel: () async {
        await changes?.cancel();
        await controller.close();
      },
    );
    return controller.stream;
  }

  @override
  Future<List<TraitComparison>> getComparison(String otherUid) async {
    await Future<void>.delayed(delay);
    return _all.firstWhereOrNull((r) => r.otherUid == otherUid)?.comparison ??
        const [];
  }

  @override
  Future<void> dismiss(String otherUid) async {
    _all = [
      for (final r in _all)
        r.otherUid == otherUid ? r.copyWith(dismissed: true) : r,
    ];
    _changes.add(_visible());
  }

  /// Closes the change stream. Call when the service is no longer used.
  void dispose() => _changes.close();

  List<Recommendation> _visible() =>
      (_all.where((r) => !r.dismissed).toList()
            ..sort((a, b) => b.score.compareTo(a.score)))
          .take(25)
          .toList();
}

/// Trait key, label, weight (from the architecture doc), and the reason shown
/// when two students are similar.
typedef _Trait = ({String key, String label, double weight, String reason});

const List<_Trait> _traits = [
  (
    key: 'sleep',
    label: 'Sleep schedule',
    weight: 3,
    reason: 'You keep similar sleep hours',
  ),
  (
    key: 'cleanliness',
    label: 'Cleanliness',
    weight: 3,
    reason: 'You have similar cleaning standards',
  ),
  (
    key: 'noise',
    label: 'Noise',
    weight: 2,
    reason: 'You both like a similar noise level in the room',
  ),
  (
    key: 'guests',
    label: 'Guests',
    weight: 2,
    reason: 'You feel the same about having friends over',
  ),
  (
    key: 'study',
    label: 'Studying in the room',
    weight: 1.5,
    reason: 'You study in the room about as often',
  ),
  (
    key: 'sharing',
    label: 'Sharing',
    weight: 1,
    reason: 'You agree on sharing things',
  ),
  (
    key: 'social',
    label: 'Social life',
    weight: 1,
    reason: 'You want a similar kind of roommate friendship',
  ),
  (
    key: 'temperature',
    label: 'Temperature & air',
    weight: 1,
    reason: 'You like the room at a similar temperature',
  ),
];

/// The signed-in user's made-up trait values, in [_traits] order (1–5).
const _myTraits = [2, 2, 2, 3, 4, 3, 3, 3];

typedef _FakeStudent = ({
  String uid,
  String name,
  String program,
  int year,
  int photo,
  List<int> traits,
});

/// Photos come from a placeholder avatar service. Real matches are always the
/// same gender as the user; these placeholders are mixed.
const List<_FakeStudent> _fakeStudents = [
  (
    uid: 'mock_deniz',
    name: 'Deniz Yılmaz',
    program: 'Computer Science and Engineering',
    year: 1,
    photo: 11,
    traits: [2, 2, 2, 3, 4, 3, 3, 3],
  ),
  (
    uid: 'mock_elif',
    name: 'Elif Kaya',
    program: 'Economics',
    year: 1,
    photo: 5,
    traits: [2, 1, 2, 2, 4, 3, 4, 3],
  ),
  (
    uid: 'mock_mehmet',
    name: 'Mehmet Demir',
    program: 'Industrial Engineering',
    year: 1,
    photo: 12,
    traits: [3, 2, 2, 3, 3, 2, 3, 2],
  ),
  (
    uid: 'mock_zeynep',
    name: 'Zeynep Arslan',
    program: 'Molecular Biology, Genetics and Bioengineering',
    year: 1,
    photo: 9,
    traits: [2, 3, 1, 2, 5, 4, 2, 3],
  ),
  (
    uid: 'mock_can',
    name: 'Can Öztürk',
    program: 'Mechatronics Engineering',
    year: 2,
    photo: 13,
    traits: [3, 3, 3, 3, 3, 3, 4, 4],
  ),
  (
    uid: 'mock_aylin',
    name: 'Aylin Şahin',
    program: 'Political Science',
    year: 1,
    photo: 16,
    traits: [1, 2, 2, 4, 2, 4, 5, 3],
  ),
  (
    uid: 'mock_emre',
    name: 'Emre Çelik',
    program: 'Management',
    year: 1,
    photo: 14,
    traits: [4, 3, 3, 4, 2, 3, 4, 2],
  ),
  (
    uid: 'mock_selin',
    name: 'Selin Koç',
    program: 'Visual Arts and Visual Communication Design',
    year: 1,
    photo: 20,
    traits: [4, 4, 3, 3, 3, 5, 3, 4],
  ),
  (
    uid: 'mock_lukas',
    name: 'Lukas Weber',
    program: 'Computer Science (exchange)',
    year: 3,
    photo: 15,
    traits: [3, 2, 4, 2, 4, 2, 2, 1],
  ),
  (
    uid: 'mock_burak',
    name: 'Burak Aydın',
    program: 'Electronics Engineering',
    year: 1,
    photo: 33,
    traits: [5, 4, 4, 5, 1, 4, 5, 2],
  ),
];

Recommendation _build(_FakeStudent s) {
  final comparison = [
    for (final (i, t) in _traits.indexed)
      TraitComparison(
        trait: t.key,
        label: t.label,
        mine: _myTraits[i].toDouble(),
        theirs: s.traits[i].toDouble(),
        fit: 1 - (_myTraits[i] - s.traits[i]).abs() / 4,
      ),
  ];

  final totalWeight = _traits.map((t) => t.weight).sum;
  final weightedFit = [
    for (final (i, t) in _traits.indexed) t.weight * comparison[i].fit,
  ].sum;

  return Recommendation(
    otherUid: s.uid,
    score: (weightedFit / totalWeight * 100).round(),
    reasons: _reasons(comparison),
    otherSummary: OtherSummary(
      name: s.name,
      photoUrl: 'https://i.pravatar.cc/300?img=${s.photo}',
      program: s.program,
      year: s.year,
    ),
    comparison: comparison,
    computedAt: DateTime(2026, 11, 1),
  );
}

/// Up to 3 traits with fit >= 0.8 (heaviest first), plus one heads-up for the
/// worst trait if its fit is below 0.5.
List<String> _reasons(List<TraitComparison> comparison) {
  final ranked = [
    for (final (i, t) in _traits.indexed) (trait: t, fit: comparison[i].fit),
  ];
  final reasons =
      (ranked.where((r) => r.fit >= 0.8).toList()..sort(
            (a, b) =>
                (b.trait.weight * b.fit).compareTo(a.trait.weight * a.fit),
          ))
          .take(3)
          .map((r) => r.trait.reason)
          .toList();

  final worst = minBy(ranked, (r) => r.fit)!;
  if (worst.fit < 0.5) {
    reasons.add(
      'You differ on ${worst.trait.label.toLowerCase()}; talk about it in chat',
    );
  }
  return reasons;
}
