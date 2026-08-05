// One-time external fact-check for the loaner comparison chart.
//
// Recomputes each owing loaner's loanedAmount and currentValue directly from
// the real Isar database (using an independent manual walk of the debt
// window) and cross-checks the result against computeLoanerComparison, the
// exact function that feeds the chart.
//
// Hot products are not tracked in the product catalog (no reliable buy price),
// so they are excluded from both sides of the chart. Their sell value is
// reported separately so a loaner's balance can be reconciled:
//
//   tracked loaned (chart) + hot = balance
//
// Run it on demand against the real data:
//
//   DUKKAN_DB_DIR=/path/to/db/folder \
//     flutter test factcheck/fact_check_test.dart
//
// The folder must contain `isarInstance.isar`. If DUKKAN_DB_DIR is unset the
// check tries common local locations and prints usage otherwise.
//
// The database is copied to a temp dir before opening, so real data is never
// touched and the check works while the app is running.
// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'dart:io';

import 'package:dukkan/data/stats/jobs.dart'
    show computeLoanerComparison, hotSellValue, logLoanedValue;
import 'package:dukkan/models/Expense.dart';
import 'package:dukkan/models/Log.dart';
import 'package:dukkan/models/Loaner.dart';
import 'package:dukkan/models/Owner.dart';
import 'package:dukkan/models/Product.dart';
import 'package:dukkan/models/prodStats.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:isar_community/isar.dart';

const _dbFileName = 'isarInstance.isar';
final _nf = NumberFormat('#,##0.###');
final _df = DateFormat('yyyy-MM-dd');

class _LineCheck {
  final Log log;
  final double price;
  final double hot;
  final double recomputed;
  final double trackedAmount;
  final double hotAmount;
  final double currentValue;
  final double fraction;
  final bool boundary;

  _LineCheck({
    required this.log,
    required this.price,
    required this.hot,
    required this.recomputed,
    required this.trackedAmount,
    required this.hotAmount,
    required this.currentValue,
    required this.fraction,
    required this.boundary,
  });

  bool get priceDiffers => (price + hot - recomputed).abs() > 0.01;
}

class _LoanerCheck {
  final String name;
  final Id id;
  final double balance;
  final List<_LineCheck> lines;
  final double trackedAmount;
  final double hotAmount;
  final double currentValue;

  _LoanerCheck({
    required this.name,
    required this.id,
    required this.balance,
    required this.lines,
    required this.trackedAmount,
    required this.hotAmount,
    required this.currentValue,
  });
}

bool _feq(double a, double b, {double tol = 0.01}) => (a - b).abs() <= tol;

double _currentValue(Log log, Map<int, Product> productMap) {
  double value = 0;
  for (final ep in log.products) {
    if (ep.hot == true) continue;
    final count = ep.count ?? 0;
    final buyPrice = (ep.productId != null && ep.productId! > 0)
        ? (productMap[ep.productId]?.buyprice ?? (ep.buyPrice ?? 0))
        : (ep.buyPrice ?? 0);
    value += buyPrice * count;
  }
  return value;
}

double _recomputePrice(Log log) {
  final sum = log.products.fold<double>(
    0,
    (total, ep) => total + ((ep.sellPrice ?? 0) * (ep.count ?? 0)),
  );
  return sum - log.discount;
}

_LoanerCheck _manualWalk(
  Loaner loaner,
  List<Log> logs,
  Map<int, Product> productMap,
) {
  final sorted = [...logs]..sort((a, b) => b.date.compareTo(a.date));
  final lines = <_LineCheck>[];
  double tracked = 0;
  double hot = 0;
  double current = 0;
  var remaining = loaner.balance ?? 0;

  for (final log in sorted) {
    final price = log.price;
    final hotValue = hotSellValue(log);
    final value = logLoanedValue(log);
    final currentValue = _currentValue(log, productMap);
    final recomputed = _recomputePrice(log);

    if (value <= 0) {
      continue;
    }

    if (remaining <= value) {
      final fraction = remaining / value;
      lines.add(_LineCheck(
        log: log,
        price: price,
        hot: hotValue,
        recomputed: recomputed,
        trackedAmount: price * fraction,
        hotAmount: hotValue * fraction,
        currentValue: currentValue * fraction,
        fraction: fraction,
        boundary: true,
      ));
      tracked += price * fraction;
      hot += hotValue * fraction;
      current += currentValue * fraction;
      break;
    }

    lines.add(_LineCheck(
      log: log,
      price: price,
      hot: hotValue,
      recomputed: recomputed,
      trackedAmount: price,
      hotAmount: hotValue,
      currentValue: currentValue,
      fraction: 1,
      boundary: false,
    ));
    tracked += price;
    hot += hotValue;
    current += currentValue;
    remaining -= value;
  }

  return _LoanerCheck(
    name: loaner.name ?? 'Unknown',
    id: loaner.ID,
    balance: loaner.balance ?? 0,
    lines: lines,
    trackedAmount: tracked,
    hotAmount: hot,
    currentValue: current,
  );
}

