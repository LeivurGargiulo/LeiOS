import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:leios/app/bootstrap.dart';
import 'package:leios/core/sync/auth_service.dart';

/// Linux desktop flow (spec §13.6): login (mock) → quick-add a task → it appears in
/// Today (Due soon) and in Tasks. Run with:
///   xvfb-run -a flutter test integration_test/app_test.dart -d linux
/// Several frames, so route/sheet animations (which start on the *next* frame) complete.
/// `pumpAndSettle` is not usable: empty-state illustrations loop forever.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('mock login → quick add task → visible in Today and Tasks', (tester) async {
    final dir = Directory.systemTemp.createTempSync('leios_it_');
    final db = await openDatabase(path: '${dir.path}/it.db');
    await bootstrap(authService: FakeAuthService(), db: db, syncEnabled: false);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Signed out → sign in screen.
    expect(find.text('Sign in'), findsWidgets);
    await tester.enterText(find.byType(TextFormField).at(0), 'lei@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'password');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await settle(tester);
    await settle(tester);
    expect(find.text('How are you today?'), findsOneWidget);

    // Quick-add via the FAB chooser (compact) — on a wide desktop window use Ctrl+N instead.
    final fab = find.byType(FloatingActionButton).hitTestable();
    if (fab.evaluate().isNotEmpty) {
      await tester.tap(fab);
    } else {
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    }
    await settle(tester);
    await tester.tap(find.text('Task').first);
    await settle(tester);
    final title = find.widgetWithText(TextField, 'Title');
    await tester.enterText(title, 'Integration task');
    await tester.pump();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Today'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await settle(tester);
    await settle(tester);

    // Today / Due soon
    expect(find.text('Integration task'), findsWidgets);
    // Tasks
    await tester.tap(find.text('Tasks').last);
    await settle(tester);
    await settle(tester);
    expect(find.text('Integration task'), findsWidgets);
  });
}
