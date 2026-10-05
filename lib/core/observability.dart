import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class ObservabilityConfig {
  static const dsn = String.fromEnvironment('SENTRY_DSN');
  static const environment = String.fromEnvironment(
    'SENTRY_ENVIRONMENT',
    defaultValue: 'production',
  );
  static const release = String.fromEnvironment('SENTRY_RELEASE');

  static bool get crashReportingEnabled => dsn.isNotEmpty;
}

class AppLogger {
  static bool _sentryStarted = false;

  static Future<void> bootstrap(Future<void> Function() appRunner) async {
    await _runGuarded(() async {
      WidgetsFlutterBinding.ensureInitialized();
      if (ObservabilityConfig.crashReportingEnabled) {
        await SentryFlutter.init(configureSentry);
        _sentryStarted = true;
      }
      _installGlobalErrorHandlers();
      await _breadcrumb('App started', level: SentryLevel.info, data: {
        'environment': ObservabilityConfig.environment,
        'release': ObservabilityConfig.release.isEmpty
            ? 'unknown'
            : ObservabilityConfig.release,
        'mode': kReleaseMode
            ? 'release'
            : kDebugMode
                ? 'debug'
                : 'profile',
      });
      await appRunner();
    });
  }

  /// Builds the options used at bootstrap. Takes the base [SentryOptions] so
  /// the same configuration is used by `SentryFlutter.init` and by tests that
  /// boot the pure-Dart SDK, and is kept public (and exercised by tests) so
  /// that signals like `enableLogs` cannot be dropped without a failing test.
  @visibleForTesting
  static void configureSentry(SentryOptions options) {
    options.dsn = ObservabilityConfig.dsn;
    options.environment = ObservabilityConfig.environment;
    if (ObservabilityConfig.release.isNotEmpty) {
      options.release = ObservabilityConfig.release;
    }
    options.debug = kDebugMode;
    options.sendDefaultPii = false;
    options.attachStacktrace = true;
    options.maxBreadcrumbs = 100;
    options.tracesSampleRate = 1.0;

    // Sentry Logs: a queryable stream of structured log lines, independent of
    // error events. `enableLogs` defaults to false (it is not read by the
    // 9.29.x SDK, which wires the logger unconditionally, but newer SDKs do
    // gate on it), so opt in explicitly. The actual log traffic comes from
    // AppLogger._sendLog calling Sentry.logger — without that, the Logs tab
    // stays empty no matter what this flag says.
    options.enableLogs = true;
    options.beforeSendLog = filterLog;

    // Filter out known validation errors that are not bugs.
    options.beforeSend = (event, hint) {
      final msg = event.exceptions?.firstOrNull?.value ?? '';
      if (_isValidationError(msg)) return null;
      return event;
    };
  }

  /// Last line of defense for a log before it leaves the device: drops the
  /// same non-bug validation messages [beforeSend] drops, then re-scrubs body
  /// and attributes so nothing sensitive reaches Sentry even when a call site
  /// hand-rolled its data instead of going through [sanitizeMap].
  ///
  /// [SentryAttribute.value] is immutable, so redacted entries are replaced
  /// rather than mutated. Runs after the SDK has attached its default
  /// attributes (environment, release, trace), which are left untouched.
  @visibleForTesting
  static SentryLog? filterLog(SentryLog log) {
    if (_isValidationError(log.body)) return null;
    log.body = sanitizeText(log.body);
    log.attributes = log.attributes.map((key, value) {
      if (_isSensitiveKey(key)) {
        return MapEntry(key, SentryAttribute.string('<redacted>'));
      }
      final raw = value.value;
      if (raw is String) {
        return MapEntry(key, SentryAttribute.string(sanitizeText(raw)));
      }
      return MapEntry(key, value);
    });
    return log;
  }

  /// Known validation messages that should not be reported to Sentry.
  static final _validationErrors = RegExp(
    r'Discount must be non-negative|'
    r'Discount cannot exceed checkout total|'
    r'Insufficient stock',
    caseSensitive: false,
  );

  static bool _isValidationError(String message) {
    return _validationErrors.hasMatch(message);
  }

