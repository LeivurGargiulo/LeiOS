import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leios/app/app.dart';
import 'package:leios/app/providers.dart';
import 'package:leios/core/sync/auth_service.dart';
import 'package:powersync/powersync.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/test_db.dart';

const testAuthUser = AuthUser(id: testUser, email: 'lei@example.com');

class Harness {
  Harness(this.db, this.prefs, this.auth);
  final PowerSyncDatabase db;
  final SharedPreferences prefs;
  final FakeAuthService auth;
}

/// Opens a temp DB + prefs (real async work, so it runs outside the fake-async zone).
Future<Harness> openHarness(WidgetTester tester, {bool signedIn = true}) async {
  late Harness h;
  await tester.runAsync(() async {
    SharedPreferences.setMockInitialValues({});
    h = Harness(await openTestDb(), await SharedPreferences.getInstance(), FakeAuthService(initial: signedIn ? testAuthUser : null));
  });
  addTearDown(() async {
    // Unmount first so no stream is watching the DB when it closes.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await h.db.close().timeout(const Duration(milliseconds: 300), onTimeout: () {});
    });
  });
  return h;
}

void setScreen(WidgetTester tester, double w, double h, {double textScale = 1.0}) {
  tester.view.physicalSize = Size(w, h);
  tester.view.devicePixelRatio = 1.0;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    tester.platformDispatcher.clearTextScaleFactorTestValue();
  });
}

Future<void> pumpApp(WidgetTester tester, Harness h) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [
      dbProvider.overrideWithValue(h.db),
      prefsProvider.overrideWithValue(h.prefs),
      authServiceProvider.overrideWithValue(h.auth),
      syncEnabledProvider.overrideWithValue(false),
    ],
    child: const LeiOSApp(),
  ));
  await settle(tester);
}

/// Lets streams + animations finish. DB streams need real time, so interleave runAsync.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}
