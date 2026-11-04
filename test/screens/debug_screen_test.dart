import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roommate_finder/screens/debug/debug_screen.dart';
import 'package:roommate_finder/services/mock/mock_match_service.dart';
import 'package:roommate_finder/services/mock/mock_questionnaire_service.dart';

void main() {
  late MockQuestionnaireService questionnaire;
  late MockMatchService matches;

  setUp(() {
    questionnaire = MockQuestionnaireService(
      bundle: _FileBundle(),
      delay: Duration.zero,
    );
    matches = MockMatchService(delay: Duration.zero);
  });
  tearDown(() => matches.dispose());

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      DebugApp(questionnaire: questionnaire, matches: matches),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows sections and saves a draft answer', (tester) async {
    await pumpApp(tester);

    expect(find.text('1. Sleep schedule'), findsOneWidget);
    expect(find.textContaining('0 of'), findsOneWidget);

    await tester.tap(find.text('1. Sleep schedule'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Before 23:00'));
    await tester.pumpAndSettle();
    expect(find.textContaining('1 of'), findsOneWidget);

    await tester.tap(find.text('Save draft'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Draft: 1 answers'), findsOneWidget);
  });

  testWidgets('submit is blocked until every question is answered', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    expect(find.textContaining('are not answered yet'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
  });
}

/// Reads assets straight from the project folder. The real asset bundle uses
/// I/O that never completes under the widget test's fake clock.
class _FileBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async =>
      ByteData.sublistView(File(key).readAsBytesSync());

  @override
  Future<String> loadString(String key, {bool cache = true}) async =>
      File(key).readAsStringSync();
}
