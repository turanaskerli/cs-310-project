import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

/// The main call-to-action button (filled violet), e.g. "Log in" or "Next".
///
/// Set [isLoading] while waiting for something (for example a network call):
/// the label is replaced by a spinner and taps are ignored, so the user
/// cannot submit the same form twice.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: isLoading ? null : onPressed,
      // While loading the button is technically disabled, but it should keep
      // its normal color instead of turning grey.
      style: isLoading
          ? FilledButton.styleFrom(
              disabledBackgroundColor: AppColors.primary,
              disabledForegroundColor: AppColors.surface,
            )
          : null,
      child: isLoading
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.surface,
              ),
            )
          : Text(label),
    );
  }
}

/// The second choice next to a [PrimaryButton] (violet outline),
/// e.g. "Log in" under "Sign up" on the Welcome screen.
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(onPressed: onPressed, child: Text(label));
  }
}
