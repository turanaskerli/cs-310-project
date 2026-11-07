import 'package:flutter/material.dart';

import '../../models/question.dart';
import '../../services/app_services.dart';
import '../../services/questionnaire_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_routes.dart';
import '../../utils/app_spacing.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/questionnaire/question_card.dart';

/// Questionnaire. Owner: Turan.
///
/// Screen 8: one section per page with a progress bar, Back/Next and Save
/// draft. Previously saved answers are filled in, so it also works as Edit
/// answers. The dealbreakers section has its own screen, which comes next.
class QuestionnaireScreen extends StatefulWidget {
  /// Defaults to [AppServices.questionnaire].
  final QuestionnaireService? service;

  const QuestionnaireScreen({super.key, this.service});

  @override
  State<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  static const _dealbreakersSection = 'dealbreakers';

  late final QuestionnaireService _service =
      widget.service ?? AppServices.questionnaire;

  List<QuestionSection>? _sections;
  final Map<String, num?> _answers = {};
  int _page = 0;
  Object? _loadError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loadError = null);
    try {
      final sections = await _service.getQuestions();
      final saved = await _service.getMyAnswers();
      if (!mounted) return;
      setState(() {
        _sections = sections
            .where((s) => s.id != _dealbreakersSection)
            .toList();
        if (saved != null) _answers.addAll(saved.answers);
      });
    } catch (e) {
      if (mounted) setState(() => _loadError = e);
    }
  }

  bool _isPageComplete(QuestionSection section) => section.questions
      .where((q) => !q.optional)
      .every((q) => _answers.containsKey(q.id));

  Future<void> _saveDraft({bool showMessage = true}) async {
    setState(() => _saving = true);
    try {
      await _service.saveDraft(Map.of(_answers));
      if (mounted && showMessage) _showMessage('Draft saved');
    } catch (_) {
      if (mounted) _showMessage('Could not save your answers. Try again.');
      rethrow;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _next() async {
    final sections = _sections!;
    if (_page < sections.length - 1) {
      setState(() => _page++);
      return;
    }
    try {
      await _saveDraft(showMessage: false);
    } catch (_) {
      return;
    }
    if (mounted) Navigator.pushNamed(context, AppRoutes.dealbreakers);
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final sections = _sections;
    if (sections == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Questionnaire')),
        body: Center(
          child: _loadError == null
              ? const CircularProgressIndicator()
              : _LoadError(onRetry: _load),
        ),
      );
    }

    final section = sections[_page];
    final complete = _isPageComplete(section);
    return Scaffold(
      appBar: AppBar(
        title: Text(section.title),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => _saveDraft().catchError((_) {}),
            child: const Text('Save draft'),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              0,
              AppSpacing.screenPadding,
              AppSpacing.md,
            ),
            child: _Progress(page: _page, total: sections.length),
          ),
          Expanded(
            child: ListView(
              // A new key per section starts each page at the top.
              key: ValueKey(section.id),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                0,
                AppSpacing.screenPadding,
                AppSpacing.lg,
              ),
              children: [
                for (final q in section.questions) ...[
                  QuestionCard(
                    question: q,
                    answered: _answers.containsKey(q.id),
                    value: _answers[q.id],
                    onChanged: (v) => setState(() => _answers[q.id] = v),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!complete) ...[
                const Text(
                  'Answer every question on this page to continue',
                  style: AppTextStyles.caption,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              Row(
                children: [
                  if (_page > 0) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _page--),
                        child: const Text('Back'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                  ],
                  Expanded(
                    child: FilledButton(
                      onPressed: complete && !_saving ? _next : null,
                      child: const Text('Next'),
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

class _Progress extends StatelessWidget {
  final int page;
  final int total;

  const _Progress({required this.page, required this.total});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Section ${page + 1} of $total', style: AppTextStyles.caption),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.xs),
          child: LinearProgressIndicator(
            value: (page + 1) / total,
            minHeight: 6,
            color: AppColors.primary,
            backgroundColor: AppColors.primaryLight,
          ),
        ),
      ],
    );
  }
}

class _LoadError extends StatelessWidget {
  final VoidCallback onRetry;

  const _LoadError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Could not load the questions.',
            style: AppTextStyles.body,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}
