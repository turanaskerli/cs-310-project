import 'package:flutter/material.dart';

import '../../models/recommendation.dart';
import '../../services/app_services.dart';
import '../../services/match_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_routes.dart';
import '../../utils/app_spacing.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/matches/match_card.dart';

/// Matches. Owner: Turan.
///
/// Screen 11 (tab): suggested roommates as cards, best score first. Swipe a
/// card or tap ✕ to hide it; tap it to open Match detail.
class MatchesScreen extends StatefulWidget {
  /// Defaults to [AppServices.matches].
  final MatchService? service;

  const MatchesScreen({super.key, this.service});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  late final MatchService _service = widget.service ?? AppServices.matches;
  late final Stream<List<Recommendation>> _matches = _service
      .watchRecommendations();

  /// Hidden cards leave the list at once, before the service's update
  /// arrives; a swiped Dismissible must not stay in the tree.
  final Set<String> _hidden = {};

  void _hide(Recommendation match) {
    setState(() => _hidden.add(match.otherUid));
    _service.dismiss(match.otherUid);
    _showMessage('${match.otherSummary.name} is hidden from your matches');
  }

  void _open(Recommendation match) =>
      Navigator.pushNamed(context, AppRoutes.matchDetail, arguments: match);

  void _request(Recommendation match) {
    // Sending is wired to the connection service in a later step.
    _showMessage('Request sent to ${match.otherSummary.name}');
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Matches')),
      body: StreamBuilder<List<Recommendation>>(
        stream: _matches,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const _Message(
              icon: Icons.cloud_off_outlined,
              title: 'Could not load your matches',
              text: 'Check your connection and open this tab again.',
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final matches = snapshot.data!
              .where((m) => !_hidden.contains(m.otherUid))
              .toList();
          if (matches.isEmpty) {
            return const _Message(
              icon: Icons.people_outline,
              title: 'No matches left',
              text:
                  'You have hidden every suggestion. New matches appear when '
                  'more students finish the questionnaire.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              0,
              AppSpacing.screenPadding,
              AppSpacing.lg,
            ),
            itemCount: matches.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, i) {
              if (i == 0) {
                return Text(
                  '${matches.length} suggested roommates, best match first',
                  style: AppTextStyles.bodySmall,
                );
              }
              final match = matches[i - 1];
              return Dismissible(
                key: ValueKey(match.otherUid),
                direction: DismissDirection.endToStart,
                onDismissed: (_) => _hide(match),
                background: const _HideBackground(),
                child: MatchCard(
                  match: match,
                  onOpen: () => _open(match),
                  onHide: () => _hide(match),
                  onRequest: () => _request(match),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _HideBackground extends StatelessWidget {
  const _HideBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radius),
      ),
      child: Text(
        'Hide',
        style: AppTextStyles.button.copyWith(color: AppColors.error),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _Message({required this.icon, required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: AppTextStyles.heading,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              text,
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
