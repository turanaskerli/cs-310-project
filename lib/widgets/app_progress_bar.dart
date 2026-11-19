import 'package:flutter/material.dart';

import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';
import '../utils/app_text_styles.dart';

/// A rounded progress bar with an optional label above it,
/// e.g. "Section 3 of 9".
class AppProgressBar extends StatelessWidget {
  /// Progress from 0.0 (empty) to 1.0 (full).
  final double value;
  final String? label;

  const AppProgressBar({super.key, required this.value, this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label != null) ...[
          Text(label!, style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.xs + 2),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            minHeight: 8,
            color: AppColors.primary,
            backgroundColor: AppColors.border,
          ),
        ),
      ],
    );
  }
}
