import 'package:flutter/material.dart';

import '../utils/app_spacing.dart';

/// The base white card with a thin border and rounded corners.
/// Pass [onTap] to make the whole card tappable (with a ripple).
class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
  });

  @override
  Widget build(BuildContext context) {
    // Card takes its color, border and radius from cardTheme in AppTheme.
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
