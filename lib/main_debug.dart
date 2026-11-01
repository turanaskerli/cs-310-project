import 'package:flutter/material.dart';

import 'screens/debug/debug_screen.dart';
import 'services/mock/mock_match_service.dart';
import 'services/mock/mock_questionnaire_service.dart';

/// Separate entry point for testing the questionnaire and matching services
/// on a device, without the real app shell.
///
/// Run with: flutter run -t lib/main_debug.dart
void main() {
  runApp(
    DebugApp(
      questionnaire: MockQuestionnaireService(),
      matches: MockMatchService(),
    ),
  );
}
