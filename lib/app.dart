import 'package:flutter/material.dart';

import 'screens/home/not_found_screen.dart';
import 'utils/app_routes.dart';
import 'utils/app_theme.dart';

/// The root widget: applies the shared theme and the named routes.
class RoommateFinderApp extends StatelessWidget {
  const RoommateFinderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Roommate Finder',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppRoutes.welcome,
      routes: AppRoutes.routes,
      // A mistyped route name shows a friendly page instead of crashing.
      onUnknownRoute: (settings) => MaterialPageRoute(
        settings: settings,
        builder: (_) => const NotFoundScreen(),
      ),
    );
  }
}
