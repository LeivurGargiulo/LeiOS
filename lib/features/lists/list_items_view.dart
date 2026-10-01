import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/providers.dart';
import '../../core/design/breakpoints.dart';
import '../../core/design/motion.dart';
import '../../core/design/tokens.dart';
import '../../core/widgets/dialogs.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/entity_editor.dart';
import '../../core/widgets/filter_bar.dart';
import '../../core/widgets/format.dart';
import '../../core/widgets/master_detail_scaffold.dart';
import '../../core/widgets/reorderable_group.dart';
import '../../core/widgets/small_widgets.dart';
import '../../core/widgets/swipe_action_tile.dart';
import '../../domain/models.dart';
import '../../l10n/app_localizations.dart';
import 'list_config.dart';
import 'list_item_form.dart';

enum _ItemFilter { pending, done, all }

/// One implementation that powers all four Lists tabs (spec §2.2).
class ListItemsView extends ConsumerStatefulWidget {
  const ListItemsView({super.key, required this.config, this.selectedId, this.reorderMode = false});
  final ListConfig config;
  final String? selectedId;
  final bool reorderMode;

  @override
  ConsumerState<ListItemsView> createState() => _ListItemsViewState();
}

class _ListItemsViewState extends ConsumerState<ListItemsView> {
  _ItemFilter _filter = _ItemFilter.pending;
  String? _category;

  ListConfig get c => widget.config;

  String _filterLabel(_ItemFilter f) => switch (f) {
        _ItemFilter.pending => 'Pending',
        _ItemFilter.done => c.doneLabel,
        _ItemFilter.all => 'All',
      };

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final async = ref.watch(listItemsProvider(c.kind));
    final items = async.asData?.value ?? const <ListItem>[];
    final categories = {for (final i in items) if (i.category.trim().isNotEmpty) i.category}.toList()..sort();
    final shown = items.where((i) {
      final okFilter = switch (_filter) {
        _ItemFilter.pending => !i.done,
        _ItemFilter.done => i.done,
        _ItemFilter.all => true,
      };
      return okFilter && (_category == null || i.category == _category);
    }).toList();
    final selectedId = widget.selectedId;
    final pendingTotal = items.where((i) => !i.done).fold<int>(0, (a, i) => a + (i.price ?? 0));

    final master = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: ChipFilterRow<_ItemFilter>(
                values: _ItemFilter.values,
                selected: _filter,
                labelOf: _filterLabel,
                onSelected: (f) => setState(() => _filter = f),
              ),
            ),
            if (c.hasCategory && categories.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: Space.sm),
                child: PopupMenuButton<String?>(
                  tooltip: 'Filter by ${c.categoryLabel!.toLowerCase()}',
                  icon: Icon(_category == null ? Icons.filter_list : Icons.filter_alt),
                  initialValue: _category,
                  onSelected: (v) => setState(() => _category = v),
                  itemBuilder: (_) => [
                    const PopupMenuItem<String?>(value: null, child: Text('All')),
                    for (final cat in categories) PopupMenuItem<String?>(value: cat, child: Text(cat)),
                  ],
                ),
              ),
            if (context.isExpanded) Padding(padding: const EdgeInsets.only(right: Space.sm), child: NewButton(onPressed: () => context.go('/lists/new'))),
          ],
        ),
        Expanded(
          child: async.isLoading && !async.hasValue
              ? const Center(child: CircularProgressIndicator())
              : items.isEmpty
                  ? EmptyState(
                      icon: c.emptyIcon,
                      title: c.emptyTitle(l),
                      message: c.emptyMessage(l),
                      actionLabel: c.emptyAction(l),
                      onAction: () => openListItem(context, c),
                      seed: 10 + c.kind.index,
                    )
                  : widget.reorderMode
                      ? ReorderableGroup<ListItem>(
                          shrinkWrap: false,
                          items: items,
                          idOf: (i) => i.id,
                          itemBuilder: (_, i) => _ItemTile(config: c, item: i, selected: i.id == selectedId),
                          onReorder: (o, n) => ref.read(listItemsRepoProvider).reorder(c.kind, o, n),
                          onMove: (i, dir) => ref.read(listItemsRepoProvider).move(c.kind, i.id, dir),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.only(bottom: kListBottomPadding),
                          itemCount: shown.length,
                          separatorBuilder: (_, _) => const Divider(indent: 72),
                          itemBuilder: (context, i) => _ItemTile(config: c, item: shown[i], selected: shown[i].id == selectedId),
                        ),
        ),
        if (c.hasPrice)
          Material(
            color: Theme.of(context).colorScheme.surfaceContainer,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.md),
              child: Row(children: [
                Text('Pending total', style: Theme.of(context).textTheme.labelLarge),
                const Spacer(),
                Text(formatMoney(pendingTotal), style: moneyStyle(Theme.of(context).textTheme.titleMedium)),
              ]),
            ),
          ),
      ],
    );

    return MasterDetailScaffold<ListItem>(
      master: master,
      detail: selectedId == null
          ? null
          : ListItemForm(
              key: ValueKey('list-form-${c.kind.name}-$selectedId'),
              config: c,
              itemId: selectedId == 'new' ? null : selectedId,
              presentation: EditorPresentation.inline,
              onClosed: () => context.go('/lists'),
            ),
      itemIds: [for (final i in items) i.id],
      selectedId: selectedId,
      dataLoaded: async.hasValue,
      onSelectionCleared: () => context.go('/lists'),
      onCreate: () => context.go('/lists/new'),
      onMoveSelection: (dir) {
        if (shown.isEmpty) return;
        final i = shown.indexWhere((e) => e.id == selectedId);
        context.go('/lists/${shown[(i + dir).clamp(0, shown.length - 1)].id}');
      },
    );
  }
}

