/// Pure planning for `sort_order` groups (spec Appendix A, "Reordering").
/// Each function returns the list of `(id, newSortOrder)` updates to apply.
library;

typedef OrderUpdate = ({String id, int sortOrder});

/// New items append: `sort_order = group size`.
int appendOrder(int groupLength) => groupLength;

/// Swap with the neighbour. Out of range or unknown id → no updates.
List<OrderUpdate> planMove(List<String> orderedIds, String id, int dir) {
  final i = orderedIds.indexOf(id);
  final j = i + dir;
  if (i < 0 || j < 0 || j >= orderedIds.length) return const [];
  return [(id: orderedIds[i], sortOrder: j), (id: orderedIds[j], sortOrder: i)];
}

/// After deleting [id], renumber the remaining items 0..n-1 (only changed rows).
List<OrderUpdate> planRenumberAfterDelete(List<String> orderedIds, String id) {
  final rest = orderedIds.where((e) => e != id).toList();
  final before = orderedIds.indexOf(id);
  return [
    for (var i = 0; i < rest.length; i++)
      if (before < 0 || i >= before) (id: rest[i], sortOrder: i),
  ];
}

/// Full renumber of an arbitrary reorder (drag & drop): move [oldIndex] to [newIndex].
List<OrderUpdate> planReorder(List<String> orderedIds, int oldIndex, int newIndex) {
  final ids = [...orderedIds];
  final moved = ids.removeAt(oldIndex);
  ids.insert(newIndex, moved);
  return [
    for (var i = 0; i < ids.length; i++)
      if (ids[i] != orderedIds[i]) (id: ids[i], sortOrder: i),
  ];
}
