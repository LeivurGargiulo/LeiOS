import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/screen_scaffold.dart';
import '../../core/widgets/tabbed_screen.dart';
import '../../l10n/app_localizations.dart';
import 'list_config.dart';
import 'list_item_form.dart';
import 'list_items_view.dart';

class ListsScreen extends ConsumerStatefulWidget {
  const ListsScreen({super.key, this.selectedId});
  final String? selectedId;

  @override
  ConsumerState<ListsScreen> createState() => _ListsScreenState();
}

class _ListsScreenState extends ConsumerState<ListsScreen> {
  int _tab = 0;
  bool _reorder = false;

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final config = listConfigs[_tab];
    return ScreenScaffold(
      title: l.navLists,
      actions: [
        IconButton(
          tooltip: _reorder ? l.listDoneReordering : l.listReorder,
          isSelected: _reorder,
          icon: const Icon(Icons.swap_vert),
          selectedIcon: const Icon(Icons.check),
          onPressed: () => setState(() => _reorder = !_reorder),
        ),
      ],
      fab: FabSpec(tooltip: l.listAddItemTooltip(config.tabLabel(l).toLowerCase()), onPressed: () => openListItem(context, config)),
      body: TabbedScreen(
        prefKey: 'lists',
        scrollable: true,
        onTabChanged: (i) {
          if (i != _tab) setState(() => _tab = i);
        },
        tabs: [
          for (final c in listConfigs)
            TabSpec(
              label: c.tabLabel(l),
              builder: (_) => ListItemsView(config: c, selectedId: widget.selectedId, reorderMode: _reorder),
            ),
        ],
      ),
    );
  }
}
