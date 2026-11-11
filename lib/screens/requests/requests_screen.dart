import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/connection.dart';
import '../../services/app_services.dart';
import '../../services/connection_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_spacing.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/matches/match_card.dart';

/// Requests. Owner: Arda.
///
/// Screen 12 (tab): roommate requests in two tabs. Incoming requests can be
/// accepted, which opens a chat, or declined; outgoing ones can be
/// cancelled. Swiping a card left declines or cancels it, after a
/// confirmation.
class RequestsScreen extends StatefulWidget {
  /// Defaults to [AppServices.connections].
  final ConnectionService? service;

  const RequestsScreen({super.key, this.service});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  late final ConnectionService _service =
      widget.service ?? AppServices.connections;

  late final StreamSubscription<List<Connection>> _incomingSub;
  late final StreamSubscription<List<Connection>> _outgoingSub;

  /// Null until the first list arrives.
  List<Connection>? _incoming;
  List<Connection>? _outgoing;
  Object? _incomingError;
  Object? _outgoingError;

  /// Answered cards leave the list at once, before the service's update
  /// arrives; a swiped Dismissible must not stay in the tree. A card comes
  /// back if the service call fails.
  final Set<String> _removed = {};

  @override
  void initState() {
    super.initState();
    // Both lists are watched here, not in each tab, so the tab labels can
    // show the counts.
    _incomingSub = _service.watchIncomingRequests().listen(
      (list) => setState(() {
        _incoming = list;
        _incomingError = null;
      }),
      onError: (Object e) => setState(() => _incomingError = e),
    );
    _outgoingSub = _service.watchOutgoingRequests().listen(
      (list) => setState(() {
        _outgoing = list;
        _outgoingError = null;
      }),
      onError: (Object e) => setState(() => _outgoingError = e),
    );
  }

  @override
  void dispose() {
    _incomingSub.cancel();
    _outgoingSub.cancel();
    super.dispose();
  }

  List<Connection>? _visible(List<Connection>? list) =>
      list?.where((c) => !_removed.contains(c.id)).toList();

  String _nameOf(Connection c) => c.otherSummary(_service.currentUid).name;

  /// Removes the card, runs [action], and shows [done] or puts the card back
  /// with [failed].
  Future<void> _answer(
    Connection c,
    Future<void> Function(String id) action, {
    required String done,
    required String failed,
  }) async {
    setState(() => _removed.add(c.id));
    try {
      await action(c.id);
      _showMessage(done);
    } catch (_) {
      if (!mounted) return;
      setState(() => _removed.remove(c.id));
      _showMessage(failed);
    }
  }

  void _accept(Connection c) => _answer(
    c,
    _service.accept,
    done: 'You and ${_nameOf(c)} are connected. Say hi in Chats!',
    failed: 'Could not accept the request. Try again.',
  );

  void _decline(Connection c) => _answer(
    c,
    _service.decline,
    done: 'Request from ${_nameOf(c)} declined',
    failed: 'Could not decline the request. Try again.',
  );

  void _cancel(Connection c) => _answer(
    c,
    _service.cancel,
    done: 'Request to ${_nameOf(c)} cancelled',
    failed: 'Could not cancel the request. Try again.',
  );

  Future<bool> _confirmDecline(Connection c) => _confirm(
    title: "Decline ${_nameOf(c)}'s request?",
    text: 'The request is removed and no chat is opened.',
    action: 'Decline',
  );

  Future<bool> _confirmCancel(Connection c) => _confirm(
    title: 'Cancel your request to ${_nameOf(c)}?',
    text: 'You can send a new one later from Matches.',
    action: 'Cancel request',
  );

