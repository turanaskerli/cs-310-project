import 'package:flutter/material.dart';

import '../../utils/app_colors.dart';
import '../../utils/app_routes.dart';
import '../../utils/app_spacing.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/app_button.dart';

/// Welcome (screen 1). Owner: Murad.
///
/// The first screen a new user sees: a local illustration, the app name,
/// a short tagline, and buttons to Sign up or Log in.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  /// Local image bundled with the app (declared under assets in pubspec).
  static const String illustrationAsset = 'assets/images/welcome.png';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        // LayoutBuilder + minHeight lets the buttons sit at the bottom on tall
        // phones, while small phones can scroll instead of overflowing.
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 2 * AppSpacing.screenPadding,
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.xl),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 280),
                      child: AspectRatio(
                        aspectRatio: 4 / 3,
                        child: Image.asset(
                          illustrationAsset,
                          fit: BoxFit.contain,
                          semanticLabel:
                              'Two roommates standing in front of a house',
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    const Text(
                      'Roommate Finder',
                      style: AppTextStyles.display,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Find a roommate you’ll actually get along with, '
                      'before dorm applications open.',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const Spacer(),
                    const SizedBox(height: AppSpacing.xl),
                    PrimaryButton(
                      label: 'Sign up',
                      onPressed: () =>
                          Navigator.pushNamed(context, AppRoutes.signUp),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SecondaryButton(
                      label: 'Log in',
                      onPressed: () =>
                          Navigator.pushNamed(context, AppRoutes.login),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Text(
                      'Only @sabanciuniv.edu emails can join.',
                      style: AppTextStyles.caption,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
