import 'package:flutter_test/flutter_test.dart';
import 'package:roommate_finder/services/mock/mock_questionnaire_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockQuestionnaireService service;

  setUp(() => service = MockQuestionnaireService(delay: Duration.zero));

  test('loads the question bank asset as ordered sections', () async {
    final sections = await service.getQuestions();

    expect(sections.first.id, 'sleep');
    expect(sections.first.title, 'Sleep schedule');
    expect(sections.last.id, 'dealbreakers');
    expect(
      sections.map((s) => s.order),
      orderedEquals([1, 2, 3, 4, 5, 6, 7, 8, 9]),
    );
    for (final s in sections) {
      final orders = s.questions.map((q) => q.order).toList();
      expect(orders, [...orders]..sort(), reason: s.id);
    }
  });

  test('no answers before anything is saved', () async {
    expect(await service.getMyAnswers(), isNull);
  });

  test('drafts merge with earlier drafts', () async {
    await service.saveDraft({'sleep_1': 2});
    await service.saveDraft({'clean_1': 1}, dealbreakers: ['smoking']);

    final answers = await service.getMyAnswers();
    expect(answers!.isDraft, isTrue);
    expect(answers.answers, {'sleep_1': 2, 'clean_1': 1});
    expect(answers.dealbreakers, ['smoking']);
  });

  test('submitting replaces the draft and drops "none"', () async {
    await service.saveDraft({'sleep_1': 2, 'clean_1': 1});
    await service.saveAnswers({'sleep_1': 3}, ['none']);

    final answers = await service.getMyAnswers();
    expect(answers!.isDraft, isFalse);
    expect(answers.answers, {'sleep_1': 3});
    expect(answers.dealbreakers, isEmpty);
    expect(answers.updatedAt, isNotNull);
  });
}