  static Future<void> _runGuarded(Future<void> Function() appRunner) async {
    final guarded = runZonedGuarded<Future<void>>(
      () async {
        await appRunner();
      },
      (error, stackTrace) {
        unawaited(captureException(
          error,
          stackTrace: stackTrace,
          area: 'zone',
          fatal: true,
        ));
      },
    );
    if (guarded != null) {
      await guarded;
    }
  }

  static void _installGlobalErrorHandlers() {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      unawaited(captureException(
        details.exception,
        stackTrace: details.stack,
        area: 'flutter',
        fatal: true,
      ));
    };

    PlatformDispatcher.instance.onError = (error, stackTrace) {
      unawaited(captureException(
        error,
        stackTrace: stackTrace,
        area: 'platform',
        fatal: true,
      ));
      return true;
    };
  }

  static void debug(String message, {Map<String, Object?>? data}) {
    _localLog('debug', message, data: data);
    _breadcrumb(message, level: SentryLevel.debug, data: data);
  }

  static void info(String message, {Map<String, Object?>? data}) {
    _localLog('info', message, data: data);
    _breadcrumb(message, level: SentryLevel.info, data: data);
  }

  static Future<void> warning(String message,
      {Map<String, Object?>? data}) async {
    _localLog('warning', message, data: data);
    if (!ObservabilityConfig.crashReportingEnabled || !_sentryStarted) return;

    await _breadcrumb(message, level: SentryLevel.warning, data: data);
    await Sentry.captureMessage(
      sanitizeText(message),
      level: SentryLevel.warning,
    );
  }

  static Future<void> captureException(
    Object error, {
    StackTrace? stackTrace,
    String? area,
    Map<String, Object?>? data,
    bool fatal = false,
  }) async {
    final summary = sanitizeText(error.toString());

    _localLog(
      fatal ? 'fatal' : 'error',
      summary,
      data: {
        if (area != null) 'area': area,
        if (fatal) 'fatal': true,
        ...?data,
      },
      stackTrace: stackTrace,
    );

    if (!ObservabilityConfig.crashReportingEnabled || !_sentryStarted) return;

    await _breadcrumb(
      summary,
      level: fatal ? SentryLevel.fatal : SentryLevel.error,
      data: {
        if (area != null) 'area': area,
        if (fatal) 'fatal': true,
        ...?data,
      },
    );
    await Sentry.captureException(Exception(summary), stackTrace: stackTrace);
  }

  /// Emits [message] to the console and to Sentry Logs.
  ///
  /// Both sinks share one sanitization pass so the console and Sentry always
  /// show the same (scrubbed) text.
  static void _localLog(
    String level,
    String message, {
    Map<String, Object?>? data,
    StackTrace? stackTrace,
  }) {
    final safeMessage = sanitizeText(message);
    final safeData = sanitizeMap(data);
    _printToConsole(level, safeMessage, safeData, stackTrace);
    _sendLog(level, safeMessage, safeData);
  }

  static void _printToConsole(
    String level,
    String safeMessage,
    Map<String, dynamic> safeData,
    StackTrace? stackTrace,
  ) {
    // Debug chatter is dev-only; warnings and above always print.
    if (kReleaseMode && !_alwaysPrintedLevels.contains(level)) return;
    final dataText = safeData.isEmpty ? '' : ' $safeData';
    final stackText =
        !kReleaseMode && stackTrace != null ? '\n$stackTrace' : '';
    debugPrint('[${level.toUpperCase()}] $safeMessage$dataText$stackText');
  }

  static const _alwaysPrintedLevels = {'warning', 'error', 'fatal'};

  /// Forwards a message to Sentry Logs — the queryable log stream in the
  /// Sentry UI, as opposed to breadcrumbs which only ride along on errors.
  ///
  /// Level policy: `info`/`warning`/`error`/`fatal` always ship; `debug` only
  /// ships outside release, because in production debug lines are already
  /// captured as breadcrumbs and would otherwise double the volume.
  static void _sendLog(
    String level,
    String safeMessage,
    Map<String, dynamic> safeData,
  ) {
    // The hub reports whether the SDK is actually live (DSN present and init
    // completed), which is a stricter and more honest check than the bootstrap
    // flag — and lets tests exercise this path with a fake transport.
    if (!Sentry.isEnabled) return;
    if (level == 'debug' && kReleaseMode) return;

    final emit = switch (level) {
      'debug' => Sentry.logger.debug,
      'info' => Sentry.logger.info,
      'warning' => Sentry.logger.warn,
      'fatal' => Sentry.logger.fatal,
      _ => Sentry.logger.error,
    };
    emit(safeMessage, attributes: toLogAttributes(safeData));
  }

  /// Converts a sanitized data map into typed Sentry log attributes so values
  /// stay queryable (`total:>1000`) instead of being flattened into the
  /// message string. Nulls are dropped — Sentry has no null attribute type.
  @visibleForTesting
  static Map<String, SentryAttribute> toLogAttributes(
    Map<String, dynamic> data,
  ) {
    final attributes = <String, SentryAttribute>{};
    data.forEach((key, value) {
      if (value == null) return;
      if (value is String) {
        attributes[key] = SentryAttribute.string(value);
      } else if (value is bool) {
        attributes[key] = SentryAttribute.bool(value);
      } else if (value is int) {
        attributes[key] = SentryAttribute.int(value);
      } else if (value is double) {
        attributes[key] = SentryAttribute.double(value);
      } else {
        attributes[key] = SentryAttribute.string(value.toString());
      }
    });
    return attributes;
  }

  static Future<void> _breadcrumb(
    String message, {
    required SentryLevel level,
    Map<String, Object?>? data,
  }) async {
    if (!ObservabilityConfig.crashReportingEnabled || !_sentryStarted) return;
    await Sentry.addBreadcrumb(Breadcrumb(
      message: sanitizeText(message),
      category: 'app',
      level: level,
      data: sanitizeMap(data),
    ));
  }

  // ── User context ──────────────────────────────────────────────────────

  /// Associates the current Sentry session with a user.
  /// Call after successful login; PII is stripped by [sanitizeText].
  static void setUser(String? userId, {String? email, String? username}) {
    if (!ObservabilityConfig.crashReportingEnabled || !_sentryStarted) return;
    Sentry.configureScope((scope) {
      scope.setUser(SentryUser(
        id: userId,
        email: email != null ? sanitizeText(email) : null,
        username: username != null ? sanitizeText(username) : null,
      ));
    });
  }

  /// Clears the user from the Sentry scope. Call on sign-out.
  static void clearUser() {
    if (!ObservabilityConfig.crashReportingEnabled || !_sentryStarted) return;
    Sentry.configureScope((scope) {
      scope.setUser(null);
    });
  }

  // ── Tags ──────────────────────────────────────────────────────────────

  /// Sets a tag on the current Sentry scope. Tags are indexed and
  /// searchable in the Sentry UI (e.g. `area`, `feature`).
  static void setTag(String key, String value) {
    if (!ObservabilityConfig.crashReportingEnabled || !_sentryStarted) return;
    Sentry.configureScope((scope) {
      scope.setTag(key, value);
    });
  }

  // ── Performance monitoring ────────────────────────────────────────────

  /// Starts a Sentry transaction for performance monitoring.
  /// Returns the [SentrySpan] which must be passed to [finishTransaction].
  ///
  /// Example:
  /// ```dart
  /// final txn = AppLogger.startTransaction('checkout', 'checkout');
  /// try {
  ///   await _doCheckout();
  ///   txn.finish(status: SpanStatus.ok());
  /// } catch (e) {
  ///   txn.finish(status: SpanStatus.internalError());
  ///   rethrow;
  /// }
  /// ```
  static Future<ISentrySpan> startTransaction(
    String name,
    String operation, {
    Map<String, Object?>? data,
  }) async {
    if (!ObservabilityConfig.crashReportingEnabled || !_sentryStarted) {
      return _NoopSpan();
    }
    final transaction = Sentry.startTransaction(
      name,
      operation,
      bindToScope: true,
    );
    if (data != null) {
      for (final entry in sanitizeMap(data).entries) {
        transaction.setData(entry.key, entry.value);
      }
    }
    return transaction;
  }

  /// Convenience wrapper: runs [fn] inside a Sentry transaction,
  /// automatically finishing with [SpanStatus.ok] on success or
  /// [SpanStatus.internalError] on exception.
  ///
  /// Example:
  /// ```dart
  /// await AppLogger.trace('checkout', 'checkout', () async {
  ///   await _performCheckout();
  /// }, data: {'productCount': items.length});
  /// ```
  static Future<T> trace<T>(
    String name,
    String operation,
    Future<T> Function() fn, {
    Map<String, Object?>? data,
  }) async {
    final span = await startTransaction(name, operation, data: data);
    try {
      final result = await fn();
      span.finish(status: SpanStatus.ok());
      return result;
    } catch (e) {
      span.throwable = e;
      span.finish(status: SpanStatus.internalError());
      rethrow;
    }
  }

  /// Converts a log/breadcrumb data map into values that are safe to hand to
  /// Sentry's serializer: text is scrubbed, nested maps recursed, iterables
  /// collapsed, [DateTime]s become ISO-8601 strings, and anything else that
  /// isn't a JSON primitive falls back to `toString()` — a raw object here
  /// would make Sentry's `jsonEncode` throw
  /// `Converting object to an encodable object failed`.
  @visibleForTesting
  static Map<String, dynamic> sanitizeMap(Map<String, Object?>? data) {
    if (data == null || data.isEmpty) return {};
    return data.map((key, value) {
      if (_isSensitiveKey(key)) return MapEntry(key, '<redacted>');
      if (value is String) return MapEntry(key, sanitizeText(value));
      if (value is Map<String, Object?>) {
        return MapEntry(key, sanitizeMap(value));
      }
      if (value is Iterable) {
        return MapEntry(key, '<list:${value.length}>');
      }
      if (value is DateTime) return MapEntry(key, value.toIso8601String());
      if (value == null || value is num || value is bool) {
        return MapEntry(key, value);
      }
      return MapEntry(key, value.toString());
    });
  }

  @visibleForTesting
  static String sanitizeText(String value) {
    var output = value;
    output = output.replaceAll(
      RegExp(r'[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}', caseSensitive: false),
      '<email>',
    );
    output = output.replaceAll(
      RegExp(r'\b(?:\d{1,3}\.){3}\d{1,3}:\d{2,5}:\d{6}\b'),
      '<pairing-address>',
    );
    output = output.replaceAll(
      RegExp(
          r'\b(?:backup|isarInstance|isarinstance)[^\s]*\.isar(?:\.received)?\b'),
      '<backup-file>',
    );
    output = output.replaceAll(
      RegExp(r'''(?:[A-Za-z]:\\|/)[^\s'")]+'''),
      '<path>',
    );
    return output;
  }

  static bool _isSensitiveKey(String key) {
    final normalized = key.toLowerCase();
    return normalized.contains('password') ||
        normalized.contains('email') ||
        normalized.contains('userid') ||
        normalized.contains('user_id') ||
        normalized.contains('path') ||
        normalized.contains('file') ||
        normalized.contains('barcode') ||
        normalized.contains('phone') ||
        normalized.contains('location') ||
        normalized.contains('pairing') ||
        normalized.contains('code') ||
        normalized.contains('owner') ||
        normalized.contains('loan') ||
        normalized == 'product' ||
        normalized == 'products' ||
        normalized.contains('productname') ||
        normalized.contains('product_name');
  }
}

