import 'package:flutter/material.dart';

import '../../utils/app_routes.dart';
import '../../widgets/placeholder_screen.dart';

/// Welcome. Owner: Murad.
///
/// Screen 1: local image (illustration or logo), app name, Sign up and Log in buttons.
///
/// Placeholder: replace the body of [build] with the real screen.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: "Welcome",
      owner: "Murad",
      links: [
        PlaceholderLink("Sign up", AppRoutes.signUp),
        PlaceholderLink("Log in", AppRoutes.login),
      ],
    );
  }
}
