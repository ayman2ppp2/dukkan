import 'package:isar_community/isar.dart';
part 'Emap.g.dart';

@embedded
class Emap {
  // Id id = Isar.autoIncrement;
  double? buyPrice;
  double? sellPrice;
  DateTime? date;
  Emap();

  Emap.fromMap({required Map map}) {
    buyPrice = map['buyPrice'];
    sellPrice = map['sellPrice'];
    date = map['date'] != null ? DateTime.parse(map['date'] as String) : null;
  }

  Map<String, dynamic> toMap() {
    return {
      'buyPrice': buyPrice,
      'sellPrice': sellPrice,
      'date': date?.toIso8601String(),
    };
  }
}
