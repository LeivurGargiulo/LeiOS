import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/quick_add.dart';
import '../../app/screen_scaffold.dart';
import '../../core/design/breakpoints.dart';
import '../../core/design/tokens.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/format.dart';
import '../../core/widgets/small_widgets.dart';
import '../../core/widgets/tabbed_screen.dart';
import '../../domain/dates.dart';
import '../../domain/models.dart';
import '../../domain/tasks.dart';
import '../../l10n/app_localizations.dart';
import '../tasks/task_form.dart';
import '../tasks/task_tile.dart';
import 'habits_ui.dart';
import 'mood_ui.dart';
import 'review_tab.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    return ScreenScaffold(
      title: l.navToday,
      fab: FabSpec(tooltip: l.quickAddTitle, onPressed: () => showQuickAdd(context)),
      body: TabbedScreen(
        prefKey: 'today',
        tabs: [
          TabSpec(label: l.tabCheckIn, builder: (_) => const _CheckIn()),
          TabSpec(label: l.tabReview, builder: (_) => const ReviewTab()),
        ],
      ),
    );
  }
}

/// Cards laid out single-column (compact/medium) or as a 2-column grid (expanded).
class CardColumns extends StatelessWidget {
  const CardColumns({super.key, required this.children, this.header});
  final List<Widget> children;
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    final gutter = context.gutter;
    final pad = EdgeInsets.fromLTRB(gutter, Space.sm, gutter, kListBottomPaddingToday);
    if (context.isExpanded) {
      final left = <Widget>[], right = <Widget>[];
      for (var i = 0; i < children.length; i++) {
        (i.isEven ? left : right).add(children[i]);
      }
      Widget col(List<Widget> c) => Expanded(child: Column(children: _gap(c)));
      return SingleChildScrollView(
        padding: pad,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ?header,
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [col(left), const SizedBox(width: Space.md), col(right)]),
          ],
        ),
      );
    }
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Layout.maxContentWidth),
        child: ListView(padding: pad, children: [?header, ..._gap(children)]),
      ),
    );
  }

  List<Widget> _gap(List<Widget> c) => [
        for (var i = 0; i < c.length; i++) ...[if (i > 0) const SizedBox(height: Space.md), c[i]],
      ];
}

const double kListBottomPaddingToday = Layout.fabClearance;

class _CheckIn extends ConsumerWidget {
  const _CheckIn();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L10n.of(context);
    final name = ref.watch(displayNameProvider);
    final now = DateTime.now();
    final greeting = greetingFor(now.hour);
    final tasks = ref.watch(tasksProvider).asData?.value ?? const <Task>[];
    final today = dateOnly(now);
    final doing = tasks.where((t) => t.status == TaskStatus.doing && !t.longTerm).toList();
    final due = tasks.where((t) => t.status != TaskStatus.done && !t.longTerm && t.dueDate != null).toList();
    final buckets = bucketTasks(due, today);

    return CardColumns(
      header: Padding(
        padding: const EdgeInsets.only(bottom: Space.lg, top: Space.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name.isEmpty ? '$greeting!' : '$greeting, $name!', style: Theme.of(context).textTheme.headlineSmall),
            Text(longDate(now), style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
      children: [
        const HabitsCard(),
        const MoodCard(),
        if (doing.isNotEmpty)
          TonalCard(
            title: l.statusDoing,
            child: Column(children: [for (final t in doing) TaskTile(task: t, swipe: false, onTap: () => openTask(context, id: t.id))]),
          ),
        _DueSoonCard(buckets: buckets),
      ],
    );
  }
}

class _DueSoonCard extends StatelessWidget {
  const _DueSoonCard({required this.buckets});
  final Map<TaskBucket, List<Task>> buckets;

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final cs = Theme.of(context).colorScheme;
    final overdue = buckets[TaskBucket.overdue]!;
    final soon = [...buckets[TaskBucket.today]!, ...buckets[TaskBucket.next7]!];
    return TonalCard(
      title: l.todayDueSoon,
      child: (overdue.isEmpty && soon.isEmpty)
          ? EmptyState(icon: Icons.wb_sunny, title: l.emptyCaughtUpTitle, message: l.emptyCaughtUpMessage, seed: 4, compact: true)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (overdue.isNotEmpty) ...[
                  SectionHeader(l.sectionCount(l.overdue, overdue.length), color: cs.error, padding: const EdgeInsets.only(bottom: Space.xs)),
                  for (final t in overdue) TaskTile(task: t, swipe: false, onTap: () => openTask(context, id: t.id)),
                ],
                if (soon.isNotEmpty) ...[
                  SectionHeader(l.next7Days, padding: const EdgeInsets.only(top: Space.sm, bottom: Space.xs)),
                  for (final t in soon) TaskTile(task: t, swipe: false, onTap: () => openTask(context, id: t.id)),
                ],
              ],
            ),
    );
  }
}
