import 'package:flutter/material.dart';

import '../../widgets/placeholder_screen.dart';

/// Forgot password. Owner: Murad.
///
/// Screen 4b: email field, Send reset link button and a confirmation message.
///
/// Placeholder: replace the body of [build] with the real screen.
class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(title: "Forgot password", owner: "Murad");
  }
}
