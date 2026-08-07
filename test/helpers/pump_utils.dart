import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sets a phone-like tall surface (the default 800x600 test surface breaks
/// dialogs whose layouts assume a taller screen). The width is kept below 720
/// so the inventory grid renders 3 wide columns instead of 4 narrow ones.
void usePhoneScreen(WidgetTester tester, {Size size = const Size(700, 1300)}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// Pumps and lets the real event loop turn so real-async work (Isar FFI)
/// can complete inside widget tests.
Future<void> pumpRealAsync(WidgetTester tester,
    [Duration delay = const Duration(milliseconds: 15)]) async {
  await tester.runAsync(() => Future<void>.delayed(delay));
  await tester.pump();
}

Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final end = DateTime.now().add(timeout);
  do {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
    await pumpRealAsync(tester);
    if (finder.evaluate().isNotEmpty) return;
  } while (DateTime.now().isBefore(end));
  throw StateError('Timed out waiting for $finder');
}

/// Pumps (interleaving real-async turns) until [check] returns true.
Future<void> pumpUntilDb(
  WidgetTester tester,
  Future<bool> Function() check, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final end = DateTime.now().add(timeout);
  do {
    await tester.pump(const Duration(milliseconds: 100));
    var ok = false;
    await tester.runAsync(() async {
      try {
        ok = await check();
      } catch (_) {
        ok = false;
      }
    });
    if (ok) return;
  } while (DateTime.now().isBefore(end));
  throw StateError('Timed out waiting for DB condition');
}

Future<void> pumpUntilIdle(WidgetTester tester) async {
  for (var i = 0; i < 50; i++) {
    await tester.pump(const Duration(milliseconds: 50));
    await pumpRealAsync(tester);
  }
}
