import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/design/motion.dart';
import '../../core/design/tokens.dart';
import '../../core/widgets/entity_editor.dart';
import '../../core/widgets/small_widgets.dart';
import '../../domain/dates.dart';
import '../../domain/models.dart';
import '../../domain/tags.dart';

const moodIcons = [
  Icons.sentiment_very_dissatisfied,
  Icons.sentiment_dissatisfied,
  Icons.sentiment_neutral,
  Icons.sentiment_satisfied,
  Icons.sentiment_very_satisfied,
];

IconData moodIcon(int rating) => moodIcons[(rating - 1).clamp(0, 4)];

/// Row of five faces; the selected one scales up and takes `secondaryContainer` (spec §9.8).
class MoodPicker extends StatelessWidget {
  const MoodPicker({super.key, required this.value, required this.onChanged});
  final int? value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var r = 1; r <= 5; r++)
          Flexible(
            child: Semantics(
              button: true,
              selected: value == r,
              label: 'Mood $r of 5${value == r ? ', selected' : ''}',
              excludeSemantics: true,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => onChanged(r),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 44, maxWidth: 56),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedScale(
                        scale: value == r ? 1.15 : 1,
                        duration: motionDuration(context),
                        child: AnimatedContainer(
                          duration: motionDuration(context),
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: value == r
                                ? cs.secondaryContainer
                                : Colors.transparent,
                          ),
                          child: Icon(
                            moodIcons[r - 1],
                            size: 30,
                            color: value == r
                                ? cs.onSecondaryContainer
                                : cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Text(
                        '$r',
                        style: tt.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class MoodCard extends ConsumerWidget {
  const MoodCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = dateOnly(DateTime.now());
    final feelings =
        ref.watch(feelingsProvider).asData?.value ?? const <Feeling>[];
    final todayEntry = feelings
        .where((f) => sameDay(f.date, today))
        .firstOrNull;
    return TonalCard(
      title: 'How are you today?',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MoodPicker(
            value: todayEntry?.rating,
            onChanged: (r) => ref.read(feelingsRepoProvider).upsert(today, r),
          ),
          const SizedBox(height: Space.xs),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => showMoodSheet(context, date: today),
              child: Text(
                todayEntry == null ? 'Add note or tags' : 'Edit note',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> showMoodSheet(BuildContext context, {required DateTime date}) =>
    showEntitySheet(context, builder: (_) => MoodSheet(date: date));

class MoodSheet extends ConsumerStatefulWidget {
  const MoodSheet({super.key, required this.date});
  final DateTime date;

  @override
  ConsumerState<MoodSheet> createState() => _MoodSheetState();
}

class _MoodSheetState extends ConsumerState<MoodSheet> {
  final _notes = TextEditingController();
  final _tags = TextEditingController();
  int? _rating;
  Feeling? _original;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await ref.read(feelingsRepoProvider).watchAll().first;
    final f = all.where((e) => sameDay(e.date, widget.date)).firstOrNull;
    if (f != null) {
      _original = f;
      _rating = f.rating;
      _notes.text = f.notes;
      _tags.text = f.tags;
    }
    if (mounted) setState(() => _loaded = true);
  }

  @override
  void dispose() {
    _notes.dispose();
    _tags.dispose();
    super.dispose();
  }

  bool get _dirty => _original == null
      ? (_rating != null || _notes.text.isNotEmpty || _tags.text.isNotEmpty)
      : (_rating != _original!.rating ||
            _notes.text != _original!.notes ||
            _tags.text != _original!.tags);

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const SizedBox(
        height: 160,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return EntitySheet(
      title: 'Mood',
      dirty: _dirty,
      valid: _rating != null,
      onSave: () => ref
          .read(feelingsRepoProvider)
          .upsert(widget.date, _rating!, notes: _notes.text, tags: _tags.text),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MoodPicker(
            value: _rating,
            onChanged: (r) => setState(() => _rating = r),
          ),
          const SizedBox(height: Space.lg),
          TextField(
            controller: _notes,
            minLines: 2,
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Notes'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: Space.md),
          TextField(
            controller: _tags,
            decoration: const InputDecoration(
              labelText: 'Tags',
              helperText: 'Comma separated',
            ),
            onChanged: (_) => setState(() {}),
          ),
          if (_tags.text.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: Space.sm),
              child: Wrap(
                spacing: Space.sm,
                children: [
                  for (final t in splitTags(normalizeTags(_tags.text)))
                    Chip(label: Text(t)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
