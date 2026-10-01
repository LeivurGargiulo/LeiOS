import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

void main() {
  testWidgets('signed-in user lands on Today / Check-in (compact)', (tester) async {
    setScreen(tester, 360, 800);
    final h = await openHarness(tester);
    await pumpApp(tester, h);
    expect(find.text('How are you today?'), findsOneWidget);
    expect(find.text('Check-in'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('signed-out user is sent to sign in', (tester) async {
    setScreen(tester, 360, 800);
    final h = await openHarness(tester, signedIn: false);
    await pumpApp(tester, h);
    expect(find.text('Sign in'), findsWidgets);
    expect(find.byType(NavigationBar), findsNothing);
  });
}
