import 'package:flutter/material.dart';

import '../../utils/app_routes.dart';
import '../../widgets/placeholder_screen.dart';

/// Profile. Owner: Bassam.
///
/// Screen 14 (tab): my photo, name, program, year and bio; Edit profile, Edit answers and Settings buttons.
///
/// Placeholder: replace the body of [build] with the real screen.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: "Profile",
      owner: "Bassam",
      links: [
        PlaceholderLink("Edit profile", AppRoutes.basicProfile),
        PlaceholderLink("Edit answers", AppRoutes.questionnaire),
        PlaceholderLink("Settings", AppRoutes.settings),
      ],
    );
  }
}
