import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leios/data/tasks_repo.dart';
import 'package:leios/domain/models.dart';

import '../data/test_db.dart';
import '../helpers/harness.dart';

Future<void> tapText(WidgetTester tester, String text, {bool warn = true}) async {
  await tester.tap(find.text(text).first, warnIfMissed: warn);
  await settle(tester);
}

void main() {
  testWidgets('quick-add a task from Today → appears in Today (Due soon) and Tasks', (tester) async {
    setScreen(tester, 412, 915);
    final h = await openHarness(tester);
    await pumpApp(tester, h);

    // Today FAB opens the quick-add chooser.
    await tester.tap(find.byType(FloatingActionButton));
    await settle(tester);
    expect(find.text('Quick add'), findsOneWidget);
    await tapText(tester, 'Task');

    // Sheet: type a title, pick "Today" and save.
    await tester.enterText(find.byType(TextField).first, 'Write report');
    await tester.pump();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Today'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await settle(tester);

    expect(find.text('Task added'), findsOneWidget);
    expect(find.text('Write report'), findsOneWidget); // in Due soon

    // Tasks destination shows it too.
    await tester.tap(find.text('Tasks').last);
    await settle(tester);
    expect(find.text('Write report'), findsWidgets);
  });

  testWidgets('Save is disabled until the title is valid; dirty sheet asks before discarding', (tester) async {
    setScreen(tester, 412, 915);
    final h = await openHarness(tester);
    await pumpApp(tester, h);
    await tester.tap(find.byType(FloatingActionButton));
    await settle(tester);
    await tapText(tester, 'Task');

    FilledButton save() => tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Save'));
    expect(save().onPressed, isNull);
    await tester.enterText(find.byType(TextField).first, 'x');
    await tester.pump();
    expect(save().onPressed, isNotNull);

    await tester.tap(find.text('Cancel'));
    await settle(tester);
    expect(find.text('Discard changes?'), findsOneWidget);
    await tapText(tester, 'Discard');
    expect(find.text('Discard changes?'), findsNothing);
  });

  testWidgets('swipe left deletes a task with Undo', (tester) async {
    setScreen(tester, 412, 915);
    final h = await openHarness(tester);
    late TasksRepo repo;
    await tester.runAsync(() async {
      repo = TasksRepo(h.db, userId: () => testUser);
      await repo.create(title: 'Swipe me');
    });
    await pumpApp(tester, h);
    await tester.tap(find.text('Tasks').last);
    await settle(tester);
    expect(find.text('Swipe me'), findsOneWidget);

    await tester.drag(find.text('Swipe me'), const Offset(-500, 0));
    await settle(tester);
    expect(find.text('Swipe me'), findsNothing);
    expect(find.text('Undo'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await settle(tester);
    expect(find.text('Swipe me'), findsOneWidget);
  });

  testWidgets('tapping a task status circle advances todo → doing and Today shows it in Doing', (tester) async {
    setScreen(tester, 412, 915);
    final h = await openHarness(tester);
    await tester.runAsync(() => TasksRepo(h.db, userId: () => testUser).create(title: 'Focus'));
    await pumpApp(tester, h);
    await tester.tap(find.text('Tasks').last);
    await settle(tester);
    await tester.tap(find.bySemanticsLabel(RegExp('To do. Tap to advance')).first);
    await settle(tester);
    final tasks = await tester.runAsync(() => TasksRepo(h.db, userId: () => testUser).watchAll().first);
    expect(tasks!.single.status, TaskStatus.doing);
    await tester.tap(find.text('Today').last);
    await settle(tester);
    expect(find.text('Doing'), findsWidgets);
  });

  testWidgets('mood face upserts today and shows Edit note', (tester) async {
    setScreen(tester, 412, 915);
    final h = await openHarness(tester);
    await pumpApp(tester, h);
    expect(find.text('Add note or tags'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Mood 4 of 5'));
    await settle(tester);
    expect(find.text('Edit note'), findsOneWidget);
    final rows = await tester.runAsync(() => h.db.getAll('SELECT rating FROM feelings'));
    expect(rows!.single['rating'], 4);
  });
}
