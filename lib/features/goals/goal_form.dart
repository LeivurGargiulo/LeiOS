import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/design/tokens.dart';
import '../../core/widgets/dialogs.dart';
import '../../core/widgets/draft.dart';
import '../../core/widgets/entity_editor.dart';
import '../../core/widgets/format.dart';
import '../../core/widgets/period_picker.dart';
import '../../core/widgets/reorderable_group.dart';
import '../../core/widgets/small_widgets.dart';
import '../../core/widgets/swipe_action_tile.dart';
import '../../domain/dates.dart';
import '../../domain/goals.dart';
import '../../domain/models.dart';
import '../../domain/tasks.dart';
import '../../l10n/app_localizations.dart';

void openGoal(BuildContext context, {String? id}) {
  if (MediaQuery.sizeOf(context).width >= 840) {
    context.go('/goals/${id ?? 'new'}');
  } else {
    pushEntityScreen(context, builder: (_) => GoalForm(goalId: id, presentation: EditorPresentation.screen));
  }
}

String goalStatusLabel(GoalStatus s) => switch (s) { GoalStatus.pending => 'Pending', GoalStatus.active => 'Active', GoalStatus.completed => 'Completed' };

class GoalForm extends ConsumerStatefulWidget {
  const GoalForm({super.key, this.goalId, required this.presentation, this.onClosed});
  final String? goalId;
  final EditorPresentation presentation;
  final VoidCallback? onClosed;

  @override
  ConsumerState<GoalForm> createState() => _GoalFormState();
}

