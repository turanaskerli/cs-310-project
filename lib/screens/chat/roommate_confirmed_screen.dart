import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/connection.dart';
import '../../services/app_services.dart';
import '../../services/connection_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_routes.dart';
import '../../utils/app_spacing.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/matches/match_card.dart';

/// Roommate confirmed. Owner: Arda.
///
/// Screen 17: shown once both students pressed "We're roommates". Reveals the
/// partner's student ID, phone and Instagram, each with a copy button, and
/// explains how to request each other in the dorm application.
///
/// Opened from Chat with the [Connection] as the route argument.
class RoommateConfirmedScreen extends StatefulWidget {
  /// Defaults to [AppServices.connections].
  final ConnectionService? service;

  const RoommateConfirmedScreen({super.key, this.service});

  @override
  State<RoommateConfirmedScreen> createState() =>
      _RoommateConfirmedScreenState();
}

class _RoommateConfirmedScreenState extends State<RoommateConfirmedScreen> {
  late final ConnectionService _service =
      widget.service ?? AppServices.connections;

  Connection? _connection;
  Future<RoommateContact?>? _contact;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_connection != null) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Connection) {
      _connection = args;
      _contact = _service.getPartnerContact(args.id);
    }
  }

  void _retry() =>
      setState(() => _contact = _service.getPartnerContact(_connection!.id));

  void _goHome() =>
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);

  Future<void> _copy(String label, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$label copied')));
  }

  @override
  Widget build(BuildContext context) {
    final connection = _connection;
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: connection == null
            ? const _Info(
                text: 'Open this screen from a chat after you both confirm.',
              )
            : FutureBuilder<RoommateContact?>(
                future: _contact,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return _Info(
                      text: 'Could not load the contact details.',
                      action: OutlinedButton(
                        onPressed: _retry,
                        child: const Text('Try again'),
                      ),
                    );
                  }
                  final contact = snapshot.data;
                  if (contact == null) {
                    return const _Info(
                      text:
                          'Contact details appear here once you both '
                          "confirm you're roommates.",
                    );
                  }
                  return _content(connection, contact);
                },
              ),
      ),
    );
  }

  Widget _content(Connection connection, RoommateContact contact) {
    final s = connection.otherSummary(_service.currentUid);
    final first = s.name.split(' ').first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              0,
              AppSpacing.screenPadding,
              AppSpacing.xl,
            ),
            children: [
              Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    MatchAvatar(photoUrl: s.photoUrl, name: s.name, size: 96),
                    const Positioned(
                      right: -4,
                      bottom: -4,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.surface,
                        child: Icon(
                          Icons.verified,
                          color: AppColors.success,
                          size: 30,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                "You and $first are roommates!",
                style: AppTextStyles.title,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'You can now see each other\'s details. Use them to request '
                'each other in the dorm application.',
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              Card(
                child: Column(
                  children: [
                    _DetailRow(
                      icon: Icons.badge_outlined,
                      label: 'Student ID',
                      value: contact.studentId,
                      highlight: true,
                      onCopy: () => _copy('Student ID', contact.studentId),
                    ),
                    if (contact.phone case final phone?) ...[
                      const Divider(height: 1),
                      _DetailRow(
                        icon: Icons.phone_outlined,
                        label: 'Phone',
                        value: phone,
                        onCopy: () => _copy('Phone number', phone),
                      ),
                    ],
                    if (contact.instagram case final instagram?) ...[
                      const Divider(height: 1),
                      _DetailRow(
                        icon: Icons.camera_alt_outlined,
                        label: 'Instagram',
                        value: instagram,
                        onCopy: () => _copy('Instagram', instagram),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _Reminder(partnerName: first, studentId: contact.studentId),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.sm,
            AppSpacing.screenPadding,
            AppSpacing.lg,
          ),
          child: FilledButton(
            onPressed: _goHome,
            child: const Text('Back to home'),
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool highlight;
  final VoidCallback onCopy;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onCopy,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.caption),
                SelectableText(
                  value,
                  style: highlight
                      ? AppTextStyles.title.copyWith(letterSpacing: 2)
                      : AppTextStyles.body,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onCopy,
            tooltip: 'Copy $label',
            icon: const Icon(Icons.copy, size: 20),
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}

/// How to use the student ID in the dorm application.
class _Reminder extends StatelessWidget {
  final String partnerName;
  final String studentId;

  const _Reminder({required this.partnerName, required this.studentId});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.event_note_outlined, color: AppColors.warning),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Don't forget the dorm application",
                  style: AppTextStyles.heading,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Enter $partnerName\'s student ID ($studentId) in the '
                  'roommate request field, and ask $partnerName to enter '
                  'yours. The request only counts if you both do it before '
                  'the deadline.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Info extends StatelessWidget {
  final String text;
  final Widget? action;

  const _Info({required this.text, this.action});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text, style: AppTextStyles.body, textAlign: TextAlign.center),
            if (action != null) ...[
              const SizedBox(height: AppSpacing.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
