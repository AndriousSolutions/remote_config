// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _location = '========================== widget_test.dart';

void main() {
  //
  /// Set up anything necessary before testing begins.
  /// Runs once before ALL tests or groups
  setUpAll(() async {
    // Ensure TestWidgetsFlutterBinding is explicitly initialized
    // ignore: unused_local_variable
    final TestWidgetsFlutterBinding binding =
        TestWidgetsFlutterBinding.ensureInitialized();
  });

  /// Runs after EACH test or group
  tearDown(() {});

  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    //
    final app = MyApp(key: UniqueKey());

    // Tells the tester to build a UI based on the widget tree passed to it
    await tester.pumpWidget(app);

    /// pumpAndSettle() waits for all animations to complete.
    await tester.pumpAndSettle(const Duration(seconds: 5));

    expect(hRemoteConfig, isNotNull);

    final lastTime = hRemoteConfig.lastFetchTime;

    await tester.tap(
        find.byKey(const Key('hRemoteConfigRefresh'), skipOffstage: false));

    await tester.pumpAndSettle();

    expect(lastTime.isBefore(hRemoteConfig.lastFetchTime), isTrue,
        reason: _location);
  });
}
