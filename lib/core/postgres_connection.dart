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
      print('Connected to PostgreSQL database.');
    } catch (e) {
      print('Failed to connect to PostgreSQL database: $e');
    }
  }

  Future<List<Map<String, dynamic>>> query(String sql,
      {Map<String, dynamic>? substitutionValues}) async {
    try {
      return await conn.mappedResultsQuery(
        sql,
        substitutionValues: substitutionValues,
      );
    } catch (e) {
      print('Error executing query: $e');
      return [];
    }
  }

  Future<void> close() async {
    try {
      await conn.close();
      print('PostgreSQL connection closed.');
    } catch (e) {
      print('Error closing PostgreSQL connection: $e');
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
      print('Product inserted successfully.');
    } catch (e) {
      print('Error inserting product: $e');
    }
  }
}
