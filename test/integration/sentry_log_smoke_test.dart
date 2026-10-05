import 'dart:convert';
import 'dart:io';

import 'package:dukkan/core/observability.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// POSTs the envelope the SDK produced straight to the DSN endpoint and
/// records the HTTP status, so a "green" run actually proves Sentry accepted
/// the bytes rather than merely proving we called the logger.
class _HttpTransport implements Transport {
  _HttpTransport(this.envelopeUrl, this.publicKey, this.options);

  final String envelopeUrl;
  final String publicKey;
  final SentryOptions options;
  final statuses = <Map<String, Object>>[];

  @override
  Future<SentryId?> send(SentryEnvelope envelope) async {
    envelope.header.sentAt = DateTime.now().toUtc();
    final bytes = await envelope
        .envelopeStream(options)
        .expand((chunk) => chunk)
        .toList();
    final types = envelope.items.map((i) => i.header.type).join(',');

    final client = HttpClient();
    final req = await client.postUrl(Uri.parse(envelopeUrl));
    req.headers
      ..contentType = ContentType.parse('application/x-sentry-envelope')
      ..set(
        'X-Sentry-Auth',
        'Sentry sentry_version=7, sentry_key=$publicKey',
      );
    req.add(bytes);
    final resp = await req.close();
    final body = await resp.transform(utf8.decoder).join();
    client.close(force: true);

    statuses.add({'types': types, 'status': resp.statusCode, 'body': body});
    // ignore: avoid_print
    print('ENVELOPE [$types] -> HTTP ${resp.statusCode} $body');
    return envelope.header.eventId;
  }
}

/// Splits `https://<key>@<host>/<project>` into the ingest URL and key.
({String envelopeUrl, String publicKey}) _dsnParts(String dsn) {
  final uri = Uri.parse(dsn);
  final project = uri.pathSegments.where((s) => s.isNotEmpty).last;
  final origin = '${uri.scheme}://${uri.host}'
      '${uri.hasPort ? ':${uri.port}' : ''}';
  return (
    envelopeUrl: '$origin/api/$project/envelope/',
    publicKey: uri.userInfo.split('@').first,
  );
}

/// One-shot live check against the real Sentry project: proves logs actually
/// leave this machine and land in the Logs tab (the unit/integration tests
/// above only prove the pipeline up to the transport).
///
/// Skipped unless `SENTRY_LOG_SMOKE_DSN` holds a project DSN; the test itself
/// asserts Sentry accepted the envelope. `SENTRY_LOG_SMOKE_ENV` optionally
/// overrides the environment (defaults to `log-smoke`).
///
/// ```sh
/// SENTRY_LOG_SMOKE_DSN=https://<key>@o0.ingest.sentry.io/<project> \
///   flutter test test/integration/sentry_log_smoke_test.dart
/// ```
///
/// The DSN is public — it ships inside every client build — so it only needs
/// the project's client key (Sentry → Settings → Projects → flutter →
/// Client Keys). Afterwards check Sentry → Explore → Logs filtered on
/// `area:smoke` (attribute filters work; the `environment:` filter does not
/// match logs — see TECHNICAL.md). Ingest to searchable takes ~1-2 minutes.
void main() {
  // Deliberately NO TestWidgetsFlutterBinding: it installs HttpOverrides that
  // fake every HttpClient request with a 400, which would silently prevent
  // this live check from ever reaching Sentry. Nothing here needs a binding.
  final dsn = Platform.environment['SENTRY_LOG_SMOKE_DSN'];

  test(
    'sends structured logs to the real Sentry project',
    () async {
      late _HttpTransport transport;

      await Sentry.init((options) {
        AppLogger.configureSentry(options);
        final parts = _dsnParts(dsn!);
        transport = _HttpTransport(parts.envelopeUrl, parts.publicKey, options);
        options
          ..dsn = dsn
          ..transport = transport
          // Override to an environment the org already knows (e.g. `master`)
          // when checking that environment filtering on the Logs tab works.
          ..environment =
              Platform.environment['SENTRY_LOG_SMOKE_ENV'] ?? 'log-smoke'
          ..release = 'log-smoke';
      });

      // Typed attributes must survive all the way to ingest.
      AppLogger.info('Smoke: checkout completed', data: {
        'area': 'smoke',
        'step': 'checkout',
        'itemCount': 3,
        'total': 1250.5,
        'paid': true,
      });

      // Proves filterLog scrubs PII but still ships the line: the email
      // becomes <email> and the sensitive key becomes <redacted>.
      AppLogger.info('Smoke: contact owner@example.com', data: {
        'area': 'smoke',
        'ownerName': 'Golden',
      });

      // Must NOT reach the transport — dropped by the validation filter.
      AppLogger.warning('Smoke: Insufficient stock for "Sugar"');

      // Buffer flush timeout is 5s; close() forces an immediate flush.
      await Future<void>.delayed(const Duration(milliseconds: 500));
      await Sentry.close();

      expect(transport.statuses, isNotEmpty,
          reason: 'the SDK never produced an envelope — nothing was sent');
      for (final s in transport.statuses) {
        expect(s['status'], 200,
            reason: 'ingest rejected the envelope: ${s['body']}');
        // A `client_report` item rides along when beforeSendLog dropped the
        // validation message — that discard is reported to Sentry, not lost.
        expect(s['types'], contains('log'));
      }
      expect(transport.statuses.length, 1,
          reason: 'both logs must be batched into one envelope, and the '
              'validation message must never reach it');
    },
    skip: dsn == null || dsn.isEmpty
        ? 'set SENTRY_LOG_SMOKE_DSN to a project DSN to run this live check'
        : false,
  );
}
