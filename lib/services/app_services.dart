import 'chat_service.dart';
import 'connection_service.dart';
import 'match_service.dart';
import 'mock/mock_chat_service.dart';
import 'mock/mock_connection_service.dart';
import 'mock/mock_match_service.dart';
import 'mock/mock_questionnaire_service.dart';
import 'questionnaire_service.dart';

/// The service implementations the screens use. Mocks for now; in Step 3
/// each owner swaps in the Firebase version here, one line per service.
///
/// Tests can assign a different implementation before pumping a screen.
class AppServices {
  AppServices._();

  static QuestionnaireService questionnaire = MockQuestionnaireService();
  static MatchService matches = MockMatchService();

  /// The mock chat updates the mock connections' last message and unread
  /// count, so both mocks share one instance.
  static final MockConnectionService _mockConnections = MockConnectionService();

  static ConnectionService connections = _mockConnections;
  static ChatService chat = MockChatService(connections: _mockConnections);
}
