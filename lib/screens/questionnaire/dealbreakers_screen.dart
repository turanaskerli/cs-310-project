import 'package:flutter/material.dart';

import '../../models/question.dart';
import '../../services/app_services.dart';
import '../../services/questionnaire_service.dart';
import '../../utils/app_routes.dart';
import '../../utils/app_spacing.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/questionnaire/question_card.dart';
import '../../widgets/questionnaire/section_progress.dart';

/// Dealbreakers. Owner: Turan.
///
/// Screen 9, the last questionnaire section: whether the student smokes,
/// vapes or has overnight guests, then which of these they would refuse in a
/// roommate. "None of these" clears the other choices.
class DealbreakersScreen extends StatefulWidget {
  /// Defaults to [AppServices.questionnaire].
  final QuestionnaireService? service;

  const DealbreakersScreen({super.key, this.service});

  @override
  State<DealbreakersScreen> createState() => _DealbreakersScreenState();
}

class _DealbreakersScreenState extends State<DealbreakersScreen> {
  static const _sectionId = 'dealbreakers';

  late final QuestionnaireService _service =
      widget.service ?? AppServices.questionnaire;

  QuestionSection? _section;
  int _totalSections = 0;
  final Map<String, num?> _answers = {};
  final Set<String> _dealbreakers = {};

  /// "None of these" is a choice of its own, so an empty list can mean either
  /// "not answered" or "nothing is a dealbreaker".
  bool _noneChosen = false;
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
      final section = sections.firstWhere((s) => s.id == _sectionId);
      setState(() {
        _totalSections = sections.length;
        _section = section;
        if (saved != null) {
          _answers.addAll(saved.answers);
          _dealbreakers.addAll(saved.dealbreakers);
          _noneChosen =
              saved.dealbreakers.isEmpty &&
              _attributeQuestions.any((q) => saved.answers.containsKey(q.id));
        }
      });
    } catch (e) {
      if (mounted) setState(() => _loadError = e);
    }
  }

  List<Question> get _attributeQuestions => [
    for (final q in _section?.questions ?? const <Question>[])
      if (!q.isDealbreakerSelection) q,
  ];

  Question? get _selectionQuestion {
    for (final q in _section?.questions ?? const <Question>[]) {
      if (q.isDealbreakerSelection) return q;
    }
    return null;
  }

  bool get _isComplete =>
      _attributeQuestions
          .where((q) => !q.optional)
          .every((q) => _answers.containsKey(q.id)) &&
      (_dealbreakers.isNotEmpty || _noneChosen);

  void _toggle(QuestionOption option) {
    setState(() {
      if (option.exclusive) {
        _noneChosen = !_noneChosen;
        if (_noneChosen) _dealbreakers.clear();
        return;
      }
      final key = option.stringValue!;
      _noneChosen = false;
      if (!_dealbreakers.remove(key)) _dealbreakers.add(key);
    });
  }

  Future<bool> _save({bool showMessage = true}) async {
    setState(() => _saving = true);
    try {
      await _service.saveDraft({
        for (final q in _attributeQuestions)
          if (_answers.containsKey(q.id)) q.id: _answers[q.id],
      }, dealbreakers: _dealbreakers.toList());
      if (mounted && showMessage) _showMessage('Draft saved');
      return true;
    } catch (_) {
      if (mounted) _showMessage('Could not save your answers. Try again.');
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _next() async {
    if (await _save(showMessage: false) && mounted) {
      Navigator.pushNamed(context, AppRoutes.reviewSubmit);
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final section = _section;
    if (section == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dealbreakers')),
        body: Center(
          child: _loadError == null
              ? const CircularProgressIndicator()
              : Padding(
                  padding: const EdgeInsets.all(AppSpacing.screenPadding),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Could not load the questions.',
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

    final selection = _selectionQuestion;
    final complete = _isComplete;
    return Scaffold(
      appBar: AppBar(
        title: Text(section.title),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
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
            child: SectionProgress(
              number: _totalSections,
              total: _totalSections,
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                0,
                AppSpacing.screenPadding,
                AppSpacing.lg,
              ),
              children: [
                for (final q in _attributeQuestions) ...[
                  QuestionCard(
                    question: q,
                    answered: _answers.containsKey(q.id),
                    value: _answers[q.id],
                    onChanged: (v) => setState(() => _answers[q.id] = v),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (selection != null) _selectionCard(selection),
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
                  'Answer every question and pick at least one option',
                  style: AppTextStyles.caption,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.maybePop(context),
                      child: const Text('Back'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
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

  Widget _selectionCard(Question question) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              question.text,
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.md),
            for (final option in question.options)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: OptionTile(
                  label: option.label,
                  checkbox: true,
                  selected: option.exclusive
                      ? _noneChosen
                      : _dealbreakers.contains(option.stringValue),
                  onTap: () => _toggle(option),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
