import 'package:flutter/material.dart';

import '../../utils/app_routes.dart';
import '../../widgets/placeholder_screen.dart';

/// Roommate confirmed. Owner: Arda.
///
/// Screen 17: partner's student ID, phone and Instagram, plus a reminder for the dorm application.
///
/// Placeholder: replace the body of [build] with the real screen.
class RoommateConfirmedScreen extends StatelessWidget {
  const RoommateConfirmedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: "Roommate confirmed",
      owner: "Arda",
      links: [
        PlaceholderLink("Back to home", AppRoutes.home, clearHistory: true),
      ],
    );
  }
}
