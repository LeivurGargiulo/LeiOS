import 'package:flutter/material.dart';

import '../features/finance/finance_forms.dart';
import '../features/notes/note_form.dart';
import '../features/tasks/task_form.dart';
import '../l10n/app_localizations.dart';

/// Global quick-add chooser: Task / Note / Transaction in one gesture from anywhere
/// (FAB long-press or Ctrl+N on desktop; spec §9.6).
Future<void> showQuickAdd(BuildContext context) async {
  final l = L10n.of(context);
  final choice = await showModalBottomSheet<int>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    constraints: const BoxConstraints(maxWidth: 560),
    builder: (ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
          child: Align(alignment: Alignment.centerLeft, child: Text(l.quickAddTitle, style: Theme.of(ctx).textTheme.titleLarge)),
        ),
        ListTile(leading: const Icon(Icons.task_alt), title: Text(l.quickAddTask), onTap: () => Navigator.pop(ctx, 0)),
        ListTile(leading: const Icon(Icons.edit_note), title: Text(l.quickAddNote), onTap: () => Navigator.pop(ctx, 1)),
        ListTile(leading: const Icon(Icons.account_balance_wallet_outlined), title: Text(l.quickAddTransaction), onTap: () => Navigator.pop(ctx, 2)),
        const SizedBox(height: 16),
      ],
    ),
  );
  if (choice == null || !context.mounted) return;
  switch (choice) {
    case 0:
      openTask(context);
    case 1:
      openNote(context);
    case 2:
      openTransaction(context);
  }
}
