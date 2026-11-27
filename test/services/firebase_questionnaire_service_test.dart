import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roommate_finder/services/firebase/firebase_questionnaire_service.dart';

import '../helpers/test_data.dart';

void main() {
  const uid = 'student-1';

  late FakeFirebaseFirestore db;
  late FirebaseQuestionnaireService service;

  FirebaseQuestionnaireService serviceFor(MockFirebaseAuth auth) =>
      FirebaseQuestionnaireService(
        firestore: db,
        auth: auth,
        bundle: FileAssetBundle(),
      );

  setUp(() {
    db = FakeFirebaseFirestore();
    service = serviceFor(
      MockFirebaseAuth(signedIn: true, mockUser: MockUser(uid: uid)),
    );
  });

  Future<Map<String, dynamic>?> answersDoc() async =>
      (await db.collection('answers').doc(uid).get()).data();

  test('loads the bundled question bank', () async {
    final sections = await service.getQuestions();

    expect(sections.first.id, 'sleep');
    expect(sections.last.id, 'dealbreakers');
  });

  test('no answers before anything is saved', () async {
    expect(await service.getMyAnswers(), isNull);
  });

  test('a draft is stored at answers/{uid} and read back', () async {
    await service.saveDraft({'sleep_1': 2, 'db_alcohol': null});

    final doc = await answersDoc();
    expect(doc!['isDraft'], isTrue);
    expect(doc['updatedAt'], isNotNull);

    final answers = await service.getMyAnswers();
    expect(answers!.isDraft, isTrue);
    expect(answers.answers, {'sleep_1': 2, 'db_alcohol': null});
    expect(answers.isAnswered('db_alcohol'), isTrue);
    expect(answers.updatedAt, isNotNull);
  });

  test('drafts merge with earlier drafts', () async {
    await service.saveDraft({'sleep_1': 2}, dealbreakers: ['smoking']);
    await service.saveDraft({'clean_1': 1, 'sleep_1': 3});

    final answers = await service.getMyAnswers();
    expect(answers!.answers, {'sleep_1': 3, 'clean_1': 1});
    expect(answers.dealbreakers, ['smoking']);
  });

  test('a draft can change the dealbreakers and drops "none"', () async {
    await service.saveDraft({}, dealbreakers: ['smoking']);
    await service.saveDraft({}, dealbreakers: ['none']);

    expect((await service.getMyAnswers())!.dealbreakers, isEmpty);
  });

  test('submitting replaces the draft', () async {
    await service.saveDraft({'sleep_1': 2, 'clean_1': 1});
    await service.saveAnswers({'sleep_1': 3}, ['none', 'pets']);

    final answers = await service.getMyAnswers();
    expect(answers!.isDraft, isFalse);
    expect(answers.answers, {'sleep_1': 3});
    expect(answers.dealbreakers, ['pets']);
    expect(answers.updatedAt, isNotNull);
  });

  test('submitting marks an existing profile as done', () async {
    await db.collection('users').doc(uid).set({'fullName': 'Ada'});

    await service.saveAnswers(firstOptionAnswers(), []);

    final user = (await db.collection('users').doc(uid).get()).data()!;
    expect(user['questionnaireDone'], isTrue);
    expect(user['fullName'], 'Ada');
  });

  test('submitting without a profile does not create one', () async {
    await service.saveAnswers(firstOptionAnswers(), []);

    expect((await db.collection('users').doc(uid).get()).exists, isFalse);
    expect((await service.getMyAnswers())!.isDraft, isFalse);
  });

  test('answers stay separate per student', () async {
    await service.saveDraft({'sleep_1': 2});

    final other = serviceFor(
      MockFirebaseAuth(signedIn: true, mockUser: MockUser(uid: 'student-2')),
    );
    expect(await other.getMyAnswers(), isNull);
  });

  test('needs a signed-in student', () async {
    final signedOut = serviceFor(MockFirebaseAuth());

    expect(signedOut.getMyAnswers, throwsStateError);
    expect(() => signedOut.saveDraft({'sleep_1': 1}), throwsStateError);
  });
}
