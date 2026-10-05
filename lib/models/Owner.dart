import 'package:dukkan/utils/json_values.dart';
import 'package:isar_community/isar.dart';

part 'Owner.g.dart';

@collection
class Owner {
  Id id = Isar.autoIncrement;
  @Index(type: IndexType.value)
  late String ownerName;

  late DateTime lastPaymentDate;

  late double lastPayment;

  late double totalPayed;

  late double dueMoney;
  Owner({
    required this.ownerName,
    required this.lastPaymentDate,
    required this.lastPayment,
    required this.totalPayed,
    required this.dueMoney,
  });
  Map<String, Object?> toJson() {
    return {
      'ownerName': ownerName,
      'lastPaymentDate': lastPaymentDate.toIso8601String(),
      'lastPayment': lastPayment,
      'totalPayed': totalPayed,
      'dueMoney': dueMoney,
    };
  }

  Owner.fromJson({required Map<String, Object?> map}) {
    ownerName = map['ownerName'] as String;
    // Non-nullable field: fall back to "now" rather than throwing when the
    // stored value is missing or unparsable (matches the creation default).
    lastPaymentDate = dateTimeOrNull(map['lastPaymentDate']) ?? DateTime.now();
    lastPayment = doubleOrNull(map['lastPayment']) ?? 0;
    totalPayed = doubleOrNull(map['totalPayed']) ?? 0;
    dueMoney = doubleOrNull(map['dueMoney']) ?? 0;
  }
}
