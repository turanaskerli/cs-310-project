import 'package:flutter/material.dart';

import '../../utils/app_routes.dart';
import '../../widgets/placeholder_screen.dart';

/// Review and submit. Owner: Arda.
///
/// Screen 10: answers grouped by section, Edit per section, Submit with a confirmation dialog, then Matches.
///
/// Placeholder: replace the body of [build] with the real screen.
class ReviewSubmitScreen extends StatelessWidget {
  const ReviewSubmitScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: "Review and submit",
      owner: "Arda",
      links: [PlaceholderLink("Submit", AppRoutes.home, clearHistory: true)],
    );
  }
}
