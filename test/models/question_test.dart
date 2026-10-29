import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:roommate_finder/models/question.dart';

void main() {
  group('question bank (scripts/questions.json)', () {
    final bank =
        jsonDecode(File('scripts/questions.json').readAsStringSync())
            as Map<String, dynamic>;
    final sectionIds = (bank['sections'] as List)
        .map((s) => s['id'] as String)
        .toSet();
    final questions = (bank['questions'] as List)
        .map((q) => Question.fromMap(Map<String, dynamic>.from(q)))
        .toList();

    test('every question parses and belongs to a known section', () {
      expect(questions, isNotEmpty);
      for (final q in questions) {
        expect(sectionIds, contains(q.section), reason: q.id);
      }
    });

    test('question ids are unique', () {
      expect(questions.map((q) => q.id).toSet().length, questions.length);
    });

    test('scored questions use numeric values from 1 to 5', () {
      for (final q in questions.where((q) => q.isScored)) {
        for (final o in q.options) {
          expect(o.numValue, isNotNull, reason: q.id);
          expect(o.numValue, inInclusiveRange(1, 5), reason: q.id);
        }
      }
    });

    test('attribute questions name a flag', () {
      for (final q in questions.where(
        (q) => q.direction == QuestionDirection.attribute,
      )) {
        expect(q.flag, isNotNull, reason: q.id);
        expect(q.flagMinValue, isNotNull, reason: q.id);
      }
    });

    test('dealbreaker selection options match attribute flags', () {
      final flags = questions.map((q) => q.flag).whereType<String>().toSet();
      final selection = questions.singleWhere((q) => q.isDealbreakerSelection);
      final keys = selection.options
          .where((o) => !o.exclusive)
          .map((o) => o.stringValue)
          .toSet();
      expect(keys, flags);
    });
  });

  test('toMap / fromMap round trip', () {
    const q = Question(
      id: 'q1',
      section: 'sleep',
      sectionTitle: 'Sleep schedule',
      sectionOrder: 1,
      order: 2,
      text: 'When do you sleep?',
      type: QuestionType.single,
      options: [
        QuestionOption(label: 'Early', value: 1),
        QuestionOption(label: 'Late', value: 5),
      ],
      trait: 'sleep',
      direction: QuestionDirection.self,
    );
    expect(Question.fromMap(q.toMap(), id: 'q1'), q);
  });

  test('unknown type throws FormatException', () {
    expect(() => QuestionType.fromName('slider'), throwsFormatException);
  });

  test('group sorts sections and questions, and skips inactive ones', () {
    Question make(
      String id,
      String section,
      int sOrder,
      int order, {
      bool active = true,
    }) => Question(
      id: id,
      section: section,
      sectionOrder: sOrder,
      order: order,
      text: id,
      type: QuestionType.single,
      options: const [],
      trait: section,
      direction: QuestionDirection.self,
      active: active,
    );

    final sections = QuestionSection.group([
      make('b2', 'b', 2, 2),
      make('a1', 'a', 1, 1),
      make('b1', 'b', 2, 1),
      make('a2', 'a', 1, 2, active: false),
    ]);

    expect(sections.map((s) => s.id), ['a', 'b']);
    expect(sections[0].questions.map((q) => q.id), ['a1']);
    expect(sections[1].questions.map((q) => q.id), ['b1', 'b2']);
  });
}
