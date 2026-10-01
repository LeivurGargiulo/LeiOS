import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../l10n/app_localizations.dart';

enum SyncState { synced, syncing, offline, error }

SyncState syncStateOf({required bool connected, required bool busy, required bool hasError}) {
  if (hasError) return SyncState.error;
  if (!connected) return SyncState.offline;
  if (busy) return SyncState.syncing;
  return SyncState.synced;
}

class SyncStatusChip extends ConsumerWidget {
  const SyncStatusChip({super.key, this.compact = true});

  /// Icon-only (AppBar) vs icon + label + time (rail).
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L10n.of(context);
    final cs = Theme.of(context).colorScheme;
    final status = ref.watch(syncStatusProvider).asData?.value;
    final errors = ref.watch(syncErrorsProvider).asData?.value ?? const [];
    final state = syncStateOf(
      connected: status?.connected ?? false,
      busy: (status?.uploading ?? false) || (status?.downloading ?? false) || (status?.connecting ?? false),
      hasError: errors.isNotEmpty || status?.uploadError != null,
    );
    final (icon, label, color) = switch (state) {
      SyncState.synced => (Icons.cloud_done_outlined, l.syncSynced, cs.primary),
      SyncState.syncing => (Icons.sync, l.syncSyncing, cs.primary),
      SyncState.offline => (Icons.cloud_off_outlined, l.syncOffline, cs.onSurfaceVariant),
      SyncState.error => (Icons.error_outline, l.syncError, cs.error),
    };
    final last = status?.lastSyncedAt;
    final lastText = last == null ? '' : DateFormat.Hm().format(last.toLocal());
    void open() => context.go('/settings');
    if (compact) {
      return IconButton(
        tooltip: '$label${lastText.isEmpty ? '' : ' · $lastText'}',
        icon: Icon(icon, color: color),
        onPressed: open,
      );
    }
    return ActionChip(
      avatar: Icon(icon, size: 18, color: color),
      label: Text(lastText.isEmpty ? label : '$label · $lastText'),
      onPressed: open,
    );
  }
}
