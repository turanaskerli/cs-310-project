import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/connection.dart';
import '../../models/message.dart';
import '../../services/app_services.dart';
import '../../services/chat_service.dart';
import '../../services/connection_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_routes.dart';
import '../../utils/app_spacing.dart';
import '../../utils/app_text_styles.dart';
import '../../utils/chat_time.dart';
import '../../widgets/matches/match_card.dart';

/// Chat. Owner: Arda.
///
/// Screen 16: messages with one accepted connection, a text field with Send,
/// and a "We're roommates" bar. Confirming asks first; once both students
/// have confirmed, the Roommate confirmed screen opens.
///
/// Opened from Chats with the [Connection] as the route argument.
class ChatScreen extends StatefulWidget {
  /// Defaults to [AppServices.connections].
  final ConnectionService? connectionService;

  /// Defaults to [AppServices.chat].
  final ChatService? chatService;

  const ChatScreen({super.key, this.connectionService, this.chatService});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final ConnectionService _connections =
      widget.connectionService ?? AppServices.connections;
  late final ChatService _chat = widget.chatService ?? AppServices.chat;

  final _input = TextEditingController();

  Connection? _connection;
  StreamSubscription<Connection?>? _connectionSub;
  StreamSubscription<List<Message>>? _messagesSub;

  /// Null until the first list arrives.
  List<Message>? _messages;
  Object? _messagesError;
  bool _sending = false;
  bool _confirming = false;

