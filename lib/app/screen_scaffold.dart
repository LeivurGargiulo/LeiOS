import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../core/design/breakpoints.dart';
import '../core/design/motion.dart';
import '../core/design/tokens.dart';
import '../core/widgets/sync_status_chip.dart';
import 'quick_add.dart';

class FabSpec {
  const FabSpec({required this.onPressed, this.icon = Icons.add, required this.tooltip});
  final VoidCallback onPressed;
  final IconData icon;
  final String tooltip;
}

/// Per-screen scaffold: AppBar (title, actions, compact sync chip) and the contextual FAB
/// (spec §9.6). The FAB hides on expanded widths, hides while scrolling down, and
/// long-press opens the global quick-add chooser.
class ScreenScaffold extends StatefulWidget {
  const ScreenScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions = const [],
    this.fab,
    this.bottom,
    this.showAppBar = true,
  });

  final String title;
  final Widget body;
  final List<Widget> actions;
  final FabSpec? fab;
  final PreferredSizeWidget? bottom;
  final bool showAppBar;

  @override
  State<ScreenScaffold> createState() => _ScreenScaffoldState();
}

class _ScreenScaffoldState extends State<ScreenScaffold> {
  bool _fabVisible = true;

  bool _onScroll(UserScrollNotification n) {
    if (n.metrics.axis != Axis.vertical) return false;
    final visible = switch (n.direction) {
      ScrollDirection.reverse => false,
      ScrollDirection.forward => true,
      ScrollDirection.idle => _fabVisible,
    };
    if (visible != _fabVisible) setState(() => _fabVisible = visible);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final compact = context.isCompact;
    final expanded = context.isExpanded;
    final fab = widget.fab;
    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: Text(widget.title),
              bottom: widget.bottom,
              actions: [
                ...widget.actions,
                if (compact) const SyncStatusChip(),
                const SizedBox(width: Space.xs),
              ],
            )
          : null,
      body: NotificationListener<UserScrollNotification>(onNotification: _onScroll, child: widget.body),
      floatingActionButton: (fab == null || expanded)
          ? null
          : AnimatedSlide(
              duration: motionDuration(context),
              curve: Ease.inPlace,
              offset: _fabVisible ? Offset.zero : const Offset(0, 2),
              // No Tooltip here: its own long-press recognizer would win the gesture arena
              // over the quick-add long-press. The label lives in Semantics instead.
              child: Semantics(
                button: true,
                label: '${fab.tooltip}. Long-press for quick add.',
                onLongPress: () => showQuickAdd(context),
                excludeSemantics: true,
                child: GestureDetector(
                  onLongPress: () => showQuickAdd(context),
                  // Every branch keeps its own FAB alive, so a shared Hero tag would clash.
                  child: FloatingActionButton(
                    heroTag: null,
                    onPressed: fab.onPressed,
                    child: Icon(fab.icon),
                  ),
                ),
              ),
            ),
    );
  }
}

/// Content constrained to a readable column on medium+ widths.
class ColumnBody extends StatelessWidget {
  const ColumnBody({super.key, required this.child, this.maxWidth = Layout.maxContentWidth});
  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    if (context.isCompact) return child;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth), child: child),
    );
  }
}