Directory? _resolveDbDir() {
  final fromEnv = Platform.environment['DUKKAN_DB_DIR'];
  if (fromEnv != null && fromEnv.isNotEmpty) {
    final dir = Directory(fromEnv);
    if (dir.existsSync() &&
        dir.listSync().any((e) => e is File && e.path.endsWith('.isar'))) {
      return dir;
    }
  }

  final home = Platform.environment['HOME'] ?? '';
  const candidates = [
    '/Documents',
    '/.local/share/dukkan',
    '/.local/share/com.golden.dukkan',
  ];
  for (final suffix in candidates) {
    final dir = Directory('$home$suffix');
    if (dir.existsSync() &&
        dir.listSync().any((e) => e is File && e.path.endsWith('.isar'))) {
      return dir;
    }
  }
  return null;
}

Future<void> _copyDir(Directory source, Directory target) async {
  await target.create(recursive: true);
  for (final entity in source.listSync()) {
    final name = entity.uri.pathSegments.last;
    final dest = '${target.path}/$name';
    if (entity is Directory) {
      await _copyDir(entity, Directory(dest));
    } else if (entity is File) {
      await entity.copy(dest);
    }
  }
}

Future<Directory> _copyDbToTemp(Directory source) async {
  final tmp = await Directory.systemTemp.createTemp('dukkan_factcheck_');
  await _copyDir(source, tmp);
  for (final entity in tmp.listSync(recursive: true)) {
    if (entity is! File) continue;
    final name = entity.uri.pathSegments.last;
    if (name.endsWith('.lock') ||
        name.endsWith('.tmp') ||
        name.endsWith('.wal') ||
        name.endsWith('.shm')) {
      await entity.delete();
    }
  }
  return tmp;
}

void _printUsage() {
  // ignore: avoid_print
  print('''
DUKKAN fact-check: no Isar database found.

Point the check at the real database folder (the one containing
'$_dbFileName') with the DUKKAN_DB_DIR environment variable:

  DUKKAN_DB_DIR=/path/to/db/folder flutter test factcheck/fact_check_test.dart

On Android the database lives in the app's files directory. Pull it with adb
(e.g. via `adb run-as com.golden.dukkan` on a debuggable build, or a full
device backup) and point DUKKAN_DB_DIR at the extracted folder.
''');
}

void _printReport(_LoanerCheck c, LoanerComparison? chart) {
  print('══════════════════════════════════════════════════════════════');
  print('${c.name}  (id ${c.id})');
  print('  balance (recorded):  ${_nf.format(c.balance)}');
  print('  debt window (newest -> oldest):');
  for (final line in c.lines) {
    final mark =
        line.boundary ? 'جزئي ${_nf.format(line.fraction)}' : 'full';
    print('    ${_df.format(line.log.date)}  '
        'tracked ${_nf.format(line.trackedAmount)}  '
        'hot ${_nf.format(line.hotAmount)}  '
        'current ${_nf.format(line.currentValue)}  [$mark]');
    if (line.priceDiffers) {
      print('      ⚠ stored tracked+hot ${_nf.format(line.price + line.hot)} '
          '!= Σ(sell×count)-discount ${_nf.format(line.recomputed)} '
          '(offer bundle? verify manually)');
    }
  }
  print('  ──');
  final sum = c.trackedAmount + c.hotAmount;
  final balanceOk = _feq(sum, c.balance, tol: 1.0);
  print('  Σ tracked (chart loanedAmount)  ${_nf.format(c.trackedAmount)}');
  print('  Σ hot (untracked, no buy price) ${_nf.format(c.hotAmount)}');
  print('  tracked + hot                   ${_nf.format(sum)}  '
      '==  balance ${_nf.format(c.balance)}  '
      '${balanceOk ? '✓' : '✗ MISMATCH (diff ${_nf.format(sum - c.balance)})'}');
  print('  Σ current                       ${_nf.format(c.currentValue)}');
  if (chart != null) {
    final ok = _feq(chart.loanedAmount, c.trackedAmount) &&
        _feq(chart.currentValue, c.currentValue);
    print('  chart     loaned ${_nf.format(chart.loanedAmount)}  '
        'current ${_nf.format(chart.currentValue)}  '
        '${ok ? '✓ matches' : '✗ DIFFERS'}');
  } else {
    print('  chart     NOT PRESENT (no owing logs or excluded)');
  }
}

