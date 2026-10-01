import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../helpers/harness.dart';

const routes = ['/today', '/tasks', '/calendar', '/goals', '/notes', '/lists', '/finance', '/settings'];

void main() {
  group('navigation by window size', () {
    testWidgets('compact: bottom bar with 4 destinations + More', (tester) async {
      setScreen(tester, 360, 800);
      final h = await openHarness(tester);
      await pumpApp(tester, h);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
      final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(bar.destinations.length, 5);
      await tester.tap(find.text('More'));
      await settle(tester);
      for (final l in ['Notes', 'Lists', 'Finances', 'Settings']) {
        expect(find.text(l), findsOneWidget);
      }
      await tester.tap(find.text('Notes'));
      await settle(tester);
      expect(find.text('No notes yet'), findsOneWidget);
    });

    testWidgets('medium: rail with all 8 destinations and labels', (tester) async {
      setScreen(tester, 700, 960);
      final h = await openHarness(tester);
      await pumpApp(tester, h);
      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.destinations.length, 8);
      expect(rail.extended, isFalse);
      expect(rail.labelType, NavigationRailLabelType.all);
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('expanded: extended rail, FAB hidden, + New in list pane', (tester) async {
      setScreen(tester, 1280, 800);
      final h = await openHarness(tester);
      await pumpApp(tester, h);
      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.extended, isTrue);
      expect(find.byType(FloatingActionButton), findsNothing);
      GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/tasks');
      await settle(tester);
      expect(find.text('New'), findsOneWidget);
      expect(find.text('Select an item'), findsOneWidget);
    });
  });

  // Layout verification matrix (spec §9.10): sizes × text scale, light/dark.
  final sizes = {'360x800': const Size(360, 800), '412x915': const Size(412, 915), '600x960': const Size(600, 960), '840x1200': const Size(840, 1200), '1280x800': const Size(1280, 800)};
  for (final e in sizes.entries) {
    for (final scale in [1.0, 2.0]) {
      for (final dark in [false, true]) {
        if (dark && e.key != '360x800' && e.key != '1280x800') continue;
        testWidgets('no overflow on any destination @ ${e.key} scale $scale ${dark ? 'dark' : 'light'}', (tester) async {
          setScreen(tester, e.value.width, e.value.height, textScale: scale);
          tester.platformDispatcher.platformBrightnessTestValue = dark ? Brightness.dark : Brightness.light;
          addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
          final h = await openHarness(tester);
          await seedAll(tester, h);
          await pumpApp(tester, h);
          final router = GoRouter.of(tester.element(find.byType(Scaffold).first));
          final problems = <String>[];
          final original = FlutterError.onError;
          var current = '';
          FlutterError.onError = (d) {
            final where = RegExp(r'LeivurOS/lib/[^\s)]+').allMatches(d.toString().replaceAll('\n', ' ')).map((m) => m[0]).take(3).join(' ');
            FlutterError.dumpErrorToConsole(d);
            problems.add('[$current] ${d.exceptionAsString().split('\n').first} @ $where');
          };
          addTearDown(() => FlutterError.onError = original);
          for (final r in routes) {
            current = r;
            router.go(r);
            await settleLight(tester);
          }
          FlutterError.onError = original;
          expect(problems.toSet().toList(), isEmpty);
        });
      }
    }
  }
}
