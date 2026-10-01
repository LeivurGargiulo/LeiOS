import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Standard destructive confirmation; the body states what else gets deleted (spec §9.7).
Future<bool> confirmDelete(
  BuildContext context, {
  required String title,
  required String body,
  String? confirmLabel,
}) async {
  final cs = Theme.of(context).colorScheme;
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(L10n.of(ctx).cancel)),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: cs.error),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel ?? L10n.of(ctx).delete),
        ),
      ],
    ),
  );
  return r ?? false;
}

Future<bool> confirmDiscard(BuildContext context) async {
  final l = L10n.of(context);
  final cs = Theme.of(context).colorScheme;
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.discardChangesTitle),
      content: Text(l.discardChangesBody),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: cs.error),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(l.discard),
        ),
      ],
    ),
  );
  return r ?? false;
}

void showUndoSnack(BuildContext context, String message, {VoidCallback? onUndo}) {
  final m = ScaffoldMessenger.of(context);
  m.clearSnackBars();
  m.showSnackBar(SnackBar(
    content: Text(message),
    duration: const Duration(seconds: 4),
    action: onUndo == null ? null : SnackBarAction(label: L10n.of(context).undo, onPressed: onUndo),
  ));
}

/// Same as [showUndoSnack] but with a captured messenger (usable after a sheet/route closes).
void showUndoSnackOn(ScaffoldMessengerState m, String message, {required String undoLabel, VoidCallback? onUndo}) {
  m.clearSnackBars();
  m.showSnackBar(SnackBar(
    content: Text(message),
    duration: const Duration(seconds: 4),
    action: onUndo == null ? null : SnackBarAction(label: undoLabel, onPressed: onUndo),
  ));
}
