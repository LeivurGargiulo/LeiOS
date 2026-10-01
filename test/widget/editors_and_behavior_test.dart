import 'dart:ui' show AccessibilityFeatures;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:leios/data/list_items_repo.dart';
import 'package:leios/data/notes_repo.dart';
import 'package:leios/data/tasks_repo.dart';
import 'package:leios/domain/models.dart';

import '../data/test_db.dart';
import '../helpers/harness.dart';

GoRouter routerOf(WidgetTester tester) => GoRouter.of(tester.element(find.byType(Scaffold).first));

Future<void> collectErrors(WidgetTester tester, Future<void> Function(List<String> problems) body) async {
  final problems = <String>[];
  final original = FlutterError.onError;
  FlutterError.onError = (d) {
    FlutterError.dumpErrorToConsole(d);
    problems.add(d.exceptionAsString().split('\n').first);
  };
  try {
    await body(problems);
  } finally {
    FlutterError.onError = original;
  }
  expect(problems, isEmpty);
}

void main() {
  group('master-detail (expanded)', () {
    testWidgets('selecting a task shows the inline editor; deleting it elsewhere clears the selection', (tester) async {
      setScreen(tester, 1280, 800);
      final h = await openHarness(tester);
      late String id;
      await tester.runAsync(() async => id = await TasksRepo(h.db, userId: () => testUser).create(title: 'Pick me'));
      await pumpApp(tester, h);
      routerOf(tester).go('/tasks/$id');
      await settle(tester);
      expect(find.text('Edit task'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Pick me'), findsOneWidget);

      // Deleted from "another device".
      await tester.runAsync(() => TasksRepo(h.db, userId: () => testUser).delete(id));
      await settle(tester);
      expect(find.text('Edit task'), findsNothing);
      expect(find.text('Select an item'), findsOneWidget);
      expect(routerOf(tester).routeInformationProvider.value.uri.path, '/tasks');
    });

    testWidgets('+ New opens create mode in the detail pane and Save adds the item', (tester) async {
      setScreen(tester, 1280, 800);
      final h = await openHarness(tester);
      await pumpApp(tester, h);
      routerOf(tester).go('/notes');
      await settle(tester);
      await tester.tap(find.text('New note').first);
      await settle(tester);
      expect(find.text('New note'), findsWidgets);
      await tester.enterText(find.widgetWithText(TextField, 'Title'), 'Inline note');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await settle(tester);
      final rows = await tester.runAsync(() => h.db.getAll('SELECT title FROM notes'));
      expect(rows!.single['title'], 'Inline note');
    });

    testWidgets('Ctrl+N opens the quick-add chooser', (tester) async {
      setScreen(tester, 1280, 800);
      final h = await openHarness(tester);
      await pumpApp(tester, h);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await settle(tester);
      expect(find.text('Quick add'), findsOneWidget);
    });
  });

  group('contextual FAB', () {
    testWidgets('tap creates in context, long-press opens quick add', (tester) async {
      setScreen(tester, 412, 915);
      final h = await openHarness(tester);
      await pumpApp(tester, h);
      routerOf(tester).go('/tasks');
      await settle(tester);
      await tester.tap(find.byType(FloatingActionButton).hitTestable());
      await settle(tester);
      expect(find.text('New task'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await settle(tester);

      await tester.longPress(find.byType(FloatingActionButton).hitTestable());
      await settle(tester);
      expect(find.text('Quick add'), findsOneWidget);
      expect(find.text('Transaction'), findsOneWidget);
    });
  });

  group('Tasks views', () {
    testWidgets('view switch is remembered and Matrix shows four quadrants', (tester) async {
      setScreen(tester, 412, 915);
      final h = await openHarness(tester);
      await tester.runAsync(() => TasksRepo(h.db, userId: () => testUser).create(title: 'Quadrant item', urgent: true, important: true));
      await pumpApp(tester, h);
      routerOf(tester).go('/tasks');
      await settle(tester);
      await tester.tap(find.byTooltip('Change view'));
      await settle(tester);
      await tester.tap(find.text('Matrix'));
      await settle(tester);
      expect(find.textContaining('Urgent & important'), findsOneWidget);
      expect(find.textContaining('Neither'), findsOneWidget);
      expect(h.prefs.getString('tasks_view'), 'matrix');
    });
  });

  group('ListItemsView', () {
    testWidgets('each of the four tabs renders with its own labels and empty state', (tester) async {
      setScreen(tester, 412, 915);
      final h = await openHarness(tester);
      await pumpApp(tester, h);
      routerOf(tester).go('/lists');
      await settle(tester);
      expect(find.text('Nothing to watch or read'), findsOneWidget);
      for (final (tab, title, done) in [
        ('Wishlist', 'Your wishlist is empty', 'Purchased'),
        ('Dreams', 'No dreams yet', 'Done'),
        ('Learning', 'Nothing to learn yet', 'Learned'),
      ]) {
        await tester.tap(find.text(tab));
        await settle(tester);
        expect(find.text(title), findsOneWidget, reason: tab);
        expect(find.text(done), findsWidgets, reason: '$tab filter label');
      }
    });

    testWidgets('wishlist shows the pending total and Pending is the default filter', (tester) async {
      setScreen(tester, 412, 915);
      final h = await openHarness(tester);
      await tester.runAsync(() async {
        final r = ListItemsRepo(h.db, userId: () => testUser);
        await r.create(ListKind.wishlist, title: 'Keyboard', price: 120);
        await r.create(ListKind.wishlist, title: 'Mouse', price: 30);
        await r.create(ListKind.wishlist, title: 'Bought thing', price: 999, done: true);
      });
      await pumpApp(tester, h);
      routerOf(tester).go('/lists');
      await settle(tester);
      await tester.tap(find.text('Wishlist'));
      await settle(tester);
      expect(find.text('Keyboard'), findsOneWidget);
      expect(find.text('Bought thing'), findsNothing);
      expect(find.text('Pending total'), findsOneWidget);
      expect(find.text('150'), findsOneWidget);
    });
  });

  group('Notes', () {
    testWidgets('search and tag filter narrow the list; empty result shows No matches', (tester) async {
      setScreen(tester, 412, 915);
      final h = await openHarness(tester);
      await tester.runAsync(() async {
        final r = NotesRepo(h.db, userId: () => testUser);
        await r.create(title: 'Groceries', content: 'milk', tags: 'home');
        await r.create(title: 'Standup', content: 'agenda', tags: 'work');
      });
      await pumpApp(tester, h);
      routerOf(tester).go('/notes');
      await settle(tester);
      expect(find.text('Groceries'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilterChip, 'work'));
      await settle(tester);
      expect(find.text('Groceries'), findsNothing);
      expect(find.text('Standup'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilterChip, 'work'));
      await settle(tester);
      await tester.enterText(find.byType(SearchBar), 'zzz');
      await settle(tester);
      expect(find.text('No matches'), findsOneWidget);
    });
  });

  group('reduce motion', () {
    testWidgets('app renders and animations are instant when disableAnimations is set', (tester) async {
      setScreen(tester, 412, 915);
      tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      final h = await openHarness(tester);
      await seedAll(tester, h);
      await pumpApp(tester, h);
      expect(tester.takeException(), isNull);
      routerOf(tester).go('/finance');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
      // Fade-through is instant: the destination is already fully visible after a single short frame.
      expect(find.text('Transactions'), findsOneWidget);
    });
  });

  group('editors fit at 200% text on compact and expanded', () {
    for (final (name, w, hgt, route) in [
      ('task inline', 1280.0, 800.0, '/tasks/new'),
      ('note inline', 1280.0, 800.0, '/notes/new'),
      ('goal inline', 1280.0, 800.0, '/goals/new'),
      ('event inline', 1280.0, 800.0, '/calendar/2027-03-10/new'),
      ('transaction inline', 1280.0, 800.0, '/finance/tx:new'),
      ('fund inline', 1280.0, 800.0, '/finance/fund:new'),
      ('list item inline', 1280.0, 800.0, '/lists/new'),
    ]) {
      testWidgets(name, (tester) async {
        setScreen(tester, w, hgt, textScale: 2.0);
        final h = await openHarness(tester);
        await seedAll(tester, h);
        await pumpApp(tester, h);
        await collectErrors(tester, (problems) async {
          routerOf(tester).go(route);
          await settleLight(tester);
        });
      });
    }

    testWidgets('compact editors: task sheet, habit sheet, event/goal/note screens', (tester) async {
      setScreen(tester, 360, 800, textScale: 2.0);
      final h = await openHarness(tester);
      await seedAll(tester, h);
      await pumpApp(tester, h);
      await collectErrors(tester, (problems) async {
        for (final (route, fabTooltipPart) in [
          ('/tasks', 'Add task'),
          ('/calendar', 'Add event'),
          ('/goals', 'Add goal'),
          ('/notes', 'New note'),
          ('/lists', 'Add media item'),
          ('/finance', 'Add transaction'),
        ]) {
          routerOf(tester).go(route);
          await settleLight(tester);
          expect(find.byType(FloatingActionButton).hitTestable(), findsOneWidget, reason: 'FAB visible on $route');
          await tester.tap(find.byType(FloatingActionButton).hitTestable());
          await settleLight(tester);
          expect(find.byType(FilledButton), findsWidgets, reason: 'editor open for $route ($fabTooltipPart)');
          // Close via the Cancel / Close control.
          final close = find.byTooltip('Close');
          if (close.evaluate().isNotEmpty) {
            await tester.tap(close);
          } else {
            await tester.tap(find.text('Cancel'));
          }
          await settleLight(tester);
        }
      });
    });
  });
}

class FakeAccessibilityFeatures implements AccessibilityFeatures {
  const FakeAccessibilityFeatures({this.disableAnimations = false});
  @override
  final bool disableAnimations;
  @override
  bool get accessibleNavigation => false;
  @override
  bool get boldText => false;
  @override
  bool get highContrast => false;
  @override
  bool get invertColors => false;
  @override
  bool get onOffSwitchLabels => false;
  @override
  bool get reduceMotion => disableAnimations;
  @override
  bool get supportsAnnounce => true;
  @override
  dynamic noSuchMethod(Invocation invocation) => false;
}
