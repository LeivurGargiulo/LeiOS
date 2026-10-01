import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/screen_scaffold.dart';
import '../../core/design/breakpoints.dart';
import '../../core/design/tokens.dart';
import '../../core/widgets/dialogs.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/entity_editor.dart';
import '../../core/widgets/format.dart';
import '../../core/widgets/master_detail_scaffold.dart';
import '../../core/widgets/swipe_action_tile.dart';
import '../../domain/models.dart';
import '../../domain/tags.dart';
import '../../l10n/app_localizations.dart';
import 'note_form.dart';

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key, this.selectedId});
  final String? selectedId;

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  String _query = '';
  String _tag = '';

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final async = ref.watch(notesProvider);
    final notes = async.asData?.value ?? const <Note>[];
    final selectedId = widget.selectedId;
    final allTags = <String, String>{};
    for (final n in notes) {
      for (final t in splitTags(n.tags)) {
        allTags.putIfAbsent(t.toLowerCase(), () => t);
      }
    }
    final filtered = notes
        .where((n) => matchesSearch(title: n.title, content: n.content, query: _query) && matchesTagFilter(n.tags, _tag))
        .toList();

    final master = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.lg, Space.sm, Space.lg, Space.xs),
          child: Row(children: [
            Expanded(
              child: SearchBar(
                hintText: l.noteSearch,
                leading: const Icon(Icons.search),
                elevation: const WidgetStatePropertyAll(0),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            if (context.isExpanded) ...[const SizedBox(width: Space.sm), NewButton(onPressed: () => context.go('/notes/new'), label: l.noteNew)],
          ]),
        ),
        if (allTags.isNotEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: Space.lg),
            child: Row(children: [
              for (final t in allTags.values)
                Padding(
                  padding: const EdgeInsets.only(right: Space.sm),
                  child: FilterChip(
                    label: Text(t),
                    selected: _tag.toLowerCase() == t.toLowerCase(),
                    onSelected: (s) => setState(() => _tag = s ? t : ''),
                  ),
                ),
            ]),
          ),
        Expanded(
          child: async.isLoading && !async.hasValue
              ? const Center(child: CircularProgressIndicator())
              : notes.isEmpty
                  ? EmptyState(icon: Icons.edit_note, title: l.emptyNotesTitle, message: l.emptyNotesMessage, actionLabel: l.emptyNotesAction, onAction: () => openNote(context), seed: 7)
                  : filtered.isEmpty
                      ? EmptyState(icon: Icons.search_off, title: l.emptySearchTitle, message: l.emptySearchMessage, seed: 8)
                      : ListView.separated(
                          padding: const EdgeInsets.only(bottom: kListBottomPadding),
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) => const Divider(indent: Space.lg),
                          itemBuilder: (context, i) => _NoteTile(note: filtered[i], selected: filtered[i].id == selectedId),
                        ),
        ),
      ],
    );

    return ScreenScaffold(
      title: l.navNotes,
      fab: FabSpec(tooltip: l.emptyNotesAction, onPressed: () => openNote(context)),
      body: MasterDetailScaffold<Note>(
        master: master,
        detail: selectedId == null
            ? null
            : NoteForm(
                key: ValueKey('note-form-$selectedId'),
                noteId: selectedId == 'new' ? null : selectedId,
                presentation: EditorPresentation.inline,
                onClosed: () => context.go('/notes'),
              ),
        itemIds: [for (final n in notes) n.id],
        selectedId: selectedId,
        dataLoaded: async.hasValue,
        onSelectionCleared: () => context.go('/notes'),
        onCreate: () => context.go('/notes/new'),
        onMoveSelection: (dir) {
          if (filtered.isEmpty) return;
          final i = filtered.indexWhere((n) => n.id == selectedId);
          context.go('/notes/${filtered[(i + dir).clamp(0, filtered.length - 1)].id}');
        },
      ),
    );
  }
}

class _NoteTile extends ConsumerWidget {
  const _NoteTile({required this.note, required this.selected});
  final Note note;
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final fmt = ref.watch(formatDateProvider);
    final repo = ref.read(notesRepoProvider);
    final messenger = ScaffoldMessenger.of(context);
    final l = L10n.of(context);
    Future<void> delete() async {
      await repo.delete(note.id);
      showUndoSnackOn(messenger, l.entityDeleted(l.quickAddNote), undoLabel: l.undo, onUndo: () => repo.restore(note));
    }

    final preview = stripMarkdown(note.content);
    return SwipeActionTile(
      key: ValueKey('note-${note.id}'),
      onSwipeLeft: delete,
      menuItems: [
        TileMenuItem(label: l.delete, icon: Icons.delete_outline, destructive: true, onTap: delete),
      ],
      child: ListTile(
        selected: selected,
        selectedTileColor: cs.secondaryContainer,
        title: Text(note.title, style: Theme.of(context).textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (preview.isNotEmpty) Text(preview, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: Space.xs),
            Wrap(spacing: Space.xs, runSpacing: Space.xs, crossAxisAlignment: WrapCrossAlignment.center, children: [
              for (final t in splitTags(note.tags)) Chip(label: Text(t), visualDensity: VisualDensity.compact),
              Text(fmt(note.updatedAt.toLocal()), style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
            ]),
          ],
        ),
        onTap: () => context.isExpanded ? context.go('/notes/${note.id}') : openNote(context, id: note.id),
      ),
    );
  }
}
