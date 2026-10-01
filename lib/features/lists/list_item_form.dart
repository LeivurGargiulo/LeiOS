import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/design/tokens.dart';
import '../../core/widgets/dialogs.dart';
import '../../core/widgets/draft.dart';
import '../../core/widgets/entity_editor.dart';
import '../../domain/models.dart';
import '../../l10n/app_localizations.dart';
import 'list_config.dart';

void openListItem(BuildContext context, ListConfig config, {String? id}) {
  if (MediaQuery.sizeOf(context).width >= 840) {
    context.go('/lists/${id ?? 'new'}');
  } else {
    showEntitySheet(context, builder: (_) => ListItemForm(config: config, itemId: id, presentation: EditorPresentation.sheet));
  }
}

class ListItemForm extends ConsumerStatefulWidget {
  const ListItemForm({super.key, required this.config, this.itemId, required this.presentation, this.onClosed});
  final ListConfig config;
  final String? itemId;
  final EditorPresentation presentation;
  final VoidCallback? onClosed;

  @override
  ConsumerState<ListItemForm> createState() => _ListItemFormState();
}

class _ListItemFormState extends ConsumerState<ListItemForm> with DraftFormMixin<ListItemForm> {
  final _title = TextEditingController();
  final _category = TextEditingController();
  final _notes = TextEditingController();
  final _url = TextEditingController();
  final _price = TextEditingController();
  ListItem? _original;
  bool _loaded = false;

  ListConfig get c => widget.config;

  @override
  String get draftKey => 'list:${c.kind.name}:${widget.itemId ?? 'new'}';
  @override
  bool get isDirtyDraft => _dirty;
  @override
  Map<String, Object?> snapshot() => {
        'title': _title.text,
        'category': _category.text,
        'notes': _notes.text,
        'url': _url.text,
        'price': _price.text,
      };
  @override
  void restore(Map<String, Object?> d) {
    _title.text = d['title'] as String? ?? '';
    _category.text = d['category'] as String? ?? '';
    _notes.text = d['notes'] as String? ?? '';
    _url.text = d['url'] as String? ?? '';
    _price.text = d['price'] as String? ?? '';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final id = widget.itemId;
    if (id != null) {
      final items = await ref.read(listItemsRepoProvider).watch(c.kind).first;
      final it = items.where((e) => e.id == id).firstOrNull;
      if (it != null) {
        _original = it;
        _title.text = it.title;
        _category.text = it.category;
        _notes.text = it.notes;
        _url.text = it.url;
        _price.text = it.price?.toString() ?? '';
      }
    }
    loadDraft();
    if (mounted) setState(() => _loaded = true);
  }

  @override
  void dispose() {
    for (final t in [_title, _category, _notes, _url, _price]) {
      t.dispose();
    }
    super.dispose();
  }

  bool get _dirty {
    final o = _original;
    if (o == null) return [_title, _category, _notes, _url, _price].any((t) => t.text.isNotEmpty);
    return _title.text != o.title ||
        _category.text != o.category ||
        _notes.text != o.notes ||
        _url.text != o.url ||
        _price.text != (o.price?.toString() ?? '');
  }

  Future<void> _save() async {
    final repo = ref.read(listItemsRepoProvider);
    final messenger = ScaffoldMessenger.of(context);
    final l = L10n.of(context);
    final price = int.tryParse(_price.text.trim());
    if (widget.itemId != null) {
      await repo.update(
        widget.itemId!,
        title: _title.text,
        category: _category.text,
        notes: _notes.text,
        url: _url.text,
        setPrice: c.hasPrice,
        price: price,
      );
    } else {
      final id = await repo.create(c.kind, title: _title.text, category: _category.text, notes: _notes.text, url: _url.text, price: price);
      showUndoSnackOn(messenger, l.entityAdded('Item'), undoLabel: l.undo, onUndo: () => repo.delete(c.kind, id));
    }
    discardDraft();
  }

  Future<void> _delete() async {
    final o = _original;
    if (o == null) return;
    final repo = ref.read(listItemsRepoProvider);
    final messenger = ScaffoldMessenger.of(context);
    final l = L10n.of(context);
    await repo.delete(c.kind, o.id);
    discardDraft();
    showUndoSnackOn(
      messenger,
      l.entityDeleted('Item'),
      undoLabel: l.undo,
      onUndo: () => repo.create(c.kind, id: o.id, title: o.title, category: o.category, notes: o.notes, url: o.url, price: o.price, done: o.done),
    );
    if (!mounted) return;
    if (widget.presentation == EditorPresentation.inline) {
      widget.onClosed?.call();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const SizedBox(height: 160, child: Center(child: CircularProgressIndicator()));
    final hasMore = c.hasNotes || c.hasUrl || c.hasPrice;
    final moreFields = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (c.hasNotes) ...[
          TextField(
            controller: _notes,
            minLines: 2,
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Notes'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: Space.md),
        ],
        if (c.hasUrl) ...[
          TextField(
            controller: _url,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(labelText: 'URL'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: Space.md),
        ],
        if (c.hasPrice)
          TextField(
            controller: _price,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(labelText: 'Price'),
            onChanged: (_) => setState(() {}),
          ),
      ],
    );
    return EntityEditor(
      presentation: widget.presentation,
      title: widget.itemId == null ? 'New ${c.tabLabel.toLowerCase()} item' : 'Edit item',
      dirty: _dirty,
      valid: _title.text.trim().isNotEmpty,
      onSave: _save,
      onDelete: widget.itemId == null ? null : _delete,
      onClosed: () {
        discardDraft();
        widget.onClosed?.call();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _title,
            autofocus: widget.presentation == EditorPresentation.sheet,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Title'),
            onChanged: (_) => setState(() {}),
          ),
          if (c.hasCategory) ...[
            const SizedBox(height: Space.md),
            TextField(
              controller: _category,
              decoration: InputDecoration(labelText: c.categoryLabel),
              onChanged: (_) => setState(() {}),
            ),
            if (c.categorySuggestions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: Space.sm),
                child: Wrap(spacing: Space.sm, children: [
                  for (final s in c.categorySuggestions)
                    ActionChip(label: Text(s), onPressed: () => setState(() => _category.text = s)),
                ]),
              ),
          ],
          if (hasMore) MoreDetails(initiallyOpen: _notes.text.isNotEmpty || _url.text.isNotEmpty || _price.text.isNotEmpty, child: moreFields),
        ],
      ),
    );
  }
}
