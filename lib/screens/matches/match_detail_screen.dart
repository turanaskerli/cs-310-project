import 'package:flutter/material.dart';

import '../../models/recommendation.dart';
import '../../services/app_services.dart';
import '../../services/match_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_spacing.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/matches/match_card.dart';

/// Match detail. Owner: Turan.
///
/// Screen 15: the full profile of one match with the reasons for the score
/// and side-by-side trait bars, plus Send request and Report or block.
/// Opened from Matches with the [Recommendation] as the route argument.
class MatchDetailScreen extends StatefulWidget {
  /// Defaults to [AppServices.matches].
  final MatchService? service;

  const MatchDetailScreen({super.key, this.service});

  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen> {
  late final MatchService _service = widget.service ?? AppServices.matches;
  Recommendation? _match;
  Future<List<TraitComparison>>? _comparison;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_match != null) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Recommendation) {
      _match = args;
      // The match usually carries its comparison; load it if it does not.
      _comparison = args.comparison.isNotEmpty
          ? Future.value(args.comparison)
          : _service.getComparison(args.otherUid);
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final match = _match;
    if (match == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Text(
              'This match is no longer available.',
              style: AppTextStyles.body,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final s = match.otherSummary;
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  0,
                  AppSpacing.screenPadding,
                  AppSpacing.lg,
                ),
                children: [
                  _Header(match: match),
                  const SizedBox(height: AppSpacing.lg),
                  _Section(
                    title: 'Why you match',
                    children: [
                      for (final reason in match.reasons)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                          child: MatchReason(text: reason),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FutureBuilder<List<TraitComparison>>(
                    future: _comparison,
                    builder: (context, snapshot) => _Comparison(
                      otherName: s.name.split(' ').first,
                      traits: snapshot.data,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.sm,
                AppSpacing.screenPadding,
                AppSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Sending is wired to the connection service in a later step.
                  FilledButton(
                    onPressed: () => _showMessage('Request sent to ${s.name}'),
                    child: const Text('Send request'),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                    ),
                    onPressed: () => _showMessage(
                      'Reporting and blocking will be available soon',
                    ),
                    child: const Text('Report or block'),
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

class _Header extends StatelessWidget {
  final Recommendation match;

  const _Header({required this.match});

  @override
  Widget build(BuildContext context) {
    final s = match.otherSummary;
    return Row(
      children: [
        MatchAvatar(photoUrl: s.photoUrl, name: s.name, size: 72),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.name, style: AppTextStyles.title),
              const SizedBox(height: AppSpacing.xs),
              Text(
                s.year > 0 ? '${s.program} · Year ${s.year}' : s.program,
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                ),
                child: Text(
                  '${match.score}% match',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: AppTextStyles.heading),
            const SizedBox(height: AppSpacing.md),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// Two bars per trait: the user's own value and the match's, on the 1–5
/// scale the matching engine uses.
class _Comparison extends StatelessWidget {
  final String otherName;
  final List<TraitComparison>? traits;

  const _Comparison({required this.otherName, required this.traits});

  @override
  Widget build(BuildContext context) {
    final traits = this.traits;
    return _Section(
      title: 'How you compare',
      children: [
        Row(
          children: [
            const _Legend(label: 'You', color: AppColors.primary),
            const SizedBox(width: AppSpacing.sm),
            _Legend(label: otherName, color: AppColors.accent),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (traits == null)
          const Center(child: CircularProgressIndicator())
        else
          for (final t in traits) ...[
            Text(t.label, style: AppTextStyles.caption),
            const SizedBox(height: AppSpacing.xs),
            _Bar(value: t.mine, color: AppColors.primary),
            const SizedBox(height: AppSpacing.xs),
            _Bar(value: t.theirs, color: AppColors.accent),
            const SizedBox(height: AppSpacing.md),
          ],
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  final String label;
  final Color color;

  const _Legend({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppSpacing.lg),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(color: AppColors.surface),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final double value;
  final Color color;

  const _Bar({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.xs),
      child: LinearProgressIndicator(
        value: (value / 5).clamp(0, 1),
        minHeight: 6,
        color: color,
        backgroundColor: AppColors.border,
      ),
    );
  }
}
