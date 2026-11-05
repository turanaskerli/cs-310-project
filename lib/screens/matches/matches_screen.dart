import 'package:flutter/material.dart';

import '../../utils/app_routes.dart';
import '../../widgets/placeholder_screen.dart';

/// Matches. Owner: Turan.
///
/// Screen 11 (tab): Recommendation cards with photo, score, reasons and Request; dismiss removes the card; empty state.
///
/// Placeholder: replace the body of [build] with the real screen.
class MatchesScreen extends StatelessWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: "Matches",
      owner: "Turan",
      links: [PlaceholderLink("Open a match", AppRoutes.matchDetail)],
    );
  }
}
