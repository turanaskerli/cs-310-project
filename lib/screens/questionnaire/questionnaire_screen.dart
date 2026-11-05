import 'package:flutter/material.dart';

import '../../utils/app_routes.dart';
import '../../widgets/placeholder_screen.dart';

/// Questionnaire. Owner: Turan.
///
/// Screen 8: one section per page with progress bar, Back/Next and Save draft. Also used as Edit answers.
///
/// Placeholder: replace the body of [build] with the real screen.
class QuestionnaireScreen extends StatelessWidget {
  const QuestionnaireScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: "Questionnaire",
      owner: "Turan",
      links: [PlaceholderLink("Next", AppRoutes.dealbreakers)],
    );
  }
}