  Future<bool> _confirm({
    required String title,
    required String text,
    required String action,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(text),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(action),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  static String _tabLabel(String name, List<Connection>? list) =>
      list == null || list.isEmpty ? name : '$name (${list.length})';

  @override
  Widget build(BuildContext context) {
    final incoming = _visible(_incoming);
    final outgoing = _visible(_outgoing);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Requests'),
          bottom: TabBar(
            tabs: [
              Tab(text: _tabLabel('Incoming', incoming)),
              Tab(text: _tabLabel('Outgoing', outgoing)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _RequestList(
              requests: incoming,
              error: _incomingError,
              myUid: _service.currentUid,
              emptyIcon: Icons.inbox_outlined,
              emptyTitle: 'No new requests',
              emptyText:
                  'When another student sends you a roommate request, it '
                  'shows up here.',
              swipeLabel: 'Decline',
              confirmSwipe: _confirmDecline,
              onSwiped: _decline,
              actionsBuilder: (c) => [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      if (await _confirmDecline(c)) _decline(c);
                    },
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _accept(c),
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ),
            _RequestList(
              requests: outgoing,
              error: _outgoingError,
              myUid: _service.currentUid,
              emptyIcon: Icons.send_outlined,
              emptyTitle: 'No pending requests',
              emptyText:
                  'Send a request from a match to get to know them. It waits '
                  'here until they answer.',
              swipeLabel: 'Cancel',
              confirmSwipe: _confirmCancel,
              onSwiped: _cancel,
              actionsBuilder: (c) => [
                Expanded(
                  child: Text(
                    'Waiting for a reply',
                    style: AppTextStyles.bodySmall,
                  ),
                ),
                // The theme makes buttons full width, so it needs a bound.
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      if (await _confirmCancel(c)) _cancel(c);
                    },
                    child: const Text('Cancel request'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// One tab: a loading spinner, an error, an empty message or the cards.
class _RequestList extends StatelessWidget {
  final List<Connection>? requests;
  final Object? error;
  final String myUid;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptyText;
  final String swipeLabel;
  final Future<bool> Function(Connection) confirmSwipe;
  final void Function(Connection) onSwiped;
  final List<Widget> Function(Connection) actionsBuilder;

  const _RequestList({
    required this.requests,
    required this.error,
    required this.myUid,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptyText,
    required this.swipeLabel,
    required this.confirmSwipe,
    required this.onSwiped,
    required this.actionsBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final list = requests;
    if (error != null && list == null) {
      return const _Message(
        icon: Icons.cloud_off_outlined,
        title: 'Could not load your requests',
        text: 'Check your connection and open this tab again.',
      );
    }
    if (list == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (list.isEmpty) {
      return _Message(icon: emptyIcon, title: emptyTitle, text: emptyText);
    }
    final now = DateTime.now();
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      itemCount: list.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, i) {
        final c = list[i];
        return Dismissible(
          key: ValueKey(c.id),
          direction: DismissDirection.endToStart,
          confirmDismiss: (_) => confirmSwipe(c),
          onDismissed: (_) => onSwiped(c),
          background: _SwipeBackground(label: swipeLabel),
          child: _RequestCard(
            connection: c,
            myUid: myUid,
            sentAgo: sentAgo(c.createdAt, now),
            actions: actionsBuilder(c),
          ),
        );
      },
    );
  }
}

/// The other student's photo, name, program, score and when the request was
/// sent, with the tab's buttons underneath.
class _RequestCard extends StatelessWidget {
  final Connection connection;
  final String myUid;
  final String? sentAgo;
  final List<Widget> actions;

  const _RequestCard({
    required this.connection,
    required this.myUid,
    required this.sentAgo,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final s = connection.otherSummary(myUid);
    final score = connection.score;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                MatchAvatar(photoUrl: s.photoUrl, name: s.name, size: 48),
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
                        s.year > 0
                            ? '${s.program} · Year ${s.year}'
                            : s.program,
                        style: AppTextStyles.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (sentAgo != null)
                        Text(sentAgo!, style: AppTextStyles.caption),
                    ],
                  ),
                ),
                if (score != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  ScoreBadge(score: score),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(children: actions),
          ],
        ),
      ),
    );
  }
}

/// "Sent 2 h ago", "Sent yesterday", "Sent 12 Nov"; null if [sentAt] is
/// unknown.
@visibleForTesting
String? sentAgo(DateTime? sentAt, DateTime now) {
  if (sentAt == null) return null;
  final d = now.difference(sentAt);
  if (d.inMinutes < 1) return 'Sent just now';
  if (d.inHours < 1) return 'Sent ${d.inMinutes} min ago';
  if (d.inDays < 1) return 'Sent ${d.inHours} h ago';
  if (d.inDays < 2) return 'Sent yesterday';
  if (d.inDays < 7) return 'Sent ${d.inDays} days ago';
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return 'Sent ${sentAt.day} ${months[sentAt.month - 1]}';
}

class _SwipeBackground extends StatelessWidget {
  final String label;

  const _SwipeBackground({required this.label});

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
        label,
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
