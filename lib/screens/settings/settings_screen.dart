import 'package:flutter/material.dart';

import '../../utils/app_routes.dart';
import '../../widgets/placeholder_screen.dart';

/// Settings. Owner: Arda.
///
/// Screen 19: hide profile and notifications switches, blocked users, Log out, Delete account with confirmation.
///
/// Placeholder: replace the body of [build] with the real screen.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: "Settings",
      owner: "Arda",
      links: [
        PlaceholderLink("Log out", AppRoutes.welcome, clearHistory: true),
      ],
    );
  }
}
