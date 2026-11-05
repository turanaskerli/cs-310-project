import 'package:flutter/material.dart';

import '../../utils/app_routes.dart';
import '../../widgets/placeholder_screen.dart';

/// Honesty intro. Owner: Turan.
///
/// Screen 7: why honest answers give better matches, and a Start button.
///
/// Placeholder: replace the body of [build] with the real screen.
class HonestyIntroScreen extends StatelessWidget {
  const HonestyIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: "Honesty intro",
      owner: "Turan",
      links: [PlaceholderLink("Start", AppRoutes.questionnaire)],
    );
  }
}
