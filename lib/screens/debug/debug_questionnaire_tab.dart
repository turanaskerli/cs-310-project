import 'package:flutter/material.dart';

import '../../models/answer_set.dart';
import '../../models/question.dart';
import '../../services/questionnaire_service.dart';

/// Every section and question from the service, with tappable answers,
/// Save draft and Submit.
class DebugQuestionnaireTab extends StatefulWidget {
  final QuestionnaireService service;

  const DebugQuestionnaireTab({super.key, required this.service});

  @override
  State<DebugQuestionnaireTab> createState() => _DebugQuestionnaireTabState();
}

class _DebugQuestionnaireTabState extends State<DebugQuestionnaireTab>
    with AutomaticKeepAliveClientMixin {
  late final Future<List<QuestionSection>> _sections;
  final Map<String, num?> _answers = {};
  final Set<String> _dealbreakers = {};
  bool _noDealbreakers = false;
  AnswerSet? _saved;
  bool _busy = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _sections = widget.service.getQuestions();
    widget.service.getMyAnswers().then((saved) {
      if (!mounted || saved == null) return;
      setState(() {
        _saved = saved;
        _answers.addAll(saved.answers);
        _dealbreakers.addAll(saved.dealbreakers);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<List<QuestionSection>>(
      future: _sections,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Could not load questions:\n${snapshot.error}'),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final sections = snapshot.data!;
        final questions = [for (final s in sections) ...s.questions];
        return Column(
          children: [
            _progress(questions),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 16),
                children: [for (final s in sections) _section(s)],
              ),
            ),
            _actions(questions),
          ],
        );
      },
    );
  }

  Widget _progress(List<Question> questions) {
    final required = questions
        .where((q) => !q.optional && !q.isDealbreakerSelection)
        .toList();
    final answered = required.where((q) => _answers.containsKey(q.id)).length;
    final saved = _saved;
    final status = saved == null
        ? 'Nothing saved yet'
        : '${saved.isDraft ? 'Draft' : 'Submitted'}: ${saved.answers.length} '
              'answers, dealbreakers ${saved.dealbreakers.isEmpty ? 'none' : saved.dealbreakers.join(', ')}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$answered of ${required.length} required questions answered'),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: required.isEmpty ? 0 : answered / required.length,
          ),
          const SizedBox(height: 6),
          Text(status, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _section(QuestionSection section) {
    final answered = section.questions
        .where((q) => _answers.containsKey(q.id))
        .length;
    return ExpansionTile(
      title: Text('${section.order}. ${section.title}'),
      subtitle: Text('$answered / ${section.questions.length} answered'),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      children: [for (final q in section.questions) _question(q)],
    );
  }

  Widget _question(Question q) {
    final meta =
        '${q.id} · ${q.type.name} · ${q.trait}/${q.direction.name}'
        '${q.optional ? ' · optional' : ''}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(q.text, style: Theme.of(context).textTheme.titleSmall),
          Text(meta, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final o in q.options)
                q.isDealbreakerSelection
                    ? _dealbreakerChip(o)
                    : _answerChip(q, o),
            ],
          ),
        ],
      ),
    );
  }

  Widget _answerChip(Question q, QuestionOption o) => ChoiceChip(
    label: Text('${o.label}  (${o.value ?? '–'})'),
    selected: _answers.containsKey(q.id) && _answers[q.id] == o.numValue,
    onSelected: (_) => setState(() => _answers[q.id] = o.numValue),
  );

  Widget _dealbreakerChip(QuestionOption o) {
    final key = o.stringValue!;
    return FilterChip(
      label: Text(o.label),
      selected: o.exclusive ? _noDealbreakers : _dealbreakers.contains(key),
      onSelected: (on) => setState(() {
        if (o.exclusive) {
          _noDealbreakers = on;
          if (on) _dealbreakers.clear();
        } else {
          _noDealbreakers = false;
          on ? _dealbreakers.add(key) : _dealbreakers.remove(key);
        }
      }),
    );
  }

  Widget _actions(List<Question> questions) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _busy ? null : _saveDraft,
                child: const Text('Save draft'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: _busy ? null : () => _submit(questions),
                child: const Text('Submit'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveDraft() => _run('Draft saved', () {
    return widget.service.saveDraft(
      Map.of(_answers),
      dealbreakers: _dealbreakers.toList(),
    );
  });

  Future<void> _submit(List<Question> questions) async {
    final missing = questions
        .where((q) => !q.optional && !q.isDealbreakerSelection)
        .where((q) => !_answers.containsKey(q.id))
        .length;
    if (missing > 0) {
      _snack('$missing required questions are not answered yet');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit answers?'),
        content: const Text('Matching uses these answers.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _run('Answers submitted', () {
      return widget.service.saveAnswers(
        Map.of(_answers),
        _dealbreakers.toList(),
      );
    });
  }

  Future<void> _run(String done, Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      final saved = await widget.service.getMyAnswers();
      if (!mounted) return;
      setState(() => _saved = saved);
      _snack(done);
    } catch (e) {
      _snack('Failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }
}
