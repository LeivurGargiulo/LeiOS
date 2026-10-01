import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../design/motion.dart';
import '../design/tokens.dart';
import '../validation/validation.dart';
import 'dialogs.dart';

enum EditorPresentation { sheet, screen, inline }

/// Shows [builder] as a modal bottom sheet configured per spec §9.5.
/// Drag-to-dismiss is handled by [EntitySheet] itself so a dirty sheet can ask first.
Future<T?> showEntitySheet<T>(BuildContext context, {required WidgetBuilder builder}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: false,
    enableDrag: false,
    constraints: const BoxConstraints(maxWidth: Layout.maxSheetWidth),
    builder: builder,
  );
}

Future<T?> pushEntityScreen<T>(BuildContext context, {required WidgetBuilder builder}) {
  return Navigator.of(context, rootNavigator: true).push<T>(MaterialPageRoute(builder: builder, fullscreenDialog: true));
}

/// Shared save/validation logic for the three presentations.

/// Compact modal sheet for short forms (spec §9.5).
class EntitySheet extends StatefulWidget {
  const EntitySheet({
    super.key,
    required this.title,
    required this.child,
    required this.dirty,
    required this.valid,
    required this.onSave,
    this.onDelete,
    this.saveLabel,
  });

  final String title;
  final Widget child;
  final bool dirty;
  final bool valid;
  final Future<void> Function() onSave;
  final Future<void> Function()? onDelete;
  final String? saveLabel;

  @override
  State<EntitySheet> createState() => _EntitySheetState();
}

class _EntitySheetState extends State<EntitySheet> {
  String? _error;
  bool _busy = false;

  Future<void> _close() async {
    if (widget.dirty && !await confirmDiscard(context)) return;
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onSave();
      if (mounted) Navigator.of(context).pop(true);
    } on ValidationException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final cs = Theme.of(context).colorScheme;
    final maxH = MediaQuery.sizeOf(context).height * 0.9;
    return PopScope(
      canPop: !widget.dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) await _close();
      },
      child: AnimatedPadding(
        duration: motionDuration(context),
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxH),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragEnd: (d) {
                  if ((d.primaryVelocity ?? 0) > 300) _close();
                },
                child: SizedBox(
                  height: 32,
                  width: double.infinity,
                  child: Center(
                    child: Container(
                      width: 32,
                      height: 4,
                      decoration: BoxDecoration(color: cs.onSurfaceVariant.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(Space.xl, 0, Space.xl, Space.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Semantics(header: true, child: Text(widget.title, style: Theme.of(context).textTheme.titleLarge)),
                      const SizedBox(height: Space.md),
                      widget.child,
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(Space.xl, Space.sm, Space.xl, Space.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: Space.sm),
                        child: Text(_error!, style: TextStyle(color: cs.error), key: const Key('editor-error')),
                      ),
                    Row(
                      children: [
                        if (widget.onDelete != null)
                          TextButton(
                            style: TextButton.styleFrom(foregroundColor: cs.error),
                            onPressed: _busy ? null : () async {
                              await widget.onDelete!();
                            },
                            child: Text(l.delete),
                          ),
                        const Spacer(),
                        TextButton(onPressed: _busy ? null : _close, child: Text(l.cancel)),
                        const SizedBox(width: Space.sm),
                        FilledButton(
                          onPressed: (!widget.valid || _busy) ? null : _save,
                          child: _busy
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              : Text(widget.saveLabel ?? l.save),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-screen editor (AppBar Close/Save) that also renders inside the detail pane
/// on expanded widths when [inline] is true (spec §9.4, §9.5).
class EntityScreen extends StatefulWidget {
  const EntityScreen({
    super.key,
    required this.title,
    required this.child,
    required this.dirty,
    required this.valid,
    required this.onSave,
    this.onDelete,
    this.inline = false,
    this.onClosed,
  });

  final String title;
  final Widget child;
  final bool dirty;
  final bool valid;
  final Future<void> Function() onSave;
  final Future<void> Function()? onDelete;
  final bool inline;

  /// Called after save / discard when inline (deselects). Defaults to popping the route.
  final VoidCallback? onClosed;

  @override
  State<EntityScreen> createState() => _EntityScreenState();
}

class _EntityScreenState extends State<EntityScreen> {
  String? _error;
  bool _busy = false;

  void _done() {
    if (widget.onClosed != null) {
      widget.onClosed!();
    } else if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _close() async {
    if (widget.dirty && !await confirmDiscard(context)) return;
    if (mounted) _done();
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onSave();
      if (mounted) _done();
    } on ValidationException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final cs = Theme.of(context).colorScheme;
    final canSave = widget.valid && !_busy;
    final body = SingleChildScrollView(
      padding: EdgeInsets.all(widget.inline ? Space.xl : Space.lg),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Layout.maxContentWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: Space.md),
                  child: Text(_error!, style: TextStyle(color: cs.error), key: const Key('editor-error')),
                ),
              widget.child,
              if (widget.onDelete != null) ...[
                const SizedBox(height: Space.xl),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: cs.error),
                    onPressed: _busy ? null : () => widget.onDelete!(),
                    icon: const Icon(Icons.delete_outline),
                    label: Text(l.delete),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (widget.inline) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.xl, vertical: Space.sm),
            child: Row(
              children: [
                Expanded(child: Text(widget.title, style: Theme.of(context).textTheme.titleLarge)),
                TextButton(onPressed: _busy ? null : _close, child: Text(l.discard)),
                const SizedBox(width: Space.sm),
                FilledButton(onPressed: canSave ? _save : null, child: Text(l.save)),
              ],
            ),
          ),
          const Divider(),
          Expanded(child: body),
        ],
      );
    }

    return PopScope(
      canPop: !widget.dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) await _close();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(icon: const Icon(Icons.close), tooltip: l.close, onPressed: _close),
          title: Text(widget.title),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: Space.sm),
              child: FilledButton(onPressed: canSave ? _save : null, child: Text(l.save)),
            ),
          ],
        ),
        body: SafeArea(child: body),
      ),
    );
  }
}

