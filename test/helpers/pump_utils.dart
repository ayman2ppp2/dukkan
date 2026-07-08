import 'package:flutter_test/flutter_test.dart';

Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final end = DateTime.now().add(timeout);
  do {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  } while (DateTime.now().isBefore(end));
  throw StateError('Timed out waiting for $finder');
}

Future<void> pumpUntilIdle(WidgetTester tester) async {
  for (var i = 0; i < 50; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}
