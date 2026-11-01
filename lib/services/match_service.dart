import '../models/recommendation.dart';

/// The current user's suggested roommates.
///
/// Screens and providers depend on this interface only. Use `MockMatchService`
/// until the Firebase version exists.
abstract class MatchService {
  /// Up to 25 recommendations, best score first, without dismissed ones.
  /// Emits again whenever the list changes.
  Stream<List<Recommendation>> watchRecommendations();

  /// Side-by-side trait comparison for the match detail screen. Empty if
  /// [otherUid] is not one of the user's recommendations.
  Future<List<TraitComparison>> getComparison(String otherUid);

  /// Hides a recommendation from the list.
  Future<void> dismiss(String otherUid);
}
