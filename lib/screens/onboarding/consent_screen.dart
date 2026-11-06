import 'package:flutter/material.dart';

import '../../utils/app_routes.dart';
import '../../widgets/placeholder_screen.dart';

/// Consent. Owner: Bassam.
///
/// Screen 5: short privacy notice (what is collected, who sees it) and an Agree button.
///
/// Placeholder: replace the body of [build] with the real screen.
class ConsentScreen extends StatelessWidget {
  const ConsentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: "Consent",
      owner: "Bassam",
      links: [PlaceholderLink("Agree", AppRoutes.basicProfile)],
    );
  }
}
