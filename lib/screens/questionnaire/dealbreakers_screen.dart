import 'package:flutter/material.dart';

import '../../utils/app_routes.dart';
import '../../widgets/placeholder_screen.dart';

/// Dealbreakers. Owner: Turan.
///
/// Screen 9: multi-select of absolute no's; "None of these" clears the others.
///
/// Placeholder: replace the body of [build] with the real screen.
class DealbreakersScreen extends StatelessWidget {
  const DealbreakersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: "Dealbreakers",
      owner: "Turan",
      links: [PlaceholderLink("Next", AppRoutes.reviewSubmit)],
    );
  }
}
