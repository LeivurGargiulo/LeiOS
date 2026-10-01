import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/design/tokens.dart';
import '../../core/widgets/dialogs.dart';
import '../../core/widgets/draft.dart';
import '../../core/widgets/entity_editor.dart';
import '../../core/widgets/format.dart';
import '../../domain/dates.dart';
import '../../domain/models.dart';
import '../../l10n/app_localizations.dart';

/// Opens the task editor: sheet on compact/medium, detail pane (route) on expanded.
void openTask(BuildContext context, {String? id}) {
  if (context.mounted && MediaQuery.sizeOf(context).width >= 840) {
    context.go('/tasks/${id ?? 'new'}');
  } else {
    showEntitySheet(context, builder: (_) => TaskForm(taskId: id, presentation: EditorPresentation.sheet));
  }
}

class TaskForm extends ConsumerStatefulWidget {
  const TaskForm({super.key, this.taskId, required this.presentation, this.onClosed, this.initialDue});

  /// null = create.
  final String? taskId;
  final EditorPresentation presentation;
  final VoidCallback? onClosed;
  final DateTime? initialDue;

  @override
  ConsumerState<TaskForm> createState() => _TaskFormState();
}

enum _DueChoice { today, tomorrow, pick, none }

class _TaskFormState extends ConsumerState<TaskForm> with DraftFormMixin<TaskForm> {
  final _title = TextEditingController();
  final _notes = TextEditingController();
  bool _urgent = false;
  bool _important = false;
  bool _longTerm = false;
  DateTime? _due;
  TaskStatus _status = TaskStatus.todo;
  Task? _original;
  bool _loaded = false;

  @override
  String get draftKey => 'task:${widget.taskId ?? 'new'}';

  @override
  bool get isDirtyDraft => _dirty;

  @override
  Map<String, Object?> snapshot() => {
        'title': _title.text,
        'notes': _notes.text,
        'urgent': _urgent,
        'important': _important,
        'longTerm': _longTerm,
        'due': _due,
        'status': _status,
      };

  @override
  void restore(Map<String, Object?> d) {
    _title.text = d['title'] as String? ?? '';
    _notes.text = d['notes'] as String? ?? '';
    _urgent = d['urgent'] as bool? ?? false;
    _important = d['important'] as bool? ?? false;
    _longTerm = d['longTerm'] as bool? ?? false;
    _due = d['due'] as DateTime?;
    _status = d['status'] as TaskStatus? ?? TaskStatus.todo;
  }

  @override
  void initState() {
    super.initState();
    _due = widget.initialDue;
    _title.addListener(() => setState(() {}));
    _load();
  }

