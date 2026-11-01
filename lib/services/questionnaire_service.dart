import '../models/answer_set.dart';
import '../models/question.dart';

/// Loads the questionnaire and saves the current user's answers.
///
/// Screens and providers depend on this interface only. Use
/// `MockQuestionnaireService` until the Firebase version exists; swapping is a
/// one-line change where the provider is created.
abstract class QuestionnaireService {
  /// Active questions grouped into sections, in display order.
  Future<List<QuestionSection>> getQuestions();

  /// The user's saved answers (draft or submitted), or null if none yet.
  Future<AnswerSet?> getMyAnswers();

  /// Saves unfinished answers so the user can continue later. Merges with
  /// answers saved before. Drafts never trigger matching.
  Future<void> saveDraft(
    Map<String, num?> answers, {
    List<String>? dealbreakers,
  });

  /// Submits the finished questionnaire. This replaces all saved answers and,
  /// in the Firebase version, starts matching on the server.
  Future<void> saveAnswers(
    Map<String, num?> answers,
    List<String> dealbreakers,
  );
}
