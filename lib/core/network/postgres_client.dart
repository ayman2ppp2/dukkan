import 'package:dukkan/core/observability.dart';
import 'package:postgres/postgres.dart';

class PostgresConnection {
  late var conn;

  Future<void> connect() async {
    conn = await Connection.open(Endpoint(
      host: 'localhost',
      database: 'postgres',
      username: 'user',
      password: 'pass',
    ));

    try {
      await conn.open();
      AppLogger.info('PostgreSQL connected', data: {'area': 'postgres'});
    } catch (e, st) {
      await AppLogger.captureException(e,
          stackTrace: st, area: 'postgres.connect');
    }
  }

  Future<List<Map<String, dynamic>>> query(String sql,
      {Map<String, dynamic>? substitutionValues}) async {
    try {
      return await conn.mappedResultsQuery(
        sql,
        substitutionValues: substitutionValues,
      );
    } catch (e, st) {
      await AppLogger.captureException(e,
          stackTrace: st, area: 'postgres.query');
      return [];
    }
  }

  Future<void> close() async {
    try {
      await conn.close();
      AppLogger.info('PostgreSQL connection closed',
          data: {'area': 'postgres'});
    } catch (e, st) {
      await AppLogger.captureException(e,
          stackTrace: st, area: 'postgres.close');
    }
  }

  Future<void> insertProduct({
    required String name,
    required String ownerName,
    required double buyPrice,
    required double sellPrice,
    required String barcode,
    required int count,
    required bool weightable,
    required String wholeUnit,
    required bool offer,
    required double offerCount,
    required double offerPrice,
    required DateTime? endDate,
    required bool hot,
  }) async {
    try {
      await conn.query(
        '''
        INSERT INTO products (
          name, owner_name, buy_price, sell_price, barcode, count, weightable,
          whole_unit, offer, offer_count, offer_price, end_date, hot
        ) VALUES (
          @name, @ownerName, @buyPrice, @sellPrice, @barcode, @count, @weightable,
          @wholeUnit, @offer, @offerCount, @offerPrice, @endDate, @hot
        )
        ''',
        substitutionValues: {
          'name': name,
          'ownerName': ownerName,
          'buyPrice': buyPrice,
          'sellPrice': sellPrice,
          'barcode': barcode,
          'count': count,
          'weightable': weightable,
          'wholeUnit': wholeUnit,
          'offer': offer,
          'offerCount': offerCount,
          'offerPrice': offerPrice,
          'endDate': endDate?.toIso8601String(),
          'hot': hot,
        },
      );
      AppLogger.info('Product inserted in PostgreSQL',
          data: {'area': 'postgres.insert_product'});
    } catch (e, st) {
      await AppLogger.captureException(e,
          stackTrace: st, area: 'postgres.insert_product');
    }
  }
}
