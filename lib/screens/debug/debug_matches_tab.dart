import 'package:flutter/material.dart';

import '../../models/recommendation.dart';
import '../../services/match_service.dart';

/// Live list of recommendations. Swipe a card to dismiss it; tap it to see
/// the reasons and the trait comparison.
class DebugMatchesTab extends StatefulWidget {
  final MatchService service;

  const DebugMatchesTab({super.key, required this.service});

  @override
  State<DebugMatchesTab> createState() => _DebugMatchesTabState();
}

class _DebugMatchesTabState extends State<DebugMatchesTab>
    with AutomaticKeepAliveClientMixin {
  late final Stream<List<Recommendation>> _matches = service
      .watchRecommendations();

  /// Swiped cards leave the list at once, before the service's update
  /// arrives; Dismissible requires that.
  final Set<String> _dismissed = {};

  MatchService get service => widget.service;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return StreamBuilder<List<Recommendation>>(
      stream: _matches,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Could not load matches:\n${snapshot.error}'),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final matches = snapshot.data!
            .where((m) => !_dismissed.contains(m.otherUid))
            .toList();
        if (matches.isEmpty) {
          return const Center(child: Text('No matches left'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: matches.length,
          itemBuilder: (context, i) => _card(context, matches[i]),
        );
      },
    );
  }

  Widget _card(BuildContext context, Recommendation m) {
    final s = m.otherSummary;
    return Dismissible(
      key: ValueKey(m.otherUid),
      onDismissed: (_) {
        setState(() => _dismissed.add(m.otherUid));
        service.dismiss(m.otherUid);
      },
      background: Container(
        color: Theme.of(context).colorScheme.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: const Icon(Icons.close),
      ),
      child: Card(
        child: ListTile(
          leading: CircleAvatar(
            backgroundImage: s.photoUrl == null
                ? null
                : NetworkImage(s.photoUrl!),
            onBackgroundImageError: s.photoUrl == null ? null : (_, _) {},
          ),
          title: Text(s.name),
          subtitle: Text(
            '${s.program} · year ${s.year}\n${m.reasons.first}',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          isThreeLine: true,
          trailing: Text(
            '${m.score}%',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          onTap: () => _showDetail(context, m),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context, Recommendation m) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (context, controller) => FutureBuilder<List<TraitComparison>>(
          future: service.getComparison(m.otherUid),
          builder: (context, snapshot) {
            final comparison = snapshot.data ?? const <TraitComparison>[];
            final text = Theme.of(context).textTheme;
            return ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                Text(
                  '${m.otherSummary.name} · ${m.score}%',
                  style: text.titleLarge,
                ),
                const SizedBox(height: 8),
                for (final r in m.reasons) Text('• $r'),
                const SizedBox(height: 16),
                Text('Trait comparison (1–5)', style: text.titleMedium),
                if (!snapshot.hasData)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                for (final c in comparison) ...[
                  const SizedBox(height: 10),
                  Text(
                    '${c.label}: you ${c.mine.toStringAsFixed(1)}, '
                    'them ${c.theirs.toStringAsFixed(1)}, '
                    'fit ${(c.fit * 100).round()}%',
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(value: c.fit),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
