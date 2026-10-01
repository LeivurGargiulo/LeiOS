import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/design/motion.dart';
import '../../core/design/tokens.dart';
import '../../core/widgets/dialogs.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/entity_editor.dart';
import '../../core/widgets/small_widgets.dart';
import '../../domain/dates.dart';
import '../../domain/models.dart';
import '../../domain/streak.dart';
import '../../l10n/app_localizations.dart';

Set<DateTime> datesFor(String habitId, List<HabitCompletion> all) =>
    {for (final c in all) if (c.habitId == habitId) dateOnly(c.date)};

/// Streak counter that slides/fades when its number changes, with a flame that pulses.
class StreakChip extends StatelessWidget {
  const StreakChip({super.key, required this.streak});
  final int streak;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Semantics(
      label: '$streak day streak',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Space.sm, vertical: Space.xs),
        decoration: BoxDecoration(color: cs.tertiaryContainer, borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              key: ValueKey(streak),
              tween: Tween(begin: reduceMotion(context) ? 1 : 1.2, end: 1),
              duration: motionDuration(context),
              builder: (_, v, child) => Transform.scale(scale: v, child: child),
              child: Icon(Icons.local_fire_department, size: 16, color: cs.tertiary),
            ),
            const SizedBox(width: 2),
            AnimatedSwitcher(
              duration: motionDuration(context),
              transitionBuilder: (child, a) => FadeTransition(
                opacity: a,
                child: SlideTransition(position: Tween(begin: const Offset(0, 0.5), end: Offset.zero).animate(a), child: child),
              ),
              child: Text('$streak', key: ValueKey(streak), style: moneyStyle(tt.labelLarge?.copyWith(color: cs.onTertiaryContainer))),
            ),
          ],
        ),
      ),
    );
  }
}

class HabitsCard extends ConsumerWidget {
  const HabitsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L10n.of(context);
    final habits = ref.watch(habitsProvider).asData?.value ?? const <Habit>[];
    final completions = ref.watch(completionsProvider).asData?.value ?? const <HabitCompletion>[];
    final today = dateOnly(DateTime.now());
    return TonalCard(
      title: 'Today',
      action: TextButton(onPressed: () => showManageHabits(context), child: const Text('Manage')),
      child: habits.isEmpty
          ? EmptyState(
              icon: Icons.self_improvement,
              title: l.emptyHabitsTitle,
              message: l.emptyHabitsMessage,
              actionLabel: l.emptyHabitsAction,
              onAction: () => showEntitySheet(context, builder: (_) => const HabitFormSheet()),
              seed: 3,
              compact: true,
            )
          : Column(
              children: [
                for (final h in habits)
                  _HabitRow(habit: h, dates: datesFor(h.id, completions), today: today),
              ],
            ),
    );
  }
}

class _HabitRow extends ConsumerWidget {
  const _HabitRow({required this.habit, required this.dates, required this.today});
  final Habit habit;
  final Set<DateTime> dates;
  final DateTime today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final done = dates.contains(today);
    final count = weeklyCount(dates, today);
    void toggle() => ref.read(habitsRepoProvider).toggle(habit.id, today);
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: toggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Space.xs),
        child: Row(
          children: [
            StatusCircle(
              state: done ? 2 : 0,
              size: 32,
              onTap: toggle,
              semanticLabel: '${habit.name}, ${done ? 'completed' : 'not completed'} today',
            ),
            const SizedBox(width: Space.sm),
            Expanded(child: Text(habit.name, style: tt.bodyLarge)),
            StreakChip(streak: streak(dates, today)),
            const SizedBox(width: Space.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: Space.sm, vertical: Space.xs),
              decoration: BoxDecoration(border: Border.all(color: cs.outlineVariant), borderRadius: BorderRadius.circular(8)),
              child: Text('$count/${habit.targetFrequency}', style: moneyStyle(tt.labelLarge)),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showManageHabits(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: Layout.maxSheetWidth),
      builder: (_) => const _ManageHabitsSheet(),
    );

class _ManageHabitsSheet extends ConsumerWidget {
  const _ManageHabitsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(habitsProvider).asData?.value ?? const <Habit>[];
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.9),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.xl),
            child: Row(
              children: [
                Expanded(child: Text('Habits', style: Theme.of(context).textTheme.titleLarge)),
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add habit'),
                  onPressed: () => showEntitySheet(context, builder: (_) => const HabitFormSheet()),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final h in habits)
                  ListTile(
                    title: Text(h.name),
                    subtitle: Text('Target ${h.targetFrequency} / week'),
                    onTap: () => showEntitySheet(context, builder: (_) => HabitFormSheet(habit: h)),
                    trailing: IconButton(
                      tooltip: 'Delete ${h.name}',
                      icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                      onPressed: () async {
                        final ok = await confirmDelete(
                          context,
                          title: 'Delete habit?',
                          body: 'This also deletes all completions of "${h.name}".',
                        );
                        if (ok) await ref.read(habitsRepoProvider).delete(h.id);
                      },
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: Space.lg),
        ],
      ),
    );
  }
}

class HabitFormSheet extends ConsumerStatefulWidget {
  const HabitFormSheet({super.key, this.habit});
  final Habit? habit;

  @override
  ConsumerState<HabitFormSheet> createState() => _HabitFormSheetState();
}

class _HabitFormSheetState extends ConsumerState<HabitFormSheet> {
  late final _name = TextEditingController(text: widget.habit?.name ?? '');
  late int _target = widget.habit?.targetFrequency ?? 7;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.habit;
    return EntitySheet(
      title: h == null ? 'New habit' : 'Edit habit',
      dirty: h == null ? (_name.text.isNotEmpty || _target != 7) : (_name.text != h.name || _target != h.targetFrequency),
      valid: _name.text.trim().isNotEmpty,
      onSave: () async {
        final repo = ref.read(habitsRepoProvider);
        if (h == null) {
          await repo.create(name: _name.text, targetFrequency: _target);
        } else {
          await repo.update(h.id, name: _name.text, targetFrequency: _target);
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _name,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Name'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: Space.lg),
          Text('Target per week: $_target', style: Theme.of(context).textTheme.labelLarge),
          Slider(
            value: _target.toDouble(),
            min: 1,
            max: 7,
            divisions: 6,
            label: '$_target',
            onChanged: (v) => setState(() => _target = v.round()),
          ),
        ],
      ),
    );
  }
}
