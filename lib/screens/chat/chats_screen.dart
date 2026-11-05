import 'package:flutter/material.dart';

import '../../utils/app_routes.dart';
import '../../widgets/placeholder_screen.dart';

/// Chats. Owner: Arda.
///
/// Screen 13 (tab): accepted connections with avatar, last message, time and an unread dot.
///
/// Placeholder: replace the body of [build] with the real screen.
class ChatsScreen extends StatelessWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: "Chats",
      owner: "Arda",
      links: [PlaceholderLink("Open a chat", AppRoutes.chat)],
    );
  }
}
