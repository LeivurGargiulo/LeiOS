import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';

/// Keeps unsaved editor state in a provider keyed by entity so switching between
/// compact and expanded layouts (or rotating) does not lose edits (spec §9.3).
///
/// Usage: override [draftKey], [snapshot], [restore] and [isDirtyDraft]; call
/// [loadDraft] at the end of `initState`, [discardDraft] after save/discard.
mixin DraftFormMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  late final DraftsNotifier _draftNotifier = ref.read(draftsProvider.notifier);
  bool _draftDone = false;

  String get draftKey;
  Map<String, Object?> snapshot();
  void restore(Map<String, Object?> draft);
  bool get isDirtyDraft;

  void loadDraft() {
    final d = ref.read(draftsProvider)[draftKey];
    if (d != null) restore(d);
  }

  void discardDraft() {
    _draftDone = true;
    Future.microtask(() => _draftNotifier.clear(draftKey));
  }

  @override
  void dispose() {
    if (!_draftDone && isDirtyDraft) {
      final snap = snapshot();
      Future.microtask(() => _draftNotifier.put(draftKey, snap));
    }
    super.dispose();
  }
}
