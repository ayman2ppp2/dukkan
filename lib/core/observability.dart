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
        await SentryFlutter.init(_configureSentry);
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

  static void _configureSentry(SentryFlutterOptions options) {
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

    // Filter out known validation errors that are not bugs.
    options.beforeSend = (event, hint) {
      final msg = event.exceptions?.firstOrNull?.value ?? '';
      if (_isValidationError(msg)) return null;
      return event;
    };
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
    if (!kReleaseMode) {
      _localLog('debug', message, data: data);
    }
    _breadcrumb(message, level: SentryLevel.debug, data: data);
  }

  static void info(String message, {Map<String, Object?>? data}) {
    _localLog('info', message, data: data);
    _breadcrumb(message, level: SentryLevel.info, data: data);
  }

  static Future<void> warning(String message,
      {Map<String, Object?>? data}) async {
    _localLog('warning', message, data: data);
    final safeData = sanitizeMap(data);
    if (!ObservabilityConfig.crashReportingEnabled || !_sentryStarted) return;

    await _breadcrumb(message, level: SentryLevel.warning, data: safeData);
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
    final safeData = sanitizeMap({
      if (area != null) 'area': area,
      if (fatal) 'fatal': true,
      ...?data,
    });
    final summary = sanitizeText(error.toString());

    _localLog('error', summary, data: safeData, stackTrace: stackTrace);

    if (!ObservabilityConfig.crashReportingEnabled || !_sentryStarted) return;

    await _breadcrumb(
      summary,
      level: fatal ? SentryLevel.fatal : SentryLevel.error,
      data: safeData,
    );
    await Sentry.captureException(Exception(summary), stackTrace: stackTrace);
  }

  static void _localLog(
    String level,
    String message, {
    Map<String, Object?>? data,
    StackTrace? stackTrace,
  }) {
    if (kReleaseMode && level != 'error' && level != 'warning') return;
    final safeMessage = sanitizeText(message);
    final safeData = sanitizeMap(data);
    final dataText = safeData.isEmpty ? '' : ' $safeData';
    final stackText =
        !kReleaseMode && stackTrace != null ? '\n$stackTrace' : '';
    debugPrint('[${level.toUpperCase()}] $safeMessage$dataText$stackText');
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
      return MapEntry(key, value);
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
  Future<void> finish({SpanStatus? status, DateTime? endTimestamp, dynamic hint}) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) {}
}
