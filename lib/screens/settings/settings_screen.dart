import 'package:flutter/material.dart';

import '../../utils/app_colors.dart';
import '../../utils/app_routes.dart';
import '../../utils/app_spacing.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/matches/match_card.dart';

/// Settings. Owner: Arda.
///
/// Screen 19: hide my profile, notification switches, blocked users with
/// Unblock, Log out, and Delete account behind a typed confirmation.
///
/// The choices live in this screen for now; in Step 3 they are saved to the
/// user's document and Log out / Delete account call the auth service.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

/// A student the user blocked from Match detail or a chat.
class BlockedUser {
  final String uid;
  final String name;
  final String? photoUrl;

  const BlockedUser({required this.uid, required this.name, this.photoUrl});
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _hideProfile = false;
  bool _notifyRequests = true;
  bool _notifyMessages = true;

  final List<BlockedUser> _blocked = [
    const BlockedUser(
      uid: 'mock_emre',
      name: 'Emre Çelik',
      photoUrl: 'https://i.pravatar.cc/300?img=52',
    ),
  ];

  void _showMessage(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  void _setHideProfile(bool value) {
    setState(() => _hideProfile = value);
    _showMessage(
      value
          ? 'Your profile is hidden from new matches'
          : 'Your profile is visible again',
    );
  }

  Future<void> _openBlocked() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _BlockedUsersSheet(
        blocked: _blocked,
        onUnblock: (user) {
          setState(() => _blocked.remove(user));
          _showMessage('${user.name} is unblocked');
        },
      ),
    );
  }

  Future<void> _logOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text(
          'Your matches, requests and chats stay saved. Log in again to see '
          'them.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) _leave();
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const _DeleteAccountDialog(),
    );
    if (confirmed == true && mounted) _leave();
  }

  /// Back to Welcome with nothing to go back to.
  void _leave() => Navigator.pushNamedAndRemoveUntil(
    context,
    AppRoutes.welcome,
    (_) => false,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        children: [
          const _Header('Privacy'),
          SwitchListTile(
            value: _hideProfile,
            onChanged: _setHideProfile,
            secondary: const Icon(Icons.visibility_off_outlined),
            title: const Text('Hide my profile'),
            subtitle: const Text(
              'Stop appearing in other students\' matches, e.g. once you '
              'found a roommate. Your chats stay open.',
            ),
          ),
          ListTile(
            leading: const Icon(Icons.block),
            title: const Text('Blocked users'),
            subtitle: Text(
              _blocked.isEmpty
                  ? 'Nobody blocked'
                  : _blocked.length == 1
                  ? '1 student'
                  : '${_blocked.length} students',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: _openBlocked,
          ),
          const Divider(),
          const _Header('Notifications'),
          SwitchListTile(
            value: _notifyRequests,
            onChanged: (v) => setState(() => _notifyRequests = v),
            secondary: const Icon(Icons.inbox_outlined),
            title: const Text('Roommate requests'),
            subtitle: const Text('When someone sends or accepts a request'),
          ),
          SwitchListTile(
            value: _notifyMessages,
            onChanged: (v) => setState(() => _notifyMessages = v),
            secondary: const Icon(Icons.chat_bubble_outline),
            title: const Text('Messages'),
            subtitle: const Text('When you get a new chat message'),
          ),
          const Divider(),
          const _Header('Account'),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Log out'),
            onTap: _logOut,
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: AppColors.error),
            title: Text(
              'Delete account',
              style: AppTextStyles.body.copyWith(color: AppColors.error),
            ),
            subtitle: const Text(
              'Removes your profile, answers, requests and chats',
            ),
            onTap: _deleteAccount,
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String text;

  const _Header(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.lg,
        AppSpacing.screenPadding,
        AppSpacing.xs,
      ),
      child: Text(
        text.toUpperCase(),
        style: AppTextStyles.caption.copyWith(
          color: AppColors.primary,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

/// Lists blocked students with Unblock. Keeps its own copy of the list so a
/// row disappears as soon as it is unblocked.
class _BlockedUsersSheet extends StatefulWidget {
  final List<BlockedUser> blocked;
  final ValueChanged<BlockedUser> onUnblock;

  const _BlockedUsersSheet({required this.blocked, required this.onUnblock});

  @override
  State<_BlockedUsersSheet> createState() => _BlockedUsersSheetState();
}

class _BlockedUsersSheetState extends State<_BlockedUsersSheet> {
  late final List<BlockedUser> _list = List.of(widget.blocked);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          0,
          AppSpacing.screenPadding,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Blocked users', style: AppTextStyles.heading),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              "Blocked students can't see you in matches or message you.",
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            if (_list.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: Text(
                  "You haven't blocked anyone.",
                  style: AppTextStyles.body,
                  textAlign: TextAlign.center,
                ),
              ),
            for (final user in _list)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  children: [
                    MatchAvatar(
                      photoUrl: user.photoUrl,
                      name: user.name,
                      size: 40,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        user.name,
                        style: AppTextStyles.body,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 36),
                      ),
                      onPressed: () {
                        setState(() => _list.remove(user));
                        widget.onUnblock(user);
                      },
                      child: const Text('Unblock'),
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

/// Asks the user to type DELETE, so the account is never removed by a
/// stray tap.
class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  static const _word = 'DELETE';

  final _formKey = GlobalKey<FormState>();

  void _submit() {
    if (_formKey.currentState!.validate()) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete your account?'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Your profile, answers, requests and chats are removed for '
              'good. This cannot be undone.',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'Type $_word'),
              validator: (v) => v?.trim() == _word
                  ? null
                  : 'Type $_word in capital letters to confirm',
              onFieldSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _submit,
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
