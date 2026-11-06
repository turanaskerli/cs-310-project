import 'package:flutter/material.dart';

import '../../utils/app_routes.dart';
import '../../widgets/placeholder_screen.dart';

/// Verify email. Owner: Bassam.
///
/// Screen 3: "Check your inbox" message with Resend and I've verified buttons.
///
/// Placeholder: replace the body of [build] with the real screen.
class VerifyEmailScreen extends StatelessWidget {
  const VerifyEmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: "Verify email",
      owner: "Bassam",
      links: [PlaceholderLink("I've verified", AppRoutes.consent)],
    );
  }
}