void main() {
  test(
    'fact-check loaner comparison against the real database',
    () async {
      final source = _resolveDbDir();
      if (source == null) {
        _printUsage();
        markTestSkipped('No database found');
        return;
      }

      // ignore: avoid_print
      print('Using database folder: ${source.path}');

      if (!await File('libisar.so').exists()) {
        await Isar.initializeIsarCore(download: true);
      } else {
        await Isar.initializeIsarCore();
      }

      final tmp = await _copyDbToTemp(source);
      late final Isar isar;
      try {
        isar = await Isar.open(
          [LogSchema, ProductSchema, LoanerSchema, OwnerSchema, ExpenseSchema],
          directory: tmp.path,
          name: 'isarInstance',
        );

        final loaners = await isar.loaners.where().findAll();
        final products = await isar.products.where().findAll();
        final logs = await isar.logs
            .filter()
            .loanedEqualTo(true)
            .sortByDateDesc()
            .findAll();
        final productMap = <int, Product>{};
        for (final p in products) {
          productMap[p.id] = p;
        }

        final eligible =
            loaners.where((l) => (l.balance ?? 0) > 0).toList();
        if (eligible.isEmpty) {
          markTestSkipped('No loaners with a positive balance');
          return;
        }

        final checks = <_LoanerCheck>[];
        for (final loaner in eligible) {
          final loanerLogs =
              logs.where((log) => log.loanerID == loaner.ID).toList();
          checks.add(_manualWalk(loaner, loanerLogs, productMap));
        }

        final chart = computeLoanerComparison(
          loaners: eligible,
          loanedLogs: logs,
          productMap: productMap,
        );
        final chartByName = <String, LoanerComparison>{};
        for (final c in chart) {
          chartByName[c.name] = c;
        }

        // ignore: avoid_print
        print('Checking ${checks.length} loaner(s)...');
        final failures = <String>[];
        for (final check in checks) {
          final chartRes = chartByName[check.name];
          _printReport(check, chartRes);

          final sum = check.trackedAmount + check.hotAmount;
          if (!_feq(sum, check.balance, tol: 1.0)) {
            failures.add('${check.name}: tracked+hot '
                '${_nf.format(sum)} != balance ${_nf.format(check.balance)} '
                '(diff ${_nf.format(sum - check.balance)})');
          }
          if (chartRes == null) {
            final purelyHot = check.trackedAmount == 0 &&
                check.currentValue == 0 &&
                check.hotAmount > 0;
            if (purelyHot) {
              // ignore: avoid_print
              print('  chart     absent (entirely hot debt, no buy price) — '
                  'expected');
            } else {
              failures.add(
                  '${check.name}: missing from chart output (no owing logs?)');
            }
          } else {
            if (!_feq(chartRes.loanedAmount, check.trackedAmount)) {
              failures.add('${check.name}: chart loanedAmount '
                  '${_nf.format(chartRes.loanedAmount)} != manual tracked '
                  '${_nf.format(check.trackedAmount)}');
            }
            if (!_feq(chartRes.currentValue, check.currentValue)) {
              failures.add('${check.name}: chart currentValue '
                  '${_nf.format(chartRes.currentValue)} != manual '
                  '${_nf.format(check.currentValue)}');
            }
          }
        }

        if (failures.isNotEmpty) {
          fail('Fact-check FAILED:\n${failures.join('\n')}');
        }
        // ignore: avoid_print
        print('RESULT: all ${checks.length} loaner(s) PASS ✓');
      } finally {
        await isar.close();
        if (await tmp.exists()) {
          await tmp.delete(recursive: true);
        }
      }
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );
}
