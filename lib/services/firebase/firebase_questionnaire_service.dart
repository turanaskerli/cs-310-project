import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

import '../../models/answer_set.dart';
import '../../models/question.dart';
import '../question_bank.dart';
import '../questionnaire_service.dart';

/// Keeps the signed-in student's questionnaire answers in Firestore at
/// `answers/{uid}`. Owner: Turan.
///
/// Drafts and the submitted answers share that one document; `isDraft` tells
/// them apart, so reopening the questionnaire restores whichever was saved
/// last. Submitting also sets `questionnaireDone` on `users/{uid}`.
///
/// The questions come from the bundled question bank, which stays the source
/// of truth until the `questions` collection is seeded.
class FirebaseQuestionnaireService implements QuestionnaireService {
  static const answersCollection = 'answers';
  static const usersCollection = 'users';

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final AssetBundle _bundle;

  List<QuestionSection>? _sections;

  FirebaseQuestionnaireService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    AssetBundle? bundle,
  }) : _db = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _bundle = bundle ?? rootBundle;

  /// The signed-in student's uid. Every answer belongs to one student, so
  /// nothing is read or written without a signed-in user.
  String get _uid {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Sign in before using the questionnaire.');
    }
    return user.uid;
  }

  DocumentReference<Map<String, dynamic>> get _answersDoc =>
      _db.collection(answersCollection).doc(_uid);

  @override
  Future<List<QuestionSection>> getQuestions() async =>
      _sections ??= await QuestionBank.load(_bundle);

  @override
  Future<AnswerSet?> getMyAnswers() async {
    final snapshot = await _answersDoc.get();
    final data = snapshot.data();
    return data == null ? null : AnswerSet.fromMap(data);
  }

  @override
  Future<void> saveDraft(
    Map<String, num?> answers, {
    List<String>? dealbreakers,
  }) {
    // A merge keeps answers saved earlier, including those of other pages,
    // and keeps the dealbreakers when they are not passed.
    return _answersDoc.set({
      'answers': answers,
      if (dealbreakers != null) 'dealbreakers': _withoutNone(dealbreakers),
      'isDraft': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> saveAnswers(
    Map<String, num?> answers,
    List<String> dealbreakers,
  ) async {
    final uid = _uid;
    final submitted = AnswerSet(
      answers: answers,
      dealbreakers: _withoutNone(dealbreakers),
      isDraft: false,
    );
    // No merge: the submitted answers replace the draft completely.
    await _db.collection(answersCollection).doc(uid).set({
      ...submitted.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Lets the app skip the questionnaire next time. Only an existing profile
    // is updated, so this never creates a half-empty users document.
    try {
      await _db.collection(usersCollection).doc(uid).update({
        'questionnaireDone': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      if (e.code != 'not-found') rethrow;
    }
  }

  static List<String> _withoutNone(List<String> dealbreakers) =>
      dealbreakers.where((d) => d != 'none').toList();
}
