import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../design/motion.dart';
import '../design/tokens.dart';

class TabSpec {
  const TabSpec({required this.label, required this.builder});
  final String label;
  final WidgetBuilder builder;
}

/// Tabs that remember the last selected tab (local preference) and switch with
/// a horizontal shared-axis transition (spec §9.3).
class TabbedScreen extends ConsumerStatefulWidget {
  const TabbedScreen({super.key, required this.prefKey, required this.tabs, this.scrollable = false, this.onTabChanged});

  final String prefKey;
  final List<TabSpec> tabs;
  final bool scrollable;
  final ValueChanged<int>? onTabChanged;

  @override
  ConsumerState<TabbedScreen> createState() => _TabbedScreenState();
}

class _TabbedScreenState extends ConsumerState<TabbedScreen> {
  late int _index;
  bool _reverse = false;

  @override
  void initState() {
    super.initState();
    final saved = ref.read(prefsProvider).getString('tab_${widget.prefKey}');
    final i = widget.tabs.indexWhere((t) => t.label == saved);
    _index = i < 0 ? 0 : i;
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.onTabChanged?.call(_index));
  }

  void _select(int i) {
    if (i == _index) return;
    setState(() {
      _reverse = i < _index;
      _index = i;
    });
    ref.read(prefsProvider).setString('tab_${widget.prefKey}', widget.tabs[i].label);
    widget.onTabChanged?.call(i);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TabStrip(tabs: widget.tabs, index: _index, onSelect: _select, scrollable: widget.scrollable, color: cs.primary),
        Expanded(
          child: PageTransitionSwitcher(
            duration: motionDuration(context, Dur.medium),
            reverse: _reverse,
            transitionBuilder: (child, a, b) => SharedAxisTransition(
              animation: a,
              secondaryAnimation: b,
              transitionType: SharedAxisTransitionType.horizontal,
              fillColor: Colors.transparent,
              child: child,
            ),
            child: KeyedSubtree(key: ValueKey(_index), child: widget.tabs[_index].builder(context)),
          ),
        ),
      ],
    );
  }
}

class _TabStrip extends StatelessWidget {
  const _TabStrip({required this.tabs, required this.index, required this.onSelect, required this.scrollable, required this.color});
  final List<TabSpec> tabs;
  final int index;
  final ValueChanged<int> onSelect;
  final bool scrollable;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      key: ValueKey('${tabs.length}-$index'),
      length: tabs.length,
      initialIndex: index,
      child: TabBar(
        isScrollable: scrollable,
        tabAlignment: scrollable ? TabAlignment.start : null,
        onTap: onSelect,
        tabs: [for (final t in tabs) Tab(text: t.label)],
      ),
    );
  }
}
