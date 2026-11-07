import 'package:flutter/material.dart';

import '../../utils/app_colors.dart';
import '../../utils/app_routes.dart';
import '../../utils/app_spacing.dart';
import '../../utils/app_text_styles.dart';

/// Honesty intro. Owner: Turan.
///
/// Screen 7: explains that the app matches people who live alike, so honest
/// answers give better matches, then starts the questionnaire.
class HonestyIntroScreen extends StatelessWidget {
  const HonestyIntroScreen({super.key});

  static const _points = [
    'Questions ask about real habits, not self-ratings',
    'Takes about 5 minutes, 9 short sections',
    'You can save a draft and edit answers later',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _Illustration(),
                    const SizedBox(height: AppSpacing.xl),
                    const Text(
                      'Be honest, get better matches',
                      style: AppTextStyles.title,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'We match people who live alike. There are no right or '
                      'wrong answers, so an untrue answer only gives you a '
                      'worse match.',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    for (final point in _points) _Point(text: point),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              child: FilledButton(
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.questionnaire),
                child: const Text('Start'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Illustration extends StatelessWidget {
  const _Illustration();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppSpacing.radius * 2),
      ),
      alignment: Alignment.center,
      child: Container(
        width: 72,
        height: 72,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, color: AppColors.surface, size: 36),
      ),
    );
  }
}

class _Point extends StatelessWidget {
  final String text;

  const _Point({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(text, style: AppTextStyles.bodySmall)),
        ],
      ),
    );
  }
}