class UserSafeMessages {
  static const generic = 'تعذر إتمام العملية. حاول مرة أخرى.';
  static const loadFailed = 'تعذر تحميل البيانات. حاول مرة أخرى.';
  static const loginFailed = 'تعذر تسجيل الدخول. تحقق من البيانات أو الاتصال.';
  static const registerFailed = 'تعذر إنشاء الحساب. حاول مرة أخرى.';
  static const verificationFailed = 'تعذر التحقق. حاول مرة أخرى.';
  static const checkoutFailed = 'فشل تسجيل الفاتورة. حاول مرة أخرى.';
  static const backupFailed = 'تعذر إكمال النسخ الاحتياطي. حاول مرة أخرى.';
  static const restoreFailed = 'تعذر استعادة النسخة الاحتياطية. حاول مرة أخرى.';
  static const syncFailed =
      'فشلت المزامنة. تحقق من الشبكة وعنوان المشاركة ثم حاول مرة أخرى.';
  static const pdfFailed = 'تعذر إنشاء ملف PDF. حاول مرة أخرى.';
}

/// A no-op span returned when Sentry is not enabled, so callers
/// don't need null-checks.
class _NoopSpan implements ISentrySpan {
  @override
  Future<void> finish(
      {SpanStatus? status, DateTime? endTimestamp, dynamic hint}) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) {}
}
