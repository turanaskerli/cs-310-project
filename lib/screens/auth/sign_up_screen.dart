import 'package:flutter/material.dart';

import '../../utils/app_routes.dart';
import '../../widgets/placeholder_screen.dart';

/// Sign up. Owner: Bassam.
///
/// Screen 2: university email, password, confirm password, terms checkbox, inline errors and a confirmation dialog.
///
/// Placeholder: replace the body of [build] with the real screen.
class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: "Sign up",
      owner: "Bassam",
      links: [PlaceholderLink("Create account", AppRoutes.verifyEmail)],
    );
  }
}
