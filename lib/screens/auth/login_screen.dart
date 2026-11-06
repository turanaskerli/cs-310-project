import 'package:flutter/material.dart';

import '../../utils/app_routes.dart';
import '../../widgets/placeholder_screen.dart';

/// Log in. Owner: Murad.
///
/// Screen 4: email and password with inline validation (Bassam's validators) and a Forgot password link.
///
/// Placeholder: replace the body of [build] with the real screen.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: "Log in",
      owner: "Murad",
      links: [
        PlaceholderLink("Log in", AppRoutes.home, clearHistory: true),
        PlaceholderLink("Forgot password?", AppRoutes.forgotPassword),
      ],
    );
  }
}
