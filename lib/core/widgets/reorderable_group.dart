import 'package:flutter/material.dart';

/// Reorderable list with a drag handle AND move up/down buttons (spec §2.1).
class ReorderableGroup<T> extends StatelessWidget {
  const ReorderableGroup({
    super.key,
    required this.items,
    required this.idOf,
    required this.itemBuilder,
    required this.onReorder,
    required this.onMove,
    this.shrinkWrap = true,
  });

  final List<T> items;
  final String Function(T) idOf;
  final Widget Function(BuildContext, T) itemBuilder;
  final void Function(int oldIndex, int newIndex) onReorder;
  final void Function(T item, int dir) onMove;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      buildDefaultDragHandles: false,
      itemCount: items.length,
      onReorderItem: onReorder,
      itemBuilder: (context, i) {
        final item = items[i];
        return Row(
          key: ValueKey(idOf(item)),
          children: [
            ReorderableDragStartListener(
              index: i,
              child: const SizedBox(width: 48, height: 48, child: Icon(Icons.drag_handle)),
            ),
            Expanded(child: itemBuilder(context, item)),
            IconButton(
              tooltip: 'Move up',
              icon: const Icon(Icons.arrow_upward, size: 20),
              onPressed: i == 0 ? null : () => onMove(item, -1),
            ),
            IconButton(
              tooltip: 'Move down',
              icon: const Icon(Icons.arrow_downward, size: 20),
              onPressed: i == items.length - 1 ? null : () => onMove(item, 1),
            ),
          ],
        );
      },
    );
  }
}