/// Renders the same form content in the requested presentation.
class EntityEditor extends StatelessWidget {
  const EntityEditor({
    super.key,
    required this.presentation,
    required this.title,
    required this.child,
    required this.dirty,
    required this.valid,
    required this.onSave,
    this.onDelete,
    this.onClosed,
  });

  final EditorPresentation presentation;
  final String title;
  final Widget child;
  final bool dirty;
  final bool valid;
  final Future<void> Function() onSave;
  final Future<void> Function()? onDelete;
  final VoidCallback? onClosed;

  @override
  Widget build(BuildContext context) {
    if (presentation == EditorPresentation.sheet) {
      return EntitySheet(title: title, dirty: dirty, valid: valid, onSave: onSave, onDelete: onDelete, child: child);
    }
    return EntityScreen(
      title: title,
      dirty: dirty,
      valid: valid,
      onSave: onSave,
      onDelete: onDelete,
      inline: presentation == EditorPresentation.inline,
      onClosed: onClosed,
      child: child,
    );
  }
}

/// Animated "More details" expander (spec §9.5).
class MoreDetails extends StatefulWidget {
  const MoreDetails({super.key, required this.child, this.label, this.initiallyOpen = false});
  final Widget child;
  final String? label;
  final bool initiallyOpen;

  @override
  State<MoreDetails> createState() => _MoreDetailsState();
}

class _MoreDetailsState extends State<MoreDetails> {
  late bool _open = widget.initiallyOpen;

  @override
  Widget build(BuildContext context) {
    final label = widget.label ?? L10n.of(context).moreDetails;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => setState(() => _open = !_open),
            icon: AnimatedRotation(
              turns: _open ? 0.5 : 0,
              duration: motionDuration(context),
              child: const Icon(Icons.expand_more),
            ),
            label: Text(label),
          ),
        ),
        AnimatedSize(
          duration: motionDuration(context, Dur.medium),
          curve: Ease.inPlace,
          alignment: Alignment.topCenter,
          child: _open ? widget.child : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}
