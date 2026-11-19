import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/connection.dart';
import '../../services/app_services.dart';
import '../../services/connection_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_routes.dart';
import '../../utils/app_spacing.dart';
import '../../utils/app_text_styles.dart';
import '../../utils/chat_time.dart';
import '../../widgets/matches/match_card.dart';

/// Chats. Owner: Arda.
///
/// Screen 13 (tab): every accepted connection, latest message first, with
/// the other student's photo, the last message, its time and an unread
/// count. Tapping a row opens the Chat screen with the [Connection] as the
/// route argument.
class ChatsScreen extends StatefulWidget {
  /// Defaults to [AppServices.connections].
  final ConnectionService? service;

  const ChatsScreen({super.key, this.service});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  late final ConnectionService _service =
      widget.service ?? AppServices.connections;
  late final StreamSubscription<List<Connection>> _sub;

  /// Null until the first list arrives.
  List<Connection>? _chats;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _sub = _service.watchChats().listen(
      (list) => setState(() {
        _chats = list;
        _error = null;
      }),
      onError: (Object e) => setState(() => _error = e),
    );
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  void _open(Connection c) =>
      Navigator.pushNamed(context, AppRoutes.chat, arguments: c);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
      body: _body(),
    );
  }

  Widget _body() {
    final chats = _chats;
    if (_error != null && chats == null) {
      return const _Message(
        icon: Icons.cloud_off_outlined,
        title: 'Could not load your chats',
        text: 'Check your connection and open this tab again.',
      );
    }
    if (chats == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (chats.isEmpty) {
      return const _Message(
        icon: Icons.chat_bubble_outline,
        title: 'No chats yet',
        text:
            'When a student accepts your request, or you accept theirs, a '
            'chat opens here so you can get to know each other.',
      );
    }
    final now = DateTime.now();
    final myUid = _service.currentUid;
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      itemCount: chats.length,
      separatorBuilder: (_, _) => const Divider(
        height: 1,
        indent: AppSpacing.screenPadding + 52 + AppSpacing.md,
      ),
      itemBuilder: (context, i) => _ChatTile(
        connection: chats[i],
        myUid: myUid,
        now: now,
        onTap: () => _open(chats[i]),
      ),
    );
  }
}

/// Photo, name, last message, time and the unread count.
class _ChatTile extends StatelessWidget {
  final Connection connection;
  final String myUid;
  final DateTime now;
  final VoidCallback onTap;

  const _ChatTile({
    required this.connection,
    required this.myUid,
    required this.now,
    required this.onTap,
  });

  String get _preview {
    final text = connection.lastMessage;
    if (text == null) return 'Say hi to start the conversation 👋';
    return connection.lastMessageSenderUid == myUid ? 'You: $text' : text;
  }

  @override
  Widget build(BuildContext context) {
    final s = connection.otherSummary(myUid);
    final unread = connection.unreadCount[myUid] ?? 0;
    final at = connection.lastMessageAt ?? connection.respondedAt;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            MatchAvatar(photoUrl: s.photoUrl, name: s.name, size: 52),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          s.name,
                          style: AppTextStyles.heading.copyWith(fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (connection.isConfirmed) ...[
                        const SizedBox(width: AppSpacing.xs),
                        const Icon(
                          Icons.verified,
                          size: 16,
                          color: AppColors.success,
                          semanticLabel: 'Roommate',
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _preview,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: unread > 0
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontWeight: unread > 0
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (at != null)
                  Text(
                    chatListTime(at, now),
                    style: AppTextStyles.caption.copyWith(
                      color: unread > 0
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                const SizedBox(height: AppSpacing.xs),
                // Keeps the row height the same with or without a badge.
                SizedBox(
                  height: 20,
                  child: unread > 0 ? _UnreadBadge(count: unread) : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  final int count;

  const _UnreadBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$count unread',
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(minWidth: 20),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          count > 99 ? '99+' : '$count',
          style: AppTextStyles.caption.copyWith(color: AppColors.surface),
        ),
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
