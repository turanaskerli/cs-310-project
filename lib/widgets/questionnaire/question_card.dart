import 'package:flutter/material.dart';

import '../../models/question.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_spacing.dart';
import '../../utils/app_text_styles.dart';

/// One question with its answer options, styled for the question type.
///
/// Multi-select is only used by the dealbreaker selection, which has its own
/// screen, so it is not handled here.
class QuestionCard extends StatelessWidget {
  final Question question;

  /// Whether the user has answered; [value] can be null for "Prefer not to say".
  final bool answered;
  final num? value;
  final ValueChanged<num?> onChanged;

  const QuestionCard({
    super.key,
    required this.question,
    required this.answered,
    required this.value,
    required this.onChanged,
  });

  bool _isSelected(QuestionOption option) =>
      answered && value == option.numValue;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              question.text,
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
            ),
            if (question.optional) ...[
              const SizedBox(height: AppSpacing.xs),
              const Text('Optional', style: AppTextStyles.caption),
            ],
            const SizedBox(height: AppSpacing.md),
            switch (question.type) {
              QuestionType.forced => _forcedChoice(),
              QuestionType.scale => _scale(),
              _ => _singleChoice(),
            },
          ],
        ),
      ),
    );
  }

  Widget _singleChoice() => Column(
    children: [
      for (final option in question.options)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: _OptionTile(
            label: option.label,
            selected: _isSelected(option),
            onTap: () => onChanged(option.numValue),
          ),
        ),
    ],
  );

  /// Two trade-off cards side by side.
  Widget _forcedChoice() => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, option) in question.options.indexed) ...[
          if (i > 0) const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _OptionTile(
              label: option.label,
              selected: _isSelected(option),
              onTap: () => onChanged(option.numValue),
              centered: true,
            ),
          ),
        ],
      ],
    ),
  );

  /// A row of numbered buttons with the first and last labels underneath.
  Widget _scale() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          for (final (i, option) in question.options.indexed) ...[
            if (i > 0) const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _OptionTile(
                label: '${option.value ?? '–'}',
                selected: _isSelected(option),
                onTap: () => onChanged(option.numValue),
                centered: true,
              ),
            ),
          ],
        ],
      ),
      const SizedBox(height: AppSpacing.xs),
      Row(
        children: [
          Expanded(
            child: Text(
              question.options.first.label,
              style: AppTextStyles.caption,
            ),
          ),
          Expanded(
            child: Text(
              question.options.last.label,
              style: AppTextStyles.caption,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    ],
  );
}

class _OptionTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool centered;

  const _OptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
    this.centered = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppSpacing.radius);
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? AppColors.primaryLight : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: selected ? AppColors.primary : AppColors.border,
            width: 1.5,
          ),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            child: centered
                ? Center(
                    child: Text(
                      label,
                      style: _labelStyle,
                      textAlign: TextAlign.center,
                    ),
                  )
                : Row(
                    children: [
                      Icon(
                        selected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        size: 20,
                        color: selected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: Text(label, style: _labelStyle)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  TextStyle get _labelStyle => AppTextStyles.bodySmall.copyWith(
    color: selected ? AppColors.primaryDark : AppColors.textPrimary,
    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
  );
}
