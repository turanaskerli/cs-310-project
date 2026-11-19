import 'package:flutter/material.dart';

import '../../utils/app_colors.dart';
import '../../utils/app_routes.dart';
import '../../utils/app_spacing.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/app_button.dart';

/// Verify email. Owner: Bassam.
///
/// Screen 3: tells the user to open the link we emailed them. "I've verified"
/// continues to Consent; "Resend email" shows that a new link was sent.
///
/// Sign up passes the email address as the route argument. UI only in
/// Step 2: no email is really sent yet.
class VerifyEmailScreen extends StatelessWidget {
  const VerifyEmailScreen({super.key});

  void _resend(BuildContext context, String? email) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            email == null
                ? 'We sent you a new link'
                : 'We sent a new link to $email',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final email = ModalRoute.of(context)?.settings.arguments as String?;

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
                    const SizedBox(height: AppSpacing.xxl),
                    const _MailIcon(),
                    const SizedBox(height: AppSpacing.xl),
                    const Text(
                      'Check your inbox',
                      style: AppTextStyles.title,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(
                            text: 'We sent a verification link to ',
                          ),
                          TextSpan(
                            text: email ?? 'your university email',
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const TextSpan(
                            text:
                                '. Open it to confirm that you are a '
                                'Sabanci University student.',
                          ),
                        ],
                      ),
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const Text(
                      'Can\'t find it? Check your spam folder.',
                      style: AppTextStyles.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PrimaryButton(
                    label: "I've verified",
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.consent),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SecondaryButton(
                    label: 'Resend email',
                    onPressed: () => _resend(context, email),
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

class _MailIcon extends StatelessWidget {
  const _MailIcon();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 96,
        height: 96,
        decoration: const BoxDecoration(
          color: AppColors.primaryLight,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.mark_email_unread_outlined,
          size: 48,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
