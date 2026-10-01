import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/design/theme.dart';
import '../l10n/app_localizations.dart';
import 'providers.dart';
import 'router.dart';

class LeiOSApp extends ConsumerWidget {
  const LeiOSApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(syncControllerProvider);
    return MaterialApp.router(
      title: 'LeiOS',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: ref.watch(themeModeProvider),
      routerConfig: ref.watch(routerProvider),
      localizationsDelegates: const [
        L10n.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: L10n.supportedLocales,
    );
  }
}

/// Shown instead of crashing when the build has no cloud configuration.
class NotConfiguredApp extends StatelessWidget {
  const NotConfiguredApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: buildTheme(Brightness.light),
      home: const Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'LeiOS is not configured.\n\nRun with --dart-define=SUPABASE_URL=… --dart-define=SUPABASE_ANON_KEY=… '
                '--dart-define=POWERSYNC_URL=… (see docs/SETUP.md).',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
