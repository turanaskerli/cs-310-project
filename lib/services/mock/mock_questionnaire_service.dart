import 'package:flutter/services.dart';

import '../../models/answer_set.dart';
import '../../models/question.dart';
import '../question_bank.dart';
import '../questionnaire_service.dart';

/// Serves the real question bank from `assets/data/questions.json` and keeps
/// answers in memory, so the questionnaire screens work without Firebase.
class MockQuestionnaireService implements QuestionnaireService {
  final AssetBundle _bundle;

  /// Simulated network delay, so screens show their loading state.
  final Duration delay;

  List<QuestionSection>? _sections;
  AnswerSet? _answers;

  MockQuestionnaireService({
    AssetBundle? bundle,
    this.delay = const Duration(milliseconds: 300),
    AnswerSet? initialAnswers,
  }) : _bundle = bundle ?? rootBundle,
       _answers = initialAnswers;

  @override
  Future<List<QuestionSection>> getQuestions() async {
    await _wait();
    return _sections ??= await QuestionBank.load(_bundle);
  }

  @override
  Future<AnswerSet?> getMyAnswers() async {
    await _wait();
    return _answers;
  }

  @override
  Future<void> saveDraft(
    Map<String, num?> answers, {
    List<String>? dealbreakers,
  }) async {
    await _wait();
    final previous = _answers ?? const AnswerSet();
    _answers = AnswerSet(
      answers: {...previous.answers, ...answers},
      dealbreakers: _withoutNone(dealbreakers ?? previous.dealbreakers),
      isDraft: true,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> saveAnswers(
    Map<String, num?> answers,
    List<String> dealbreakers,
  ) async {
    await _wait();
    _answers = AnswerSet(
      answers: Map.of(answers),
      dealbreakers: _withoutNone(dealbreakers),
      isDraft: false,
      updatedAt: DateTime.now(),
    );
  }

  /// Waits for [delay]. A zero delay starts no timer, so a draft saved as a
  /// screen closes does not leave a timer running at the end of a test.
  Future<void> _wait() async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
  }

  static List<String> _withoutNone(List<String> dealbreakers) =>
      dealbreakers.where((d) => d != 'none').toList();
}