class _GoalFormState extends ConsumerState<GoalForm> with DraftFormMixin<GoalForm> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _newStep = TextEditingController();
  DateTime? _target;
  GoalPrecision? _precision;
  GoalStatus _status = GoalStatus.pending;
  Goal? _original;
  bool _loaded = false;

  /// Steps added before the goal exists (create mode only).
  final List<String> _pendingSteps = [];

  @override
  String get draftKey => 'goal:${widget.goalId ?? 'new'}';
  @override
  bool get isDirtyDraft => _dirty;
  @override
  Map<String, Object?> snapshot() => {
        'title': _title.text,
        'description': _description.text,
        'target': _target,
        'precision': _precision,
        'status': _status,
        'pending': [..._pendingSteps],
      };
  @override
  void restore(Map<String, Object?> d) {
    _title.text = d['title'] as String? ?? '';
    _description.text = d['description'] as String? ?? '';
    _target = d['target'] as DateTime?;
    _precision = d['precision'] as GoalPrecision?;
    _status = d['status'] as GoalStatus? ?? GoalStatus.pending;
    _pendingSteps
      ..clear()
      ..addAll((d['pending'] as List?)?.cast<String>() ?? const []);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final id = widget.goalId;
    if (id != null) {
      final all = await ref.read(goalsRepoProvider).watchGoals().first;
      final g = all.where((e) => e.id == id).firstOrNull;
      if (g != null) {
        _original = g;
        _title.text = g.title;
        _description.text = g.description;
        _target = g.targetDate;
        _precision = g.precision;
        _status = g.status;
      }
    }
    loadDraft();
    if (mounted) setState(() => _loaded = true);
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _newStep.dispose();
    super.dispose();
  }

  bool get _editing => widget.goalId != null;

  bool get _dirty {
    final o = _original;
    if (o == null) {
      return _title.text.isNotEmpty || _description.text.isNotEmpty || _target != null || _pendingSteps.isNotEmpty || _status != GoalStatus.pending;
    }
    return _title.text != o.title || _description.text != o.description || _target != o.targetDate || _precision != o.precision || _status != o.status;
  }

  Future<void> _save() async {
    final repo = ref.read(goalsRepoProvider);
    final messenger = ScaffoldMessenger.of(context);
    final l = L10n.of(context);
    if (_editing) {
      await repo.update(widget.goalId!, title: _title.text, description: _description.text, setTarget: true, targetDate: _target, precision: _precision, status: _status);
    } else {
      final id = await repo.create(title: _title.text, description: _description.text, targetDate: _target, precision: _precision, status: _status);
      for (final s in _pendingSteps) {
        await repo.addStep(id, s);
      }
      showUndoSnackOn(messenger, l.entityAdded('Goal'), undoLabel: l.undo, onUndo: () => repo.delete(id));
    }
    discardDraft();
  }

  Future<void> _delete() async {
    final o = _original;
    if (o == null) return;
    final ok = await confirmDelete(context, title: 'Delete goal?', body: 'This also deletes the goal\'s checklist steps.');
    if (!ok || !mounted) return;
    await ref.read(goalsRepoProvider).delete(o.id);
    discardDraft();
    if (!mounted) return;
    if (widget.presentation == EditorPresentation.inline) {
      widget.onClosed?.call();
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _addStep() async {
    final t = _newStep.text.trim();
    if (t.isEmpty) return;
    if (_editing) {
      await ref.read(goalsRepoProvider).addStep(widget.goalId!, t);
    } else {
      setState(() => _pendingSteps.add(t));
    }
    _newStep.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final fmt = ref.watch(formatDateProvider);
    final allSteps = ref.watch(goalStepsProvider).asData?.value ?? const <GoalStep>[];
    final steps = _editing ? allSteps.where((s) => s.goalId == widget.goalId).toList() : <GoalStep>[];
    final repo = ref.read(goalsRepoProvider);

    final draftGoal = Goal(
      id: widget.goalId ?? 'new',
      title: _title.text,
      targetDate: _target,
      precision: _precision,
      status: _status,
      createdAt: _original?.createdAt ?? DateTime.now().toUtc(),
    );
    final progress = _editing
        ? goalProgress(draftGoal, steps, DateTime.now())
        : (_pendingSteps.isEmpty ? goalProgress(draftGoal, const [], DateTime.now()) : 0.0);

    return EntityEditor(
      presentation: widget.presentation,
      title: _editing ? 'Edit goal' : 'New goal',
      dirty: _dirty,
      valid: _title.text.trim().isNotEmpty,
      onSave: _save,
      onDelete: _editing ? _delete : null,
      onClosed: () {
        discardDraft();
        widget.onClosed?.call();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _title,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Title'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: Space.md),
          TextField(
            controller: _description,
            minLines: 2,
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Description'),
            onChanged: (_) => setState(() {}),
          ),
          const SectionHeader('Target', padding: EdgeInsets.only(top: Space.lg, bottom: Space.sm)),
          PeriodPicker(date: _target, precision: _precision, format: fmt, onChanged: (d, p) => setState(() {
                _target = d;
                _precision = p;
              })),
          const SectionHeader('Status', padding: EdgeInsets.only(top: Space.lg, bottom: Space.sm)),
          Wrap(spacing: Space.sm, runSpacing: Space.sm, crossAxisAlignment: WrapCrossAlignment.center, children: [
            Chip(label: Text(goalStatusLabel(_status))),
            FilledButton.tonal(onPressed: () => setState(() => _status = nextGoalStatus(_status)), child: Text(goalAdvanceLabel(_status))),
          ]),
          const SectionHeader('Progress', padding: EdgeInsets.only(top: Space.lg, bottom: Space.sm)),
          LabeledProgress(percent: progress, label: formatProgress(progress), semanticsLabel: 'Goal progress'),
          const SectionHeader('Steps', padding: EdgeInsets.only(top: Space.lg, bottom: Space.sm)),
          if (_editing)
            ReorderableGroup<GoalStep>(
              items: steps,
              idOf: (s) => s.id,
              onReorder: (o, n) => repo.reorderSteps(widget.goalId!, o, n),
              onMove: (s, dir) => repo.moveStep(widget.goalId!, s.id, dir),
              itemBuilder: (context, s) => SwipeActionTile(
                key: ValueKey('step-${s.id}'),
                onSwipeLeft: () => repo.deleteStep(widget.goalId!, s.id),
                menuItems: [TileMenuItem(label: 'Delete', icon: Icons.delete_outline, destructive: true, onTap: () => repo.deleteStep(widget.goalId!, s.id))],
                child: CheckboxListTile(
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  value: s.done,
                  title: Text(s.title, style: s.done ? const TextStyle(decoration: TextDecoration.lineThrough) : null),
                  onChanged: (v) => repo.updateStep(s.id, done: v ?? false),
                ),
              ),
            )
          else
            for (var i = 0; i < _pendingSteps.length; i++)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.check_box_outline_blank),
                title: Text(_pendingSteps[i]),
                trailing: IconButton(tooltip: 'Remove step', icon: const Icon(Icons.close), onPressed: () => setState(() => _pendingSteps.removeAt(i))),
              ),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _newStep,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Add a step'),
                onSubmitted: (_) => _addStep(),
              ),
            ),
            const SizedBox(width: Space.sm),
            IconButton.filled(tooltip: 'Add step', icon: const Icon(Icons.add), onPressed: _addStep),
          ]),
          if (_original != null)
            Padding(
              padding: const EdgeInsets.only(top: Space.md),
              child: Text('Created ${fmt(dateOnly(_original!.createdAt.toLocal()))}', style: Theme.of(context).textTheme.labelSmall),
            ),
        ],
      ),
    );
  }
}
