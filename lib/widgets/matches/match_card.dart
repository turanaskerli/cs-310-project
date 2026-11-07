import 'package:flutter/material.dart';

import '../../models/recommendation.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_spacing.dart';
import '../../utils/app_text_styles.dart';

/// One suggested roommate: photo, name, program, score and the main reasons,
/// with Hide, View profile and Request actions.
class MatchCard extends StatelessWidget {
  final Recommendation match;
  final VoidCallback onOpen;
  final VoidCallback onHide;
  final VoidCallback onRequest;

  const MatchCard({
    super.key,
    required this.match,
    required this.onOpen,
    required this.onHide,
    required this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    final s = match.otherSummary;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  MatchAvatar(photoUrl: s.photoUrl, name: s.name),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.name,
                          style: AppTextStyles.heading,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          s.program,
                          style: AppTextStyles.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (s.year > 0)
                          Text('Year ${s.year}', style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  ScoreBadge(score: match.score),
                  IconButton(
                    tooltip: 'Hide',
                    onPressed: onHide,
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              for (final reason in match.reasons.take(3))
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: _Reason(text: reason),
                ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onOpen,
                      child: const Text('View profile'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton(
                      onPressed: onRequest,
                      child: const Text('Request'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Round profile photo loaded from the network, with initials as a fallback
/// while it loads or if it fails.
class MatchAvatar extends StatelessWidget {
  final String? photoUrl;
  final String name;
  final double size;

  const MatchAvatar({
    super.key,
    required this.photoUrl,
    required this.name,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    final initials = Container(
      color: AppColors.primaryLight,
      alignment: Alignment.center,
      child: Text(
        name
            .split(' ')
            .where((p) => p.isNotEmpty)
            .take(2)
            .map((p) => p[0])
            .join(),
        style: AppTextStyles.heading.copyWith(color: AppColors.primary),
      ),
    );
    final url = photoUrl;
    return ClipOval(
      child: SizedBox.square(
        dimension: size,
        child: url == null
            ? initials
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => initials,
                frameBuilder: (_, child, frame, loadedSync) =>
                    frame == null && !loadedSync ? initials : child,
              ),
      ),
    );
  }
}

/// The compatibility score, in the accent color the theme reserves for it.
class ScoreBadge extends StatelessWidget {
  final int score;

  const ScoreBadge({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Text(
        '$score%',
        style: AppTextStyles.heading.copyWith(color: AppColors.accent),
      ),
    );
  }
}

class _Reason extends StatelessWidget {
  final String text;

  const _Reason({required this.text});

  /// Heads-up reasons point out a difference instead of a similarity.
  bool get _isHeadsUp => text.startsWith('You differ');

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            _isHeadsUp ? Icons.info_outline : Icons.check_circle_outline,
            size: 16,
            color: _isHeadsUp ? AppColors.warning : AppColors.accent,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(text, style: AppTextStyles.bodySmall)),
      ],
    );
  }
}
