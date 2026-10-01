import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../app/providers.dart';
import '../../app/screen_scaffold.dart';
import '../../core/design/tokens.dart';
import '../../core/export/exporter.dart';
import '../../core/sync/auth_service.dart';
import '../../core/sync/supabase_connector.dart';
import '../../core/validation/validation.dart';
import '../../core/widgets/dialogs.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/small_widgets.dart';
import '../../l10n/app_localizations.dart';

const _dateFormats = ['yyyy-MM-dd', 'dd/MM/yyyy', 'MM/dd/yyyy', 'd MMM yyyy'];
const appVersion = String.fromEnvironment('APP_VERSION', defaultValue: '1.0.0+1');

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _name = TextEditingController();
  bool _nameInit = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    try {
      await ref.read(settingsRepoProvider).save(displayName: _name.text);
    } on ValidationException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _changePassword() async {
    final ctrl = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);
    final auth = ref.read(authServiceProvider);
    final pw = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change password'),
        content: TextField(controller: ctrl, obscureText: true, autofocus: true, decoration: const InputDecoration(labelText: 'New password')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(L10n.of(ctx).cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: Text(L10n.of(ctx).save)),
        ],
      ),
    );
    ctrl.dispose();
    if (pw == null) return;
    if (pw.length < 6) {
      messenger.showSnackBar(const SnackBar(content: Text('Use at least 6 characters.')));
      return;
    }
    try {
      await auth.updatePassword(pw);
      messenger.showSnackBar(const SnackBar(content: Text('Password updated.')));
    } on AuthException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _signOut() async {
    final db = ref.read(dbProvider);
    final pending = (await db.getUploadQueueStats()).count;
    if (!mounted) return;
    final ok = await confirmDelete(
      context,
      title: 'Sign out?',
      body: pending > 0
          ? 'You have $pending change${pending == 1 ? '' : 's'} that haven\'t synced yet. Signing out will discard them and clear local data.'
          : 'Local data on this device will be cleared. Everything is safe in the cloud.',
      confirmLabel: 'Sign out',
    );
    if (!ok) return;
    await db.disconnectAndClear();
    await ref.read(authServiceProvider).signOut();
  }

  Future<void> _export() async {
    final ok = await confirmDelete(
      context,
      title: 'Export data?',
      body: 'The JSON file is plain text and NOT encrypted. Keep it somewhere safe.',
      confirmLabel: 'Export',
    );
    if (!ok || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final db = ref.read(dbProvider);
    final json = await exportDatabase(db);
    final name = exportFileName(DateTime.now());
    final dir = await getTemporaryDirectory();
    final file = await writeAtomic(File(p.join(dir.path, name)), json);
    final saved = await FilePicker.saveFile(fileName: name, bytes: utf8.encode(json), mimeType: 'application/json', dialogTitle: 'Save LeiOS export');
    await file.delete().catchError((_) => file);
    messenger.showSnackBar(SnackBar(content: Text(saved == null ? 'Export cancelled.' : 'Export saved.')));
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final settings = ref.watch(settingsProvider).asData?.value;
    if (settings != null && !_nameInit) {
      _name.text = settings.displayName;
      _nameInit = true;
    }
    final user = ref.watch(authProvider);
    final mode = ref.watch(themeModeProvider);
    final fmtPattern = ref.watch(dateFormatProvider);
    final status = ref.watch(syncStatusProvider).asData?.value;
    final pending = ref.watch(pendingOpsProvider).asData?.value ?? 0;
    final errors = ref.watch(syncErrorsProvider).asData?.value ?? const [];
    final tt = Theme.of(context).textTheme;
    final last = status?.lastSyncedAt;

    return ScreenScaffold(
      title: l.navSettings,
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Layout.maxSettingsWidth),
          child: ListView(
            padding: const EdgeInsets.only(bottom: Space.xxl),
            children: [
              const SectionHeader('Profile'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.lg),
                child: TextField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Display name'),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _saveName(),
                  onEditingComplete: _saveName,
                ),
              ),
              const SizedBox(height: Space.md),
              RadioGroup<String>(
                groupValue: fmtPattern,
                onChanged: (v) {
                  if (v != null) ref.read(settingsRepoProvider).save(dateFormat: v);
                },
                child: Column(children: [
                  for (final f in _dateFormats)
                    RadioListTile<String>(
                      value: f,
                      title: Text(DateFormat(f).format(DateTime.now())),
                      subtitle: Text(f),
                    ),
                ]),
              ),
              const SectionHeader('Appearance'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.lg),
                child: SegmentedButton<ThemeMode>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: ThemeMode.system, label: Text('System')),
                    ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                    ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                  ],
                  selected: {mode},
                  onSelectionChanged: (s) => ref.read(themeModeProvider.notifier).set(s.first),
                ),
              ),
              const SectionHeader('Account'),
              ListTile(leading: const Icon(Icons.alternate_email), title: const Text('Email'), subtitle: Text(user?.email ?? '')),
              ListTile(leading: const Icon(Icons.password), title: const Text('Change password'), onTap: _changePassword),
              ListTile(
                leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
                title: Text('Sign out', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                onTap: _signOut,
              ),
              const SectionHeader('Sync'),
              ListTile(
                leading: const Icon(Icons.cloud_sync_outlined),
                title: Text(status == null ? 'Offline' : (status.connected ? 'Connected' : 'Offline')),
                subtitle: Text(last == null ? 'Not synced yet' : 'Last sync ${DateFormat.yMd().add_Hm().format(last.toLocal())}'),
              ),
              ListTile(leading: const Icon(Icons.upload_outlined), title: const Text('Pending changes'), trailing: Text('$pending', style: moneyStyle(tt.titleMedium))),
              if (errors.isEmpty)
                const SizedBox(height: 180, child: EmptyState(icon: Icons.cloud_done, title: 'All changes synced', seed: 50, compact: true))
              else ...[
                ListTile(
                  leading: Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
                  title: Text('${errors.length} change${errors.length == 1 ? '' : 's'} could not be synced'),
                  trailing: TextButton(onPressed: () => ref.read(syncErrorsRepoProvider).clear(), child: const Text('Dismiss all')),
                ),
                for (final e in errors) ListTile(dense: true, title: Text('${e.op} ${e.table}'), subtitle: Text(e.message)),
              ],
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.sm),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reconnect'),
                    onPressed: () async {
                      final db = ref.read(dbProvider);
                      await db.disconnect();
                      if (ref.read(syncEnabledProvider)) await db.connect(connector: SupabaseConnector(db));
                    },
                  ),
                ),
              ),
              const SectionHeader('Data'),
              ListTile(leading: const Icon(Icons.download_outlined), title: const Text('Export data'), subtitle: const Text('Plain, unencrypted JSON of all your data'), onTap: _export),
              const SectionHeader('About'),
              const ListTile(leading: Icon(Icons.info_outline), title: Text('LeiOS'), subtitle: Text('Version $appVersion')),
            ],
          ),
        ),
      ),
    );
  }
}