class _ItemTile extends ConsumerWidget {
  const _ItemTile({required this.config, required this.item, required this.selected});
  final ListConfig config;
  final ListItem item;
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final repo = ref.read(listItemsRepoProvider);
    final messenger = ScaffoldMessenger.of(context);
    final l = L10n.of(context);

    Future<void> delete() async {
      final o = item;
      await repo.delete(config.kind, o.id);
      showUndoSnackOn(
        messenger,
        l.entityDeleted('Item'),
        undoLabel: l.undo,
        onUndo: () => repo.create(config.kind, id: o.id, title: o.title, category: o.category, notes: o.notes, url: o.url, price: o.price, done: o.done),
      );
    }

    final subtitleBits = <Widget>[
      if (item.category.isNotEmpty) Chip(label: Text(item.category), visualDensity: VisualDensity.compact),
      if (item.notes.isNotEmpty) Text(item.notes, maxLines: 1, overflow: TextOverflow.ellipsis, style: tt.bodySmall),
    ];

    return SwipeActionTile(
      key: ValueKey('li-${item.id}'),
      onSwipeLeft: delete,
      menuItems: [
        TileMenuItem(label: item.done ? 'Mark pending' : 'Mark ${config.doneLabel.toLowerCase()}', icon: Icons.check, onTap: () => repo.update(item.id, done: !item.done)),
        TileMenuItem(label: 'Move up', icon: Icons.arrow_upward, onTap: () => repo.move(config.kind, item.id, -1)),
        TileMenuItem(label: 'Move down', icon: Icons.arrow_downward, onTap: () => repo.move(config.kind, item.id, 1)),
        TileMenuItem(label: 'Delete', icon: Icons.delete_outline, destructive: true, onTap: delete),
      ],
      child: ListTile(
        selected: selected,
        selectedTileColor: cs.secondaryContainer,
        contentPadding: const EdgeInsets.only(left: Space.xs),
        leading: StatusCircle(
          state: item.done ? 2 : 0,
          semanticLabel: '${config.doneLabel}: ${item.done ? 'yes' : 'no'}',
          onTap: () => repo.update(item.id, done: !item.done),
        ),
        title: AnimatedDefaultTextStyle(
          duration: motionDuration(context),
          style: (tt.bodyLarge ?? const TextStyle()).copyWith(
            decoration: item.done ? TextDecoration.lineThrough : TextDecoration.none,
            color: item.done ? cs.onSurfaceVariant : cs.onSurface,
          ),
          child: Text(item.title),
        ),
        subtitle: subtitleBits.isEmpty ? null : Wrap(spacing: Space.sm, crossAxisAlignment: WrapCrossAlignment.center, children: subtitleBits),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          if (config.hasPrice && item.price != null) Text(formatMoney(item.price!), style: moneyStyle(tt.bodyMedium)),
          if (item.url.isNotEmpty)
            IconButton(
              tooltip: 'Open link',
              icon: const Icon(Icons.link),
              onPressed: () {
                final uri = Uri.tryParse(item.url.contains('://') ? item.url : 'https://${item.url}');
                if (uri != null) launchUrl(uri);
              },
            ),
        ]),
        onTap: () => context.isExpanded ? context.go('/lists/${item.id}') : openListItem(context, config, id: item.id),
      ),
    );
  }
}
