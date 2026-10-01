import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../design/breakpoints.dart';
import '../design/tokens.dart';
import 'empty_state.dart';

/// List pane + detail pane on expanded widths; list only otherwise (spec §9.4).
///
/// [selectedId] comes from the route (deep-linkable). When it no longer matches any
/// of [itemIds] (deleted here or from another device) [onSelectionCleared] fires.
class MasterDetailScaffold<T> extends StatefulWidget {
  const MasterDetailScaffold({
    super.key,
    required this.master,
    required this.detail,
    required this.itemIds,
    required this.selectedId,
    required this.onSelectionCleared,
    this.dataLoaded = true,
    this.onMoveSelection,
    this.onCreate,
    this.emptyTitle,
    this.emptyMessage,
  });

  final Widget master;

  /// Editor for the selected item, or null when nothing is selected.
  final Widget? detail;
  final List<String> itemIds;
  final String? selectedId;
  final VoidCallback onSelectionCleared;
  final bool dataLoaded;

  /// `↑/↓` moves the selection (desktop).
  final ValueChanged<int>? onMoveSelection;

  /// `Ctrl+N`.
  final VoidCallback? onCreate;
  final String? emptyTitle;
  final String? emptyMessage;

  @override
  State<MasterDetailScaffold<T>> createState() => _MasterDetailScaffoldState<T>();
}

class _MasterDetailScaffoldState<T> extends State<MasterDetailScaffold<T>> {
  void _checkSelection() {
    final id = widget.selectedId;
    if (id == null || id == 'new' || !widget.dataLoaded) return;
    if (!widget.itemIds.contains(id)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onSelectionCleared();
      });
    }
  }

  @override
  void didUpdateWidget(MasterDetailScaffold<T> old) {
    super.didUpdateWidget(old);
    _checkSelection();
  }

  @override
  void initState() {
    super.initState();
    _checkSelection();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final expanded = windowSizeFor(MediaQuery.sizeOf(context).width) == WindowSize.expanded;
      if (!expanded) return widget.master;
      final l = L10n.of(context);
      final cs = Theme.of(context).colorScheme;
      final w = masterPaneWidth(c.maxWidth);
      final shortcuts = <ShortcutActivator, VoidCallback>{
        if (widget.onMoveSelection != null) ...{
          const SingleActivator(LogicalKeyboardKey.arrowDown): () => widget.onMoveSelection!(1),
          const SingleActivator(LogicalKeyboardKey.arrowUp): () => widget.onMoveSelection!(-1),
        },
        if (widget.onCreate != null) const SingleActivator(LogicalKeyboardKey.keyN, control: true): widget.onCreate!,
        const SingleActivator(LogicalKeyboardKey.escape): widget.onSelectionCleared,
      };
      return CallbackShortcuts(
        bindings: shortcuts,
        child: Focus(
          autofocus: false,
          child: Row(
            children: [
              SizedBox(width: w, child: widget.master),
              VerticalDivider(width: 1, thickness: 1, color: cs.outlineVariant),
              Expanded(
                child: widget.detail ??
                    EmptyState(
                      icon: Icons.touch_app,
                      title: widget.emptyTitle ?? l.emptySelectionTitle,
                      message: widget.emptyMessage ?? l.emptySelectionMessage,
                      seed: 99,
                    ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

/// `+ New` filled-tonal button for list-pane headers (replaces the FAB on expanded).
class NewButton extends StatelessWidget {
  const NewButton({super.key, required this.onPressed, this.label});
  final VoidCallback onPressed;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: onPressed,
      icon: const Icon(Icons.add),
      label: Text(label ?? L10n.of(context).newItem),
    );
  }
}

const double kListBottomPadding = Layout.fabClearance;
