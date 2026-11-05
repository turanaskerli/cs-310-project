import 'package:flutter/material.dart';

import '../../utils/app_routes.dart';
import '../../widgets/placeholder_screen.dart';

/// Basic profile. Owner: Bassam.
///
/// Screen 6: photo, name, gender, program, year, bio and private student ID. Also used as Edit profile.
///
/// Placeholder: replace the body of [build] with the real screen.
class BasicProfileScreen extends StatelessWidget {
  const BasicProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: "Basic profile",
      owner: "Bassam",
      links: [PlaceholderLink("Continue", AppRoutes.honestyIntro)],
    );
  }
}
