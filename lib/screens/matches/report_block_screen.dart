import 'package:flutter/material.dart';

import '../../models/recommendation.dart';
import '../../models/report.dart';
import '../../services/app_services.dart';
import '../../services/report_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_spacing.dart';
import '../../utils/app_text_styles.dart';
import '../../utils/validators.dart';
import '../../widgets/app_text_field.dart';

/// What the user did on [ReportBlockScreen]. Returned when the screen closes
/// after a success; `null` if they left without sending anything.
enum ReportBlockResult {
  reported,
  blocked,
  reportedAndBlocked;

  bool get isBlocked => this != reported;
}

/// Report or block. Owner: Bassam (built by Turan).
///
/// Opened from Match detail with the [Recommendation] as the route argument.
/// The user picks a reason, can add details (required for "Something else"),
/// and chooses whether to block too. A separate button blocks without
/// reporting. Every action asks for confirmation first, then the screen shows
/// a success state and returns a [ReportBlockResult].
class ReportBlockScreen extends StatefulWidget {
  /// Defaults to [AppServices.reports].
  final ReportService? service;

  const ReportBlockScreen({super.key, this.service});

  static const int maxDetailsLength = 500;

  @override
  State<ReportBlockScreen> createState() => _ReportBlockScreenState();
}

class _ReportBlockScreenState extends State<ReportBlockScreen> {
  late final ReportService _service = widget.service ?? AppServices.reports;
  final _formKey = GlobalKey<FormState>();
  final _details = TextEditingController();

  Recommendation? _match;
  ReportReason? _reason;
  bool _alsoBlock = true;
  bool _sending = false;
  ReportBlockResult? _done;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (_match == null && args is Recommendation) _match = args;
  }

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  String get _name => _match!.otherSummary.name;
  String get _firstName => _name.split(' ').first;

  String? _validateDetails(String? value) {
    if (_reason == ReportReason.other) {
      final missing = Validators.required('Details')(value);
      if (missing != null) return 'Tell us what happened';
    }
    return Validators.maxLength(
      ReportBlockScreen.maxDetailsLength,
      fieldName: 'Details',
    )(value);
  }

  Future<void> _submitReport() async {
    if (_reason == null || !_formKey.currentState!.validate()) return;
    final ok = await _confirm(
      title: 'Report $_firstName?',
      text: _alsoBlock
          ? "We'll review your report and block $_firstName. They won't "
                'know who reported them.'
          : "We'll review your report. $_firstName won't know who reported "
                'them.',
      action: _alsoBlock ? 'Report and block' : 'Report',
    );
    if (!ok) return;
    await _run(() async {
      await _service.submitReport(
        reportedUid: _match!.otherUid,
        reason: _reason!,
        details: _details.text,
        block: _alsoBlock,
      );
      return _alsoBlock
          ? ReportBlockResult.reportedAndBlocked
          : ReportBlockResult.reported;
    });
  }

  Future<void> _blockOnly() async {
    final ok = await _confirm(
      title: 'Block $_firstName?',
      text:
          "$_firstName won't appear in your matches and can't send you "
          "requests or messages. They won't be told.",
      action: 'Block',
    );
    if (!ok) return;
    await _run(() async {
      await _service.block(_match!.otherUid);
      return ReportBlockResult.blocked;
    });
  }

  Future<void> _run(Future<ReportBlockResult> Function() action) async {
    setState(() => _sending = true);
    try {
      final result = await action();
      if (mounted) setState(() => _done = result);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Something went wrong. Try again.')),
        );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

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
            child: const Text('Cancel'),
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

  @override
  Widget build(BuildContext context) {
    if (_match == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Text(
              'This student is no longer available.',
              style: AppTextStyles.body,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    final done = _done;
    if (done != null) {
      return Scaffold(
        appBar: AppBar(automaticallyImplyLeading: false),
        body: SafeArea(
          child: _Success(
            result: done,
            firstName: _firstName,
            onDone: () => Navigator.pop(context, done),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Report or block')),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenPadding,
                    AppSpacing.sm,
                    AppSpacing.screenPadding,
                    AppSpacing.lg,
                  ),
                  children: [
                    Text(
                      'Why are you reporting $_firstName?',
                      style: AppTextStyles.heading,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      "Reports are anonymous. $_firstName won't know it was "
                      'you.',
                      style: AppTextStyles.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    for (final reason in ReportReason.values)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _ReasonTile(
                          reason: reason,
                          selected: _reason == reason,
                          onTap: _sending
                              ? null
                              : () => setState(() => _reason = reason),
                        ),
                      ),
                    if (_reason != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      AppTextField(
                        controller: _details,
                        enabled: !_sending,
                        maxLines: 4,
                        maxLength: ReportBlockScreen.maxDetailsLength,
                        label: _reason == ReportReason.other
                            ? 'What happened?'
                            : 'Anything else? (optional)',
                        hint: 'Add details that help us review it',
                        validator: _validateDetails,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _alsoBlock,
                      onChanged: _sending
                          ? null
                          : (v) => setState(() => _alsoBlock = v),
                      title: Text(
                        'Also block $_firstName',
                        style: AppTextStyles.body,
                      ),
                      subtitle: const Text(
                        "They won't see you or be able to message you.",
                        style: AppTextStyles.bodySmall,
                      ),
                    ),
                    const Divider(height: AppSpacing.xl),
                    Text(
                      'Just want to stop seeing them?',
                      style: AppTextStyles.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        minimumSize: const Size.fromHeight(
                          AppSpacing.controlHeight,
                        ),
                      ),
                      onPressed: _sending ? null : _blockOnly,
                      icon: const Icon(Icons.block),
                      label: Text('Block without reporting'),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.sm,
                AppSpacing.screenPadding,
                AppSpacing.sm,
              ),
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                onPressed: _reason == null || _sending ? null : _submitReport,
                child: _sending
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.surface,
                        ),
                      )
                    : const Text('Submit report'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReasonTile extends StatelessWidget {
  final ReportReason reason;
  final bool selected;
  final VoidCallback? onTap;

  const _ReasonTile({
    required this.reason,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primaryLight : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.border,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Semantics(
          selected: selected,
          button: true,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: selected ? AppColors.primary : AppColors.disabled,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reason.label,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(reason.description, style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Success extends StatelessWidget {
  final ReportBlockResult result;
  final String firstName;
  final VoidCallback onDone;

  const _Success({
    required this.result,
    required this.firstName,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final (title, text) = switch (result) {
      ReportBlockResult.reported => (
        'Report sent',
        "Thanks for letting us know. We'll review it and take action if "
            'needed.',
      ),
      ReportBlockResult.reportedAndBlocked => (
        'Report sent and $firstName blocked',
        "We'll review your report. $firstName won't appear in your matches "
            'or be able to message you.',
      ),
      ReportBlockResult.blocked => (
        '$firstName is blocked',
        "$firstName won't appear in your matches or be able to message you.",
      ),
    };
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          const Icon(Icons.check_circle, size: 72, color: AppColors.success),
          const SizedBox(height: AppSpacing.lg),
          Text(title, style: AppTextStyles.title, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.sm),
          Text(text, style: AppTextStyles.body, textAlign: TextAlign.center),
          const Spacer(),
          FilledButton(onPressed: onDone, child: const Text('Done')),
        ],
      ),
    );
  }
}
