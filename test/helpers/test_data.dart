import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:roommate_finder/models/question.dart';

/// Reads assets straight from the project folder, so tests do not depend on
/// the platform asset bundle.
class FileAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async =>
      ByteData.sublistView(File(key).readAsBytesSync());

  @override
  Future<String> loadString(String key, {bool cache = true}) async =>
      File(key).readAsStringSync();
}

/// The real question bank from assets/data/questions.json.
List<Question> loadQuestionBank() => questionsFromBank(
  jsonDecode(File('assets/data/questions.json').readAsStringSync())
      as Map<String, dynamic>,
);

/// An answer (the first option) for every question in the questionnaire
/// pages, i.e. every section except dealbreakers.
Map<String, num?> firstOptionAnswers() => {
  for (final q in loadQuestionBank())
    if (q.section != 'dealbreakers') q.id: q.options.first.numValue,
};
