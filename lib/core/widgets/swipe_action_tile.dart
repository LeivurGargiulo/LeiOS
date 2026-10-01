import 'package:flutter/material.dart';

import '../design/tokens.dart';

class TileMenuItem {
  const TileMenuItem({required this.label, required this.icon, required this.onTap, this.destructive = false});
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool destructive;
}

/// List item with swipe actions plus an overflow menu with the same actions
/// (accessible / desktop alternative, spec §9.7).
///
/// Swipe actions run and then spring back (`confirmDismiss` returns false); rows
/// leave the list when the reactive data stream no longer emits them.
class SwipeActionTile extends StatelessWidget {
  const SwipeActionTile({
    super.key,
    required this.child,
    this.onSwipeRight,
    this.rightIcon = Icons.check,
    this.onSwipeLeft,
    this.menuItems = const [],
    this.showMenu = true,
  });

  final Widget child;
  final VoidCallback? onSwipeRight;
  final IconData rightIcon;
  final VoidCallback? onSwipeLeft;
  final List<TileMenuItem> menuItems;
  final bool showMenu;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final directions = {
      if (onSwipeRight != null) DismissDirection.startToEnd,
      if (onSwipeLeft != null) DismissDirection.endToStart,
    };
    Widget row = Row(
      children: [
        Expanded(child: child),
        if (showMenu && menuItems.isNotEmpty)
          PopupMenuButton<int>(
            tooltip: 'More actions',
            icon: const Icon(Icons.more_vert),
            onSelected: (i) => menuItems[i].onTap(),
            itemBuilder: (_) => [
              for (var i = 0; i < menuItems.length; i++)
                PopupMenuItem(
                  value: i,
                  child: Row(
                    children: [
                      Icon(menuItems[i].icon, size: 20, color: menuItems[i].destructive ? cs.error : null),
                      const SizedBox(width: Space.md),
                      Text(menuItems[i].label, style: menuItems[i].destructive ? TextStyle(color: cs.error) : null),
                    ],
                  ),
                ),
            ],
          ),
      ],
    );
    if (directions.isEmpty) return row;
    return Dismissible(
      key: key ?? UniqueKey(),
      direction: directions.length == 2
          ? DismissDirection.horizontal
          : directions.first,
      background: Container(
        color: cs.primaryContainer,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: Space.xl),
        child: Icon(rightIcon, color: cs.onPrimaryContainer),
      ),
      secondaryBackground: Container(
        color: cs.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: Space.xl),
        child: Icon(Icons.delete_outline, color: cs.onErrorContainer),
      ),
      confirmDismiss: (dir) async {
        if (dir == DismissDirection.startToEnd) {
          onSwipeRight?.call();
        } else {
          onSwipeLeft?.call();
        }
        return false;
      },
      child: row,
    );
  }
}
