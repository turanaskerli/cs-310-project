import 'package:flutter/material.dart';

import '../../services/match_service.dart';
import '../../services/questionnaire_service.dart';
import 'debug_matches_tab.dart';
import 'debug_questionnaire_tab.dart';

/// Rough developer screen for the questionnaire and matching services. Not
/// part of the real app; the real screens follow the shared theme.
class DebugApp extends StatelessWidget {
  final QuestionnaireService questionnaire;
  final MatchService matches;

  const DebugApp({
    super.key,
    required this.questionnaire,
    required this.matches,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Roommate Finder debug',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      home: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('M3 debug'),
            bottom: const TabBar(
              tabs: [
                Tab(icon: Icon(Icons.quiz_outlined), text: 'Questionnaire'),
                Tab(icon: Icon(Icons.people_outline), text: 'Matches'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              DebugQuestionnaireTab(service: questionnaire),
              DebugMatchesTab(service: matches),
            ],
          ),
        ),
      ),
    );
  }
}
