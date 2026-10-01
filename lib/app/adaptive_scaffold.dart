import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../core/design/breakpoints.dart';
import '../core/design/motion.dart';
import '../core/design/tokens.dart';
import '../core/widgets/sync_status_chip.dart';
import '../l10n/app_localizations.dart';
import 'quick_add.dart';

class Destination {
  const Destination(this.icon, this.selectedIcon, this.label);
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

List<Destination> destinations(L10n l) => [
      Destination(Icons.today_outlined, Icons.today, l.navToday),
      Destination(Icons.task_alt_outlined, Icons.task_alt, l.navTasks),
      Destination(Icons.calendar_month_outlined, Icons.calendar_month, l.navCalendar),
      Destination(Icons.flag_outlined, Icons.flag, l.navGoals),
      Destination(Icons.edit_note_outlined, Icons.edit_note, l.navNotes),
      Destination(Icons.checklist_outlined, Icons.checklist, l.navLists),
      Destination(Icons.account_balance_wallet_outlined, Icons.account_balance_wallet, l.navFinances),
      Destination(Icons.settings_outlined, Icons.settings, l.navSettings),
    ];

/// Navigation shell: bottom bar (compact) or rail (medium/expanded) (spec §9.3).
class AdaptiveScaffold extends StatelessWidget {
  const AdaptiveScaffold({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final dests = destinations(l);
    final size = context.windowSize;
    final index = shell.currentIndex;

    void go(int i) => shell.goBranch(i, initialLocation: i == index);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): () => showQuickAdd(context),
      },
      child: Focus(
        autofocus: true,
        child: size == WindowSize.compact
            ? Scaffold(
                body: shell,
                bottomNavigationBar: NavigationBar(
                  selectedIndex: index < 4 ? index : 4,
                  onDestinationSelected: (i) {
                    if (i < 4) {
                      go(i);
                    } else {
                      _showMore(context, dests, go, index);
                    }
                  },
                  destinations: [
                    for (var i = 0; i < 4; i++) NavigationDestination(icon: Icon(dests[i].icon), selectedIcon: Icon(dests[i].selectedIcon), label: dests[i].label),
                    NavigationDestination(icon: const Icon(Icons.more_horiz), selectedIcon: const Icon(Icons.more_horiz), label: l.navMore),
                  ],
                ),
              )
            : Scaffold(
                body: Row(
                  children: [
                    SafeArea(
                      child: NavigationRail(
                        selectedIndex: index,
                        extended: size == WindowSize.expanded,
                        labelType: size == WindowSize.expanded ? NavigationRailLabelType.none : NavigationRailLabelType.all,
                        onDestinationSelected: go,
                        trailing: const Expanded(
                          child: Align(alignment: Alignment.bottomCenter, child: Padding(padding: EdgeInsets.all(Space.md), child: _RailSync())),
                        ),
                        destinations: [
                          for (final d in dests) NavigationRailDestination(icon: Icon(d.icon), selectedIcon: Icon(d.selectedIcon), label: Text(d.label)),
                        ],
                      ),
                    ),
                    VerticalDivider(width: 1, thickness: 1, color: Theme.of(context).colorScheme.outlineVariant),
                    Expanded(child: shell),
                  ],
                ),
              ),
      ),
    );
  }

  void _showMore(BuildContext context, List<Destination> dests, void Function(int) go, int current) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 4; i < dests.length; i++)
            ListTile(
              leading: Icon(i == current ? dests[i].selectedIcon : dests[i].icon),
              title: Text(dests[i].label),
              selected: i == current,
              onTap: () {
                Navigator.pop(ctx);
                go(i);
              },
            ),
          const SizedBox(height: Space.md),
        ],
      ),
    );
  }
}

class _RailSync extends StatelessWidget {
  const _RailSync();
  @override
  Widget build(BuildContext context) => const SyncStatusChip(compact: false);
}

/// Branch container giving destination switches a fade-through (spec §9.3), while keeping every
/// branch alive (each destination keeps its own scroll position and tab).
class FadeThroughBranches extends StatelessWidget {
  const FadeThroughBranches({super.key, required this.index, required this.children});
  final int index;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final d = motionDuration(context, Dur.medium);
    return Stack(
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < children.length; i++)
          Positioned.fill(
            child: IgnorePointer(
              ignoring: i != index,
              child: ExcludeSemantics(
                excluding: i != index,
                child: TickerMode(
                  enabled: i == index,
                  child: AnimatedOpacity(
                    opacity: i == index ? 1 : 0,
                    duration: d,
                    curve: i == index ? Ease.enter : Ease.exit,
                    child: AnimatedScale(
                      scale: i == index ? 1 : 0.96,
                      duration: d,
                      curve: Ease.inPlace,
                      child: children[i],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
