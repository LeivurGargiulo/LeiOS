import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/providers.dart';
import '../../core/design/tokens.dart';
import '../../core/widgets/dialogs.dart';
import '../../core/widgets/draft.dart';
import '../../core/widgets/entity_editor.dart';
import '../../core/widgets/filter_bar.dart';
import '../../core/widgets/small_widgets.dart';
import '../../domain/models.dart';
import '../../domain/tags.dart';
import '../../l10n/app_localizations.dart';

void openNote(BuildContext context, {String? id}) {
  if (MediaQuery.sizeOf(context).width >= 840) {
    context.go('/notes/${id ?? 'new'}');
  } else {
    pushEntityScreen(context, builder: (_) => NoteForm(noteId: id, presentation: EditorPresentation.screen));
  }
}

class NoteForm extends ConsumerStatefulWidget {
  const NoteForm({super.key, this.noteId, required this.presentation, this.onClosed});
  final String? noteId;
  final EditorPresentation presentation;
  final VoidCallback? onClosed;

  @override
  ConsumerState<NoteForm> createState() => _NoteFormState();
}

class _NoteFormState extends ConsumerState<NoteForm> with DraftFormMixin<NoteForm> {
  final _title = TextEditingController();
  final _tags = TextEditingController();
  final _content = TextEditingController();
  bool _preview = false;
  Note? _original;
  bool _loaded = false;

  @override
  String get draftKey => 'note:${widget.noteId ?? 'new'}';
  @override
  bool get isDirtyDraft => _dirty;
  @override
  Map<String, Object?> snapshot() => {'title': _title.text, 'tags': _tags.text, 'content': _content.text};
  @override
  void restore(Map<String, Object?> d) {
    _title.text = d['title'] as String? ?? '';
    _tags.text = d['tags'] as String? ?? '';
    _content.text = d['content'] as String? ?? '';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final id = widget.noteId;
    if (id != null) {
      final n = await ref.read(notesRepoProvider).get(id);
      if (n != null) {
        _original = n;
        _title.text = n.title;
        _tags.text = n.tags;
        _content.text = n.content;
      }
    }
    loadDraft();
    if (mounted) setState(() => _loaded = true);
  }

  @override
  void dispose() {
    _title.dispose();
    _tags.dispose();
    _content.dispose();
    super.dispose();
  }

  bool get _dirty {
    final o = _original;
    if (o == null) return _title.text.isNotEmpty || _tags.text.isNotEmpty || _content.text.isNotEmpty;
    return _title.text != o.title || _tags.text != o.tags || _content.text != o.content;
  }

  Future<void> _save() async {
    final repo = ref.read(notesRepoProvider);
    final messenger = ScaffoldMessenger.of(context);
    final l = L10n.of(context);
    if (widget.noteId != null) {
      await repo.update(widget.noteId!, title: _title.text, content: _content.text, tags: _tags.text);
    } else {
      final id = await repo.create(title: _title.text, content: _content.text, tags: _tags.text);
      showUndoSnackOn(messenger, l.entityAdded('Note'), undoLabel: l.undo, onUndo: () => repo.delete(id));
    }
    discardDraft();
  }

  Future<void> _delete() async {
    final n = _original;
    if (n == null) return;
    final repo = ref.read(notesRepoProvider);
    final messenger = ScaffoldMessenger.of(context);
    final l = L10n.of(context);
    await repo.delete(n.id);
    discardDraft();
    showUndoSnackOn(messenger, l.entityDeleted('Note'), undoLabel: l.undo, onUndo: () => repo.restore(n));
    if (!mounted) return;
    if (widget.presentation == EditorPresentation.inline) {
      widget.onClosed?.call();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final tags = splitTags(normalizeTags(_tags.text));
    return EntityEditor(
      presentation: widget.presentation,
      title: widget.noteId == null ? 'New note' : 'Edit note',
      dirty: _dirty,
      valid: _title.text.trim().isNotEmpty,
      onSave: _save,
      onDelete: widget.noteId == null ? null : _delete,
      onClosed: () {
        discardDraft();
        widget.onClosed?.call();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _title,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Title'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: Space.md),
          TextField(
            controller: _tags,
            decoration: const InputDecoration(labelText: 'Tags', helperText: 'Comma separated'),
            onChanged: (_) => setState(() {}),
          ),
          if (tags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: Space.sm),
              child: Wrap(spacing: Space.sm, runSpacing: Space.xs, children: [for (final t in tags) Chip(label: Text(t))]),
            ),
          const SectionHeader('Content', padding: EdgeInsets.only(top: Space.lg, bottom: Space.sm)),
          Align(
            alignment: Alignment.centerLeft,
            child: SegmentFilter<bool>(
              values: const [false, true],
              selected: _preview,
              labelOf: (p) => p ? 'Preview' : 'Edit',
              onSelected: (p) => setState(() => _preview = p),
            ),
          ),
          const SizedBox(height: Space.md),
          if (_preview)
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 240),
              child: MarkdownBody(
                data: _content.text.isEmpty ? '*Nothing to preview*' : _content.text,
                onTapLink: (text, href, title) {
                  if (href != null) launchUrl(Uri.parse(href));
                },
              ),
            )
          else
            TextField(
              controller: _content,
              minLines: 10,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(alignLabelWithHint: true, labelText: 'Markdown'),
              onChanged: (_) => setState(() {}),
            ),
        ],
      ),
    );
  }
}
