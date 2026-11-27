import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/question.dart';

/// The bundled question bank, `assets/data/questions.json`. It is the source
/// of truth for the questions; both questionnaire services read it.
class QuestionBank {
  QuestionBank._();

  static const asset = 'assets/data/questions.json';

  /// Active questions grouped into ordered sections.
  static Future<List<QuestionSection>> load(AssetBundle bundle) async =>
      QuestionSection.group(
        questionsFromBank(
          jsonDecode(await bundle.loadString(asset)) as Map<String, dynamic>,
        ),
      );
}
