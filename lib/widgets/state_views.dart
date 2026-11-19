import 'package:flutter/material.dart';

import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';
import '../utils/app_text_styles.dart';
import 'app_button.dart';

/// Full-area views for the three states every data screen has besides
/// "loaded": loading, empty and error. Use them so these states look the
/// same on every screen, for example:
///
/// ```dart
/// if (isLoading) return const LoadingView();
/// if (error != null) return ErrorView(message: error, onRetry: load);
/// if (items.isEmpty) return const EmptyView(title: 'No matches yet');
/// ```

/// A centered spinner with an optional message under it.
class LoadingView extends StatelessWidget {
  final String? message;

  const LoadingView({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              message!,
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Shown when a list has nothing in it, with an optional button.
class EmptyView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyView({
    super.key,
    required this.title,
    this.icon = Icons.inbox_outlined,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return _MessageView(
      icon: icon,
      iconColor: AppColors.primary,
      iconBackground: AppColors.primaryLight,
      title: title,
      message: message,
      action: actionLabel == null
          ? null
          : SecondaryButton(label: actionLabel!, onPressed: onAction),
    );
  }
}

/// Shown when loading failed, with a Try again button.
class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorView({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return _MessageView(
      icon: Icons.error_outline,
      iconColor: AppColors.error,
      iconBackground: AppColors.error.withValues(alpha: 0.1),
      title: 'Something went wrong',
      message: message,
      action: onRetry == null
          ? null
          : PrimaryButton(label: 'Try again', onPressed: onRetry),
    );
  }
}

/// Shared layout of [EmptyView] and [ErrorView]: round icon, title,
/// message and an optional button, centered and scrollable on small phones.
class _MessageView extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String? message;
  final Widget? action;

  const _MessageView({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: CircleAvatar(
                radius: 44,
                backgroundColor: iconBackground,
                child: Icon(icon, size: 40, color: iconColor),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: AppTextStyles.title,
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                message!,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppSpacing.xl),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
