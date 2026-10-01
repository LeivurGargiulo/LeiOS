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
    final l = L10n.of(context);
    final ctrl = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);
    final auth = ref.read(authServiceProvider);
    final pw = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.settingsChangePassword),
        content: TextField(controller: ctrl, obscureText: true, autofocus: true, decoration: InputDecoration(labelText: l.settingsNewPassword)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: Text(l.save)),
        ],
      ),
    );
    ctrl.dispose();
    if (pw == null) return;
    if (pw.length < 6) {
      messenger.showSnackBar(SnackBar(content: Text(l.authPasswordMin)));
      return;
    }
    try {
      await auth.updatePassword(pw);
      messenger.showSnackBar(SnackBar(content: Text(l.settingsPasswordUpdated)));
    } on AuthException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _signOut() async {
    final db = ref.read(dbProvider);
    final pending = (await db.getUploadQueueStats()).count;
    if (!mounted) return;
    final l = L10n.of(context);
    final ok = await confirmDelete(
      context,
      title: l.settingsSignOutTitle,
      body: pending > 0 ? l.settingsSignOutPending(pending) : l.settingsSignOutClean,
      confirmLabel: l.settingsSignOut,
    );
    if (!ok) return;
    await db.disconnectAndClear();
    await ref.read(authServiceProvider).signOut();
  }

  Future<void> _export() async {
    final l = L10n.of(context);
    final ok = await confirmDelete(
      context,
      title: l.settingsExportTitle,
      body: l.settingsExportBody,
      confirmLabel: l.settingsExport,
    );
    if (!ok || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final db = ref.read(dbProvider);
    final json = await exportDatabase(db);
    final name = exportFileName(DateTime.now());
    final dir = await getTemporaryDirectory();
    final file = await writeAtomic(File(p.join(dir.path, name)), json);
    final saved = await FilePicker.saveFile(fileName: name, bytes: utf8.encode(json), mimeType: 'application/json', dialogTitle: l.settingsExportDialogTitle);
    await file.delete().catchError((_) => file);
    messenger.showSnackBar(SnackBar(content: Text(saved == null ? l.settingsExportCancelled : l.settingsExportSaved)));
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
              SectionHeader(l.settingsProfile),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.lg),
                child: TextField(
                  controller: _name,
                  decoration: InputDecoration(labelText: l.settingsDisplayName),
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
              SectionHeader(l.settingsAppearance),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.lg),
                child: SegmentedButton<ThemeMode>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(value: ThemeMode.system, label: Text(l.themeSystem)),
                    ButtonSegment(value: ThemeMode.light, label: Text(l.themeLight)),
                    ButtonSegment(value: ThemeMode.dark, label: Text(l.themeDark)),
                  ],
                  selected: {mode},
                  onSelectionChanged: (s) => ref.read(themeModeProvider.notifier).set(s.first),
                ),
              ),
              SectionHeader(l.settingsAccount),
              ListTile(leading: const Icon(Icons.alternate_email), title: Text(l.fieldEmail), subtitle: Text(user?.email ?? '')),
              ListTile(leading: const Icon(Icons.password), title: Text(l.settingsChangePassword), onTap: _changePassword),
              ListTile(
                leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
                title: Text(l.settingsSignOut, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                onTap: _signOut,
              ),
              SectionHeader(l.settingsSync),
              ListTile(
                leading: const Icon(Icons.cloud_sync_outlined),
                title: Text(status == null ? l.syncOffline : (status.connected ? l.settingsConnected : l.syncOffline)),
                subtitle: Text(last == null ? l.settingsNotSyncedYet : l.settingsLastSync(DateFormat.yMd().add_Hm().format(last.toLocal()))),
              ),
              ListTile(leading: const Icon(Icons.upload_outlined), title: Text(l.settingsPendingChanges), trailing: Text('$pending', style: moneyStyle(tt.titleMedium))),
              if (errors.isEmpty)
                SizedBox(height: 180, child: EmptyState(icon: Icons.cloud_done, title: l.emptySyncTitle, seed: 50, compact: true))
              else ...[
                ListTile(
                  leading: Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
                  title: Text(l.settingsSyncErrors(errors.length)),
                  trailing: TextButton(onPressed: () => ref.read(syncErrorsRepoProvider).clear(), child: Text(l.settingsDismissAll)),
                ),
                for (final e in errors) ListTile(dense: true, title: Text('${e.op} ${e.table}'), subtitle: Text(e.message)),
              ],
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.sm),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: Text(l.settingsReconnect),
                    onPressed: () async {
                      final db = ref.read(dbProvider);
                      await db.disconnect();
                      if (ref.read(syncEnabledProvider)) await db.connect(connector: SupabaseConnector(db));
                    },
                  ),
                ),
              ),
              SectionHeader(l.settingsData),
              ListTile(leading: const Icon(Icons.download_outlined), title: Text(l.settingsExportData), subtitle: Text(l.settingsExportHint), onTap: _export),
              SectionHeader(l.settingsAbout),
              ListTile(leading: const Icon(Icons.info_outline), title: Text(l.appName), subtitle: Text(l.settingsVersion(appVersion))),
            ],
          ),
        ),
      ),
    );
  }
}
