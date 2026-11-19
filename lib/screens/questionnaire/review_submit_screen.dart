import 'package:flutter/material.dart';

import '../../models/answer_set.dart';
import '../../models/question.dart';
import '../../services/app_services.dart';
import '../../services/questionnaire_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_routes.dart';
import '../../utils/app_spacing.dart';
import '../../utils/app_text_styles.dart';

/// Review and submit. Owner: Arda.
///
/// Screen 10: every saved answer grouped by section, with Edit per section.
/// Submit asks for confirmation, saves the final answers (which starts
/// matching) and opens the main tabs on Matches.
class ReviewSubmitScreen extends StatefulWidget {
  /// Defaults to [AppServices.questionnaire].
  final QuestionnaireService? service;

  const ReviewSubmitScreen({super.key, this.service});

  @override
  State<ReviewSubmitScreen> createState() => _ReviewSubmitScreenState();
}

class _ReviewSubmitScreenState extends State<ReviewSubmitScreen> {
  static const _dealbreakersSection = 'dealbreakers';

  late final QuestionnaireService _service =
      widget.service ?? AppServices.questionnaire;

  List<QuestionSection>? _sections;
  AnswerSet _answers = const AnswerSet();
  Object? _loadError;
  bool _submitting = false;

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
        _sections = sections;
        _answers = saved ?? const AnswerSet();
      });
    } catch (e) {
      if (mounted) setState(() => _loadError = e);
    }
  }

  Iterable<Question> get _allQuestions => _sections!.expand((s) => s.questions);

  bool get _isComplete => _answers.isComplete(_allQuestions);

  /// Goes back to the questionnaire page for [section]. The earlier screens
  /// are still on the stack in the normal flow, so this pops back to them and
  /// keeps their state; otherwise it opens them fresh.
  void _edit(QuestionSection section) {
    final route = section.id == _dealbreakersSection
        ? AppRoutes.dealbreakers
        : AppRoutes.questionnaire;
    var found = false;
    Navigator.popUntil(context, (r) {
      if (r.settings.name == route) found = true;
      return found || r.isFirst;
    });
    if (!found) Navigator.pushNamed(context, route);
  }

  Future<void> _submit() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit your answers?'),
        content: const Text(
          "We'll use them to find your matches. You can still change them "
          'later from your Profile.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep reviewing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _submitting = true);
    try {
      await _service.saveAnswers(
        Map.of(_answers.answers),
        List.of(_answers.dealbreakers),
      );
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Could not submit your answers. Try again.'),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sections = _sections;
    if (sections == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Review answers')),
        body: Center(
          child: _loadError == null
              ? const CircularProgressIndicator()
              : Padding(
                  padding: const EdgeInsets.all(AppSpacing.screenPadding),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Could not load your answers.',
                        style: AppTextStyles.body,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      OutlinedButton(
                        onPressed: _load,
                        child: const Text('Try again'),
                      ),
                    ],
                  ),
                ),
        ),
      );
    }

    final complete = _isComplete;
    return Scaffold(
      appBar: AppBar(title: const Text('Review answers')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          0,
          AppSpacing.screenPadding,
          AppSpacing.lg,
        ),
        children: [
          const Text(
            'Check your answers before we look for matches. Honest answers '
            'give you better matches.',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final section in sections) ...[
            _SectionCard(
              section: section,
              answers: _answers,
              onEdit: _submitting ? null : () => _edit(section),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!complete) ...[
                Text(
                  'Some questions are not answered yet. Tap Edit to finish '
                  'them.',
                  style: AppTextStyles.caption.copyWith(color: AppColors.error),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              FilledButton(
                onPressed: complete && !_submitting ? _submit : null,
                child: _submitting
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.surface,
                        ),
                      )
                    : const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One section: its title with Edit, then each question and the answer.
class _SectionCard extends StatelessWidget {
  final QuestionSection section;
  final AnswerSet answers;
  final VoidCallback? onEdit;

  const _SectionCard({
    required this.section,
    required this.answers,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final questions = section.questions.where((q) => q.active).toList();
    final missing = questions.any(
      (q) =>
          !q.optional && !q.isDealbreakerSelection && !answers.isAnswered(q.id),
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.xs,
          AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(section.title, style: AppTextStyles.heading),
                ),
                if (missing)
                  const Icon(
                    Icons.error_outline,
                    size: 20,
                    color: AppColors.error,
                    semanticLabel: 'Not finished',
                  ),
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text('Edit', semanticsLabel: 'Edit ${section.title}'),
                ),
              ],
            ),
            for (final q in questions)
              Padding(
                padding: const EdgeInsets.only(
                  top: AppSpacing.md,
                  right: AppSpacing.md,
                ),
                child: _AnswerLine(question: q, answers: answers),
              ),
          ],
        ),
      ),
    );
  }
}

class _AnswerLine extends StatelessWidget {
  final Question question;
  final AnswerSet answers;

  const _AnswerLine({required this.question, required this.answers});

  /// The answer as text, or null if it still needs an answer.
  String? get _answer {
    final q = question;
    if (q.isDealbreakerSelection) {
      final chosen = answers.dealbreakers
          .map((key) => q.optionFor(key)?.label ?? key)
          .toList();
      return chosen.isEmpty ? 'None of these' : chosen.join(', ');
    }
    if (!answers.isAnswered(q.id)) return q.optional ? 'Skipped' : null;
    final value = answers.answers[q.id];
    if (value == null) return 'Prefer not to say';
    return q.optionFor(value)?.label ?? '$value';
  }

  @override
  Widget build(BuildContext context) {
    final answer = _answer;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(question.text, style: AppTextStyles.bodySmall),
        const SizedBox(height: 2),
        Text(
          answer ?? 'Not answered',
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w600,
            color: answer == null ? AppColors.error : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
