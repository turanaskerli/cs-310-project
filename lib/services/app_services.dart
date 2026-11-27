import 'package:firebase_auth/firebase_auth.dart';

import 'chat_service.dart';
import 'connection_service.dart';
import 'firebase/firebase_questionnaire_service.dart';
import 'match_service.dart';
import 'mock/mock_chat_service.dart';
import 'mock/mock_connection_service.dart';
import 'mock/mock_match_service.dart';
import 'mock/mock_questionnaire_service.dart';
import 'mock/mock_report_service.dart';
import 'mock/mock_user_service.dart';
import 'questionnaire_service.dart';
import 'report_service.dart';
import 'user_service.dart';

/// The service implementations the screens use. Mocks for now; in Step 3
/// each owner swaps in the Firebase version here, one line per service.
///
/// Tests can assign a different implementation before pumping a screen.
class AppServices {
  AppServices._();

  static UserService users = MockUserService();
  static QuestionnaireService questionnaire = MockQuestionnaireService();
  static MatchService matches = MockMatchService();
  static ReportService reports = MockReportService();

  /// The mock chat updates the mock connections' last message and unread
  /// count, so both mocks share one instance.
  static final MockConnectionService _mockConnections = MockConnectionService();

  static ConnectionService connections = _mockConnections;
  static ChatService chat = MockChatService(connections: _mockConnections);

  /// Swaps in the services that have a Firebase version. `main` calls this
  /// once Firebase has started; tests never do, so they keep the mocks.
  static void useFirebase() {
    final mockQuestionnaire = questionnaire;
    final firebaseQuestionnaire = FirebaseQuestionnaireService();

    // Answers are stored per Firebase user. Sign-in still uses the mock, so
    // the questionnaire stays on the mock while nobody is signed in to
    // Firebase and moves to Firestore as soon as someone is.
    QuestionnaireService pick(User? user) =>
        user == null ? mockQuestionnaire : firebaseQuestionnaire;
    questionnaire = pick(FirebaseAuth.instance.currentUser);
    FirebaseAuth.instance.authStateChanges().listen(
      (user) => questionnaire = pick(user),
    );
  }
}
