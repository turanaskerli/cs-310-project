import 'package:flutter/material.dart';

import '../../widgets/placeholder_screen.dart';

/// Requests. Owner: Arda.
///
/// Screen 12 (tab): Incoming (Accept/Decline) and Outgoing (Cancel) tabs with removable request cards.
///
/// Placeholder: replace the body of [build] with the real screen.
class RequestsScreen extends StatelessWidget {
  const RequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(title: "Requests", owner: "Arda");
  }
}
