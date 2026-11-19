import 'package:flutter/material.dart';

import '../../utils/app_routes.dart';
import '../../widgets/state_views.dart';

/// Shown if the app is asked to open a route name that does not exist,
/// instead of crashing. Owner: Murad.
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: EmptyView(
        icon: Icons.explore_off_outlined,
        title: 'Page not found',
        message: 'This screen does not exist. Let’s take you back.',
        actionLabel: 'Go to start',
        onAction: () => Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.welcome,
          (_) => false,
        ),
      ),
    );
  }
}
