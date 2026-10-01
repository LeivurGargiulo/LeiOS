@Tags(['screenshots'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:leios/app/app.dart';
import 'package:leios/app/providers.dart';

import '../helpers/harness.dart';

/// Renders real screenshots (Roboto + Material Icons from the Flutter SDK) into docs/screenshots.
/// Not part of CI:  flutter test test/golden/screenshots_test.dart
Future<void> loadFonts() async {
  final root = '${Platform.environment['FLUTTER_ROOT'] ?? '/opt/flutter'}/bin/cache/artifacts/material_fonts';
  Future<void> load(String family, String file) async {
    final f = File('$root/$file');
    if (!f.existsSync()) return;
    final loader = FontLoader(family)..addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())));
    await loader.load();
  }

  await load('Roboto', 'Roboto-Regular.ttf');
  await load('MaterialIcons', 'MaterialIcons-Regular.otf');
}

final _boundary = GlobalKey();

Future<void> shot(WidgetTester tester, String name) async {
  final ro = _boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final bytes = await tester.runAsync(() async {
    final image = await ro.toImage(pixelRatio: 1.5);
    return (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
  });
  File('docs/screenshots/$name.png').writeAsBytesSync(bytes!);
}

void main() {
  setUpAll(loadFonts);

  Future<void> run(WidgetTester tester, {required String suffix, required double w, required double h, required bool dark, required List<(String, String)> routes}) async {
    setScreen(tester, w, h);
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTouch;
    tester.platformDispatcher.platformBrightnessTestValue = dark ? Brightness.dark : Brightness.light;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    final hx = await openHarness(tester);
    await seedAll(tester, hx);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        dbProvider.overrideWithValue(hx.db),
        prefsProvider.overrideWithValue(hx.prefs),
        authServiceProvider.overrideWithValue(hx.auth),
        syncEnabledProvider.overrideWithValue(false),
      ],
      child: RepaintBoundary(key: _boundary, child: const LeiOSApp()),
    ));
    await settle(tester);
    final router = GoRouter.of(tester.element(find.byType(Scaffold).first));
    for (final (route, name) in routes) {
      router.go(route);
      await settle(tester);
      await shot(tester, '$name-$suffix');
    }
  }

  testWidgets('compact light', (tester) => run(tester, suffix: 'compact', w: 360, h: 780, dark: false, routes: [
        ('/today', 'today'),
        ('/tasks', 'tasks'),
        ('/calendar', 'calendar'),
        ('/goals', 'goals'),
        ('/notes', 'notes'),
        ('/lists', 'lists'),
        ('/finance', 'finances'),
        ('/settings', 'settings'),
      ]));

  testWidgets('compact dark', (tester) => run(tester, suffix: 'compact-dark', w: 360, h: 780, dark: true, routes: [
        ('/today', 'today'),
        ('/finance', 'finances'),
      ]));

  testWidgets('expanded light', (tester) => run(tester, suffix: 'expanded', w: 1280, h: 800, dark: false, routes: [
        ('/today', 'today'),
        ('/tasks', 'tasks'),
        ('/calendar', 'calendar'),
        ('/goals', 'goals'),
        ('/notes', 'notes'),
        ('/finance', 'finances'),
      ]));
}
