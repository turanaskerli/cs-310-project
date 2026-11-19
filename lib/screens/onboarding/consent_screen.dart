import 'package:flutter/material.dart';

import '../../utils/app_colors.dart';
import '../../utils/app_routes.dart';
import '../../utils/app_spacing.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';

/// Consent. Owner: Bassam.
///
/// Screen 5: a short privacy notice that says what the app collects and who
/// can see it. Agree continues to Basic profile; "Not now" returns to Welcome.
class ConsentScreen extends StatelessWidget {
  const ConsentScreen({super.key});

  static const _points = [
    _PrivacyPoint(
      icon: Icons.person_outline,
      title: 'What we collect',
      text:
          'Your name, photo, program, year, gender, a short bio and your '
          'questionnaire answers.',
    ),
    _PrivacyPoint(
      icon: Icons.visibility_outlined,
      title: 'Who sees your profile',
      text:
          'Only verified Sabanci students you are matched with see your '
          'name, photo, program and bio.',
    ),
    _PrivacyPoint(
      icon: Icons.badge_outlined,
      title: 'Your student ID stays private',
      text:
          'It is shown only to the one student you both confirm as your '
          'roommate, for the dorm application.',
    ),
    _PrivacyPoint(
      icon: Icons.delete_outline,
      title: 'You stay in control',
      text:
          'Edit your answers, hide your profile or delete your account at '
          'any time in Settings.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your privacy')),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                ),
                children: [
                  Text(
                    'Before you build your profile, here is how we use '
                    'your information.',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  for (final point in _points) ...[
                    point,
                    const SizedBox(height: AppSpacing.md),
                  ],
                  const Text(
                    'We never ask about religion, health or other sensitive '
                    'topics (KVKK).',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PrimaryButton(
                    label: 'Agree',
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.basicProfile),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextButton(
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.welcome,
                      (_) => false,
                    ),
                    child: const Text('Not now'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivacyPoint extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _PrivacyPoint({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.heading),
                const SizedBox(height: AppSpacing.xs),
                Text(text, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
