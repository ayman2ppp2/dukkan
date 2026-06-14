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
    options.tracesSampleRate = 0;
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

  static void warning(String message, {Map<String, Object?>? data}) {
    _localLog('warning', message, data: data);
    _breadcrumb(message, level: SentryLevel.warning, data: data);
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
