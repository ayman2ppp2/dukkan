import 'package:dukkan/utils/json_values.dart';
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
    buyPrice = doubleOrNull(map['buyPrice']);
    sellPrice = doubleOrNull(map['sellPrice']);
    date = dateTimeOrNull(map['date']);
  }

  Map<String, dynamic> toMap() {
    return {
      'buyPrice': buyPrice,
      'sellPrice': sellPrice,
      'date': date?.toIso8601String(),
    };
  }
}
