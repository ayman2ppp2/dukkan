import 'dart:convert';

import 'package:dukkan/core/observability.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Records envelopes instead of sending them over the network, so this test
/// exercises the real pipeline — `AppLogger` → `Sentry.logger` →
/// `beforeSendLog` → buffer → envelope — without a DSN or network access.
class _CapturingTransport implements Transport {
  final envelopes = <SentryEnvelope>[];

  @override
  Future<SentryId?> send(SentryEnvelope envelope) async {
    envelopes.add(envelope);
    return SentryId.newId();
  }

  /// Every log record that would have been uploaded, decoded. Telemetry
  /// payloads are `{"items": [<log>, ...]}`.
  Future<List<Map<String, dynamic>>> logs() async {
    final payloads = <Map<String, dynamic>>[];
    for (final envelope in envelopes) {
      for (final item in envelope.items) {
        if (item.header.type != 'log') continue;
        final decoded = jsonDecode(utf8.decode(await item.dataFactory()))
            as Map<String, dynamic>;
        final items = decoded['items'] as List<dynamic>;
        payloads.addAll(items.cast<Map<String, dynamic>>());
      }
    }
    return payloads;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('AppLogger ships structured logs through the real SDK pipeline',
      () async {
    final transport = _CapturingTransport();

    await Sentry.init((options) {
      AppLogger.configureSentry(options);
      options
        // configureSentry pins the compile-time DSN (absent in tests); this
        // test only needs the hub to consider itself live, and the transport
        // below keeps every byte on this machine.
        ..dsn = 'https://public@o0.ingest.sentry.io/1'
        ..transport = transport
        ..environment = 'test'
        ..release = 'test';
    });

    AppLogger.info('Checkout completed', data: {
      'area': 'checkout',
      'itemCount': 3,
      'total': 1250.5,
      'paid': true,
      // Key contains 'loan', so it must be redacted before it leaves the app.
      'loaned': false,
    });
    AppLogger.debug('Barcode scanned', data: {'area': 'sale.barcode_scan'});
    // Dropped by filterLog, the log-side twin of the beforeSend filter.
    await AppLogger.warning('Insufficient stock for "Sugar"');

    // Emission is fire-and-forget; give the pipeline time to buffer before
    // close() flushes it (buffer flush timeout is 5s, close is immediate).
    await Future<void>.delayed(const Duration(milliseconds: 250));
    await Sentry.close();

    final logs = await transport.logs();
    expect(logs, hasLength(2),
        reason: 'the validation message must be filtered out');

    final checkout = logs.firstWhere((l) => l['body'] == 'Checkout completed');
    expect(checkout['level'], 'info');
    final attributes = checkout['attributes'] as Map<String, dynamic>;
    expect(attributes['area']!['value'], 'checkout');
    expect(attributes['itemCount']!['value'], 3);
    expect(attributes['total']!['value'], 1250.5);
    expect(attributes['paid']!['value'], true);
    expect(attributes['loaned']!['value'], '<redacted>');
    // Values keep their types instead of being flattened into strings.
    expect(attributes['itemCount']!['type'], 'integer');
    expect(attributes['total']!['type'], 'double');
    expect(attributes['paid']!['type'], 'boolean');

    expect(logs.any((l) => l['body'] == 'Barcode scanned'), isTrue);
    expect(logs.any((l) => l['body']!.contains('Insufficient stock')), isFalse);

    // Everything Sentry ingests must be plain JSON.
    expect(() => jsonEncode(logs), returnsNormally);
  });

  test('AppLogger stays silent when the SDK is not initialised', () async {
    // Close first so the assertion does not depend on test ordering.
    await Sentry.close();
    expect(Sentry.isEnabled, isFalse);

    expect(() => AppLogger.info('no live SDK, no log'), returnsNormally);
  });
}
