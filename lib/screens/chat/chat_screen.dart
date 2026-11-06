import 'package:flutter/material.dart';

import '../../utils/app_routes.dart';
import '../../widgets/placeholder_screen.dart';

/// Chat. Owner: Arda.
///
/// Screen 16: message bubbles, text input with Send, and a We're roommates button with a confirmation dialog.
///
/// Placeholder: replace the body of [build] with the real screen.
class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: "Chat",
      owner: "Arda",
      links: [PlaceholderLink("We're roommates", AppRoutes.roommateConfirmed)],
    );
  }
}
