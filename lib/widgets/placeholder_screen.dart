import 'package:flutter/material.dart';

import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';
import '../utils/app_text_styles.dart';

/// A button on a placeholder screen that opens another route, so the
/// navigation can be tested before the real screens are built.
class PlaceholderLink {
  final String label;
  final String route;

  /// If true, the history is cleared (used for "go to home" and "log out").
  final bool clearHistory;

  const PlaceholderLink(this.label, this.route, {this.clearHistory = false});
}

/// Temporary screen shown until the owner builds the real one.
/// Each owner replaces the body of their screen file and deletes the
/// use of this widget; nobody needs to touch the routes file.
class PlaceholderScreen extends StatelessWidget {
  final String title;
  final String owner;
  final List<PlaceholderLink> links;

  const PlaceholderScreen({
    super.key,
    required this.title,
    required this.owner,
    this.links = const [],
  });

  void _open(BuildContext context, PlaceholderLink link) {
    if (link.clearHistory) {
      Navigator.pushNamedAndRemoveUntil(context, link.route, (_) => false);
    } else {
      Navigator.pushNamed(context, link.route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xxl),
              const Icon(
                Icons.construction_outlined,
                size: 48,
                color: AppColors.primary,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                title,
                style: AppTextStyles.heading,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Placeholder · built by $owner',
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              for (var i = 0; i < links.length; i++) ...[
                if (i == 0)
                  FilledButton(
                    onPressed: () => _open(context, links[i]),
                    child: Text(links[i].label),
                  )
                else
                  OutlinedButton(
                    onPressed: () => _open(context, links[i]),
                    child: Text(links[i].label),
                  ),
                const SizedBox(height: AppSpacing.md),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