  @override
  void initState() {
    super.initState();
    _input.addListener(() => setState(() {}));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_connection != null) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is! Connection) return;
    _connection = args;
    // The argument is a snapshot; follow the live connection so the
    // roommate bar updates when the partner confirms.
    _connectionSub = _connections.watchConnection(args.id).listen((c) {
      if (c != null) setState(() => _connection = c);
    });
    _messagesSub = _chat.watchMessages(args.id).listen((list) {
      setState(() {
        _messages = list;
        _messagesError = null;
      });
      _markRead();
    }, onError: (Object e) => setState(() => _messagesError = e));
  }

  @override
  void dispose() {
    _connectionSub?.cancel();
    _messagesSub?.cancel();
    _input.dispose();
    super.dispose();
  }

  String get _myUid => _connections.currentUid;

  String get _partnerName =>
      _connection!.otherSummary(_myUid).name.split(' ').first;

  Future<void> _markRead() async {
    try {
      await _connections.markRead(_connection!.id);
    } catch (_) {
      // Only the unread count is affected; try again on the next message.
    }
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _input.clear();
    try {
      await _chat.sendMessage(_connection!.id, text);
    } catch (_) {
      if (!mounted) return;
      // Give the text back so nothing typed is lost.
      if (_input.text.isEmpty) _input.text = text;
      _showMessage('Message not sent. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _confirmRoommate() async {
    final connection = _connection!;
    final name = _partnerName;
    final partnerWaiting = connection.hasConfirmed(connection.otherUid(_myUid));
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Room with $name?'),
        content: Text(
          partnerWaiting
              ? '$name already confirmed. When you confirm, you both see each '
                    "other's student ID, phone and Instagram to apply for the "
                    'dorm together.'
              : 'When $name confirms too, you both see each other\'s student '
                    'ID, phone and Instagram to apply for the dorm together.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not yet'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Yes, we're roommates"),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _confirming = true);
    try {
      final updated = await _connections.confirmRoommate(connection.id);
      if (!mounted) return;
      setState(() => _connection = updated);
      if (updated.isConfirmed) {
        _openConfirmed();
      } else {
        _showMessage(
          "We let $name know. You'll see their student ID once they "
          'confirm too.',
        );
      }
    } catch (_) {
      if (mounted) _showMessage('Could not confirm. Try again.');
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  void _openConfirmed() => Navigator.pushNamed(
    context,
    AppRoutes.roommateConfirmed,
    arguments: _connection,
  );

  void _showMessage(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final connection = _connection;
    if (connection == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Text(
              'This chat is no longer available.',
              style: AppTextStyles.body,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final s = connection.otherSummary(_myUid);
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            MatchAvatar(photoUrl: s.photoUrl, name: s.name, size: 36),
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
                    style: AppTextStyles.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _RoommateBar(
              connection: connection,
              myUid: _myUid,
              partnerName: _partnerName,
              busy: _confirming,
              onConfirm: _confirmRoommate,
              onOpenConfirmed: _openConfirmed,
            ),
            Expanded(child: _messageList()),
            _InputBar(
              controller: _input,
              canSend: _input.text.trim().isNotEmpty && !_sending,
              onSend: _send,
            ),
          ],
        ),
      ),
    );
  }

  Widget _messageList() {
    final messages = _messages;
    if (_messagesError != null && messages == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Text(
            'Could not load the messages. Check your connection and open '
            'this chat again.',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (messages == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text(
            'Say hi to $_partnerName! Ask about sleep, guests or anything '
            'the questionnaire did not cover.',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Oldest first with a day label wherever the day changes, then reversed
    // so the list starts at the bottom and stays there as messages arrive.
    final now = DateTime.now();
    final items = <Object>[];
    for (final (i, m) in messages.indexed) {
      if (i == 0 || !isSameDay(messages[i - 1].sentAt, m.sentAt)) {
        items.add(chatDayLabel(m.sentAt, now));
      }
      items.add(m);
    }
    final reversed = items.reversed.toList();

    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.sm,
      ),
      itemCount: reversed.length,
      itemBuilder: (context, i) {
        final item = reversed[i];
        if (item is String) return _DayLabel(text: item);
        final m = item as Message;
        return _Bubble(message: m, mine: m.isMine(_myUid));
      },
    );
  }
}

/// The "We're roommates" bar under the app bar. Its text and button follow
/// who has confirmed so far.
class _RoommateBar extends StatelessWidget {
  final Connection connection;
  final String myUid;
  final String partnerName;
  final bool busy;
  final VoidCallback onConfirm;
  final VoidCallback onOpenConfirmed;

  const _RoommateBar({
    required this.connection,
    required this.myUid,
    required this.partnerName,
    required this.busy,
    required this.onConfirm,
    required this.onOpenConfirmed,
  });

  static final _compact = FilledButton.styleFrom(
    minimumSize: const Size(0, 36),
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
    textStyle: AppTextStyles.button.copyWith(fontSize: 14),
  );

  @override
  Widget build(BuildContext context) {
    final iConfirmed = connection.hasConfirmed(myUid);
    final theyConfirmed = connection.hasConfirmed(connection.otherUid(myUid));

    final String text;
    Widget? button;
    if (connection.isConfirmed) {
      text = "You're roommates! 🎉";
      button = FilledButton(
        style: _compact,
        onPressed: onOpenConfirmed,
        child: const Text('Student ID'),
      );
    } else if (iConfirmed) {
      text = 'Waiting for $partnerName to confirm.';
    } else {
      text = theyConfirmed
          ? '$partnerName wants to room with you.'
          : 'Ready to apply for the dorm together?';
      button = FilledButton(
        style: _compact,
        onPressed: busy ? null : onConfirm,
        child: busy
            ? const SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text("We're roommates"),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        color: AppColors.primaryLight,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final label = Row(
            children: [
              Icon(
                connection.isConfirmed ? Icons.verified : Icons.home_outlined,
                size: 20,
                color: connection.isConfirmed
                    ? AppColors.success
                    : AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  text,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ],
          );
          if (button == null) return label;
          // On narrow phones or with large text the button goes under the
          // text, so the text never gets squeezed into a thin column.
          final narrow =
              constraints.maxWidth / MediaQuery.textScalerOf(context).scale(1) <
              320;
          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                label,
                const SizedBox(height: AppSpacing.xs),
                button,
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: label),
              const SizedBox(width: AppSpacing.sm),
              button,
            ],
          );
        },
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final Message message;
  final bool mine;

  const _Bubble({required this.message, required this.mine});

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.sizeOf(context).width * 0.75;
    const r = Radius.circular(AppSpacing.radius + 4);
    const tail = Radius.circular(AppSpacing.xs);
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.xs + 2,
        ),
        decoration: BoxDecoration(
          color: mine ? AppColors.primary : AppColors.surface,
          border: mine ? null : Border.all(color: AppColors.border),
          borderRadius: BorderRadius.only(
            topLeft: r,
            topRight: r,
            bottomLeft: mine ? r : tail,
            bottomRight: mine ? tail : r,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message.text,
              style: AppTextStyles.body.copyWith(
                fontSize: 15,
                color: mine ? AppColors.surface : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              clockTime(message.sentAt),
              style: AppTextStyles.caption.copyWith(
                fontSize: 11,
                color: mine
                    ? AppColors.surface.withValues(alpha: 0.75)
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayLabel extends StatelessWidget {
  final String text;

  const _DayLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(AppSpacing.radius),
          ),
          child: Text(text, style: AppTextStyles.caption),
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool canSend;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.canSend,
    required this.onSend,
  });

  /// Long enough for a real message, short enough to keep chats readable.
  static const maxLength = 1000;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              maxLength: maxLength,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                hintText: 'Message',
                counterText: '',
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          IconButton.filled(
            onPressed: canSend ? onSend : null,
            tooltip: 'Send',
            icon: const Icon(Icons.send),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.surface,
              disabledBackgroundColor: AppColors.disabled,
              minimumSize: const Size.square(AppSpacing.controlHeight),
            ),
          ),
        ],
      ),
    );
  }
}
