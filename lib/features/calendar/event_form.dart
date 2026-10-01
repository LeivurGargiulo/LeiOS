import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/design/tokens.dart';
import '../../core/widgets/dialogs.dart';
import '../../core/widgets/draft.dart';
import '../../core/widgets/entity_editor.dart';
import '../../core/widgets/format.dart';
import '../../core/widgets/small_widgets.dart';
import '../../domain/dates.dart';
import '../../domain/models.dart';
import '../../l10n/app_localizations.dart';

void openEvent(BuildContext context, {String? id, DateTime? day}) {
  final d = isoDate(day ?? DateTime.now());
  if (MediaQuery.sizeOf(context).width >= 840) {
    context.go('/calendar/$d/${id ?? 'new'}');
  } else {
    pushEntityScreen(context, builder: (_) => EventForm(eventId: id, initialDate: day, presentation: EditorPresentation.screen));
  }
}

const _dayLetters = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

class EventForm extends ConsumerStatefulWidget {
  const EventForm({super.key, this.eventId, this.initialDate, required this.presentation, this.onClosed});
  final String? eventId;
  final DateTime? initialDate;
  final EditorPresentation presentation;
  final VoidCallback? onClosed;

  @override
  ConsumerState<EventForm> createState() => _EventFormState();
}

class _EventFormState extends ConsumerState<EventForm> with DraftFormMixin<EventForm> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  late DateTime _date = dateOnly(widget.initialDate ?? DateTime.now());
  DateTime? _endDate;
  int? _start;
  int? _end;
  bool _allDay = true;
  bool _repeat = false;
  int _mask = 0;
  DateTime? _until;
  Event? _original;
  bool _loaded = false;

  @override
  String get draftKey => 'event:${widget.eventId ?? 'new'}';
  @override
  bool get isDirtyDraft => _dirty;
  @override
  Map<String, Object?> snapshot() => {
        'title': _title.text,
        'description': _description.text,
        'date': _date,
        'endDate': _endDate,
        'start': _start,
        'end': _end,
        'allDay': _allDay,
        'repeat': _repeat,
        'mask': _mask,
        'until': _until,
      };
  @override
  void restore(Map<String, Object?> d) {
    _title.text = d['title'] as String? ?? '';
    _description.text = d['description'] as String? ?? '';
    _date = d['date'] as DateTime? ?? _date;
    _endDate = d['endDate'] as DateTime?;
    _start = d['start'] as int?;
    _end = d['end'] as int?;
    _allDay = d['allDay'] as bool? ?? true;
    _repeat = d['repeat'] as bool? ?? false;
    _mask = d['mask'] as int? ?? 0;
    _until = d['until'] as DateTime?;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final id = widget.eventId;
    if (id != null) {
      final e = await ref.read(eventsRepoProvider).get(id);
      if (e != null) {
        _original = e;
        _title.text = e.title;
        _description.text = e.description;
        _date = e.date;
        _endDate = e.endDate;
        _start = e.startMinutes;
        _end = e.endMinutes;
        _allDay = e.startMinutes == null;
        _repeat = e.weekdays != null;
        _mask = e.weekdays ?? 0;
        _until = e.until;
      }
    }
    if (_mask == 0) _mask = weekdayBitFor(_date);
    loadDraft();
    if (mounted) setState(() => _loaded = true);
  }

  int weekdayBitFor(DateTime d) => 1 << (d.weekday - 1);

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  bool get _editing => widget.eventId != null;

  bool get _dirty {
    final o = _original;
    if (o == null) {
      return _title.text.isNotEmpty || _description.text.isNotEmpty || !_allDay || _repeat || _endDate != null;
    }
    return _title.text != o.title ||
        _description.text != o.description ||
        _date != o.date ||
        _endDate != o.endDate ||
        (_allDay ? null : _start) != o.startMinutes ||
        (_allDay ? null : _end) != o.endMinutes ||
        (_repeat ? _mask : null) != o.weekdays ||
        (_repeat ? _until : null) != o.until;
  }

  Future<void> _pickDate(DateTime initial, ValueChanged<DateTime> set) async {
    final d = await showDatePicker(context: context, initialDate: initial, firstDate: DateTime(2000), lastDate: DateTime(2100));
    if (d != null) setState(() => set(dateOnly(d)));
  }

  Future<void> _pickTime(int? current, ValueChanged<int> set) async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: (current ?? 9 * 60) ~/ 60, minute: (current ?? 0) % 60),
    );
    if (t != null) setState(() => set(t.hour * 60 + t.minute));
  }

  Future<void> _save() async {
    final repo = ref.read(eventsRepoProvider);
    final messenger = ScaffoldMessenger.of(context);
    final l = L10n.of(context);
    final start = _allDay ? null : (_start ?? 9 * 60);
    final end = _allDay ? null : _end;
    final weekdays = _repeat ? _mask : null;
    final endDate = _repeat ? null : _endDate;
    final until = _repeat ? _until : null;
    if (_editing) {
      await repo.update(widget.eventId!, title: _title.text, description: _description.text, date: _date, endDate: endDate, startMinutes: start, endMinutes: end, weekdays: weekdays, until: until);
    } else {
      final id = await repo.create(title: _title.text, description: _description.text, date: _date, endDate: endDate, startMinutes: start, endMinutes: end, weekdays: weekdays, until: until);
      showUndoSnackOn(messenger, l.entityAdded('Event'), undoLabel: l.undo, onUndo: () => repo.delete(id));
    }
    discardDraft();
  }

  Future<void> _delete() async {
    final o = _original;
    if (o == null) return;
    final ok = await confirmDelete(
      context,
      title: 'Delete event?',
      body: o.recurring ? 'This deletes the whole repeating series, not just one occurrence.' : 'This event will be deleted.',
    );
    if (!ok || !mounted) return;
    final repo = ref.read(eventsRepoProvider);
    final messenger = ScaffoldMessenger.of(context);
    final l = L10n.of(context);
    await repo.delete(o.id);
    discardDraft();
    showUndoSnackOn(messenger, l.entityDeleted('Event'), undoLabel: l.undo, onUndo: () => repo.restore(o));
    if (!mounted) return;
    if (widget.presentation == EditorPresentation.inline) {
      widget.onClosed?.call();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final fmt = ref.watch(formatDateProvider);
    return EntityEditor(
      presentation: widget.presentation,
      title: _editing ? 'Edit event' : 'New event',
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
          const SectionHeader('When', padding: EdgeInsets.only(top: Space.lg, bottom: Space.xs)),
          SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('All day'), value: _allDay, onChanged: (v) => setState(() => _allDay = v)),
          Wrap(spacing: Space.sm, runSpacing: Space.sm, children: [
            OutlinedButton.icon(icon: const Icon(Icons.event), label: Text(fmt(_date)), onPressed: () => _pickDate(_date, (d) {
                  _date = d;
                  if (_endDate != null && _endDate!.isBefore(d)) _endDate = null;
                })),
            if (!_allDay) ...[
              OutlinedButton.icon(
                icon: const Icon(Icons.schedule),
                label: Text(_start == null ? 'Start time' : formatTimeOfDayMinutes(context, _start!)),
                onPressed: () => _pickTime(_start, (m) => _start = m),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.schedule),
                label: Text(_end == null ? 'End time' : formatTimeOfDayMinutes(context, _end!)),
                onPressed: () => _pickTime(_end ?? _start, (m) => _end = m),
              ),
              if (_end != null) TextButton(onPressed: () => setState(() => _end = null), child: const Text('Clear end')),
            ],
          ]),
          const SectionHeader('Repeat', padding: EdgeInsets.only(top: Space.lg, bottom: Space.xs)),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Repeat weekly'),
            value: _repeat,
            onChanged: (v) => setState(() {
              _repeat = v;
              if (v) _endDate = null;
            }),
          ),
          if (_repeat) ...[
            Wrap(spacing: Space.sm, runSpacing: Space.sm, children: [
              for (var i = 0; i < 7; i++)
                FilterChip(
                  label: Text(_dayLetters[i]),
                  selected: (_mask & (1 << i)) != 0,
                  onSelected: (s) => setState(() => _mask = s ? (_mask | (1 << i)) : (_mask & ~(1 << i))),
                ),
            ]),
            const SizedBox(height: Space.sm),
            Wrap(spacing: Space.sm, runSpacing: Space.sm, crossAxisAlignment: WrapCrossAlignment.center, children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.event_busy),
                label: Text(_until == null ? 'Until (optional)' : 'Until ${fmt(_until!)}'),
                onPressed: () => _pickDate(_until ?? _date, (d) => _until = d),
              ),
              if (_until != null) TextButton(onPressed: () => setState(() => _until = null), child: const Text('Clear')),
            ]),
          ] else
            Wrap(spacing: Space.sm, runSpacing: Space.sm, crossAxisAlignment: WrapCrossAlignment.center, children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.date_range),
                label: Text(_endDate == null ? 'End date (multi-day)' : 'Ends ${fmt(_endDate!)}'),
                onPressed: () => _pickDate(_endDate ?? _date, (d) => _endDate = d),
              ),
              if (_endDate != null) TextButton(onPressed: () => setState(() => _endDate = null), child: const Text('Clear')),
            ]),
          const SectionHeader('Details', padding: EdgeInsets.only(top: Space.lg, bottom: Space.sm)),
          TextField(
            controller: _description,
            minLines: 2,
            maxLines: 6,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Description'),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }
}