  Future<void> _load() async {
    final id = widget.taskId;
    if (id != null) {
      final t = await ref.read(tasksRepoProvider).get(id);
      if (t != null) {
        _original = t;
        _title.text = t.title;
        _notes.text = t.notes;
        _urgent = t.urgent;
        _important = t.important;
        _longTerm = t.longTerm;
        _due = t.dueDate;
        _status = t.status;
      }
    }
    loadDraft();
    if (mounted) setState(() => _loaded = true);
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  bool get _editing => widget.taskId != null;

  bool get _dirty {
    final o = _original;
    if (o == null) {
      return _title.text.isNotEmpty || _notes.text.isNotEmpty || _urgent || _important || _longTerm || _due != widget.initialDue;
    }
    return _title.text != o.title ||
        _notes.text != o.notes ||
        _urgent != o.urgent ||
        _important != o.important ||
        _longTerm != o.longTerm ||
        _due != o.dueDate ||
        _status != o.status;
  }

  _DueChoice get _choice {
    final today = dateOnly(DateTime.now());
    if (_due == null) return _DueChoice.none;
    if (_due == today) return _DueChoice.today;
    if (_due == addDays(today, 1)) return _DueChoice.tomorrow;
    return _DueChoice.pick;
  }

  Future<void> _pickDate() async {
    final today = dateOnly(DateTime.now());
    final d = await showDatePicker(
      context: context,
      initialDate: _due ?? today,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => _due = dateOnly(d));
  }

  Future<void> _save() async {
    final repo = ref.read(tasksRepoProvider);
    final messenger = ScaffoldMessenger.of(context);
    final l = L10n.of(context);
    if (_editing) {
      await repo.update(
        widget.taskId!,
        title: _title.text,
        notes: _notes.text,
        urgent: _urgent,
        important: _important,
        longTerm: _longTerm,
        dueDate: _due,
        clearDueDate: _due == null,
      );
      if (_original != null && _status != _original!.status) await repo.setStatus(widget.taskId!, _status);
    } else {
      final id = await repo.create(
        title: _title.text,
        notes: _notes.text,
        urgent: _urgent,
        important: _important,
        longTerm: _longTerm,
        dueDate: _due,
      );
      showUndoSnackOn(messenger, l.entityAdded(l.quickAddTask), undoLabel: l.undo, onUndo: () => repo.delete(id));
    }
    discardDraft();
  }

  Future<void> _delete() async {
    final repo = ref.read(tasksRepoProvider);
    final messenger = ScaffoldMessenger.of(context);
    final l = L10n.of(context);
    final t = _original;
    if (t == null) return;
    await repo.delete(t.id);
    discardDraft();
    showUndoSnackOn(messenger, l.entityDeleted(l.quickAddTask), undoLabel: l.undo, onUndo: () => repo.restore(t));
    if (!mounted) return;
    if (widget.presentation == EditorPresentation.inline) {
      widget.onClosed?.call();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final fmt = ref.watch(formatDateProvider);
    if (!_loaded) return const SizedBox(height: 160, child: Center(child: CircularProgressIndicator()));
    final choice = _choice;
    return EntityEditor(
      presentation: widget.presentation,
      title: _editing ? l.taskEdit : l.taskNew,
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
            autofocus: widget.presentation == EditorPresentation.sheet,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(labelText: l.title),
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: Space.lg),
          Wrap(
            spacing: Space.sm,
            runSpacing: Space.sm,
            children: [
              ChoiceChip(
                label: Text(l.today),
                selected: choice == _DueChoice.today,
                onSelected: (_) => setState(() => _due = dateOnly(DateTime.now())),
              ),
              ChoiceChip(
                label: Text(l.tomorrow),
                selected: choice == _DueChoice.tomorrow,
                onSelected: (_) => setState(() => _due = addDays(dateOnly(DateTime.now()), 1)),
              ),
              ChoiceChip(
                label: Text(choice == _DueChoice.pick && _due != null ? fmt(_due!) : l.taskPickDate),
                avatar: const Icon(Icons.event, size: 18),
                selected: choice == _DueChoice.pick,
                onSelected: (_) => _pickDate(),
              ),
              ChoiceChip(
                label: Text(l.noDate),
                selected: choice == _DueChoice.none,
                onSelected: (_) => setState(() => _due = null),
              ),
            ],
          ),
          const SizedBox(height: Space.md),
          Wrap(
            spacing: Space.sm,
            runSpacing: Space.sm,
            children: [
              FilterChip(label: Text(l.urgent), selected: _urgent, onSelected: (v) => setState(() => _urgent = v)),
              FilterChip(label: Text(l.important), selected: _important, onSelected: (v) => setState(() => _important = v)),
              FilterChip(label: Text(l.longTerm), selected: _longTerm, onSelected: (v) => setState(() => _longTerm = v)),
            ],
          ),
          if (_editing) ...[
            const SizedBox(height: Space.md),
            SegmentedButton<TaskStatus>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: TaskStatus.todo, label: Text(l.statusTodo)),
                ButtonSegment(value: TaskStatus.doing, label: Text(l.statusDoing)),
                ButtonSegment(value: TaskStatus.done, label: Text(l.statusDone)),
              ],
              selected: {_status},
              onSelectionChanged: (s) => setState(() => _status = s.first),
            ),
          ],
          MoreDetails(
            label: l.notes,
            initiallyOpen: _notes.text.isNotEmpty,
            child: Padding(
              padding: const EdgeInsets.only(bottom: Space.sm),
              child: TextField(
                controller: _notes,
                minLines: 2,
                maxLines: 6,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(labelText: l.notes),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
