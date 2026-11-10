import 'package:flutter/material.dart';

import '../../utils/app_colors.dart';
import '../../utils/app_spacing.dart';
import '../../utils/app_text_styles.dart';

/// "Section 3 of 9" with a progress bar, shown at the top of every
/// questionnaire page.
class SectionProgress extends StatelessWidget {
  /// 1-based number of the current section.
  final int number;
  final int total;

  const SectionProgress({super.key, required this.number, required this.total});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Section $number of $total', style: AppTextStyles.caption),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.xs),
          child: LinearProgressIndicator(
            value: total == 0 ? 0 : number / total,
            minHeight: 6,
            color: AppColors.primary,
            backgroundColor: AppColors.primaryLight,
          ),
        ),
      ],
    );
  }
}
