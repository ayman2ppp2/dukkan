import 'package:hive/hive.dart';
import 'package:isar/isar.dart';
part '../adapters/Owner.g.dart';
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
      'lastPaymentDate': lastPaymentDate,
      'lastPayment': lastPayment,
      'totalPayed': totalPayed,
      'dueMoney': dueMoney,
    };
  }

  Owner.fromJson({required Map<String, Object?> map}) {
    ownerName = map['ownerName'] as String;
    lastPaymentDate = map['lastPaymentDate'] as DateTime;
    lastPayment = map['lastPayment'] as double;
    totalPayed = map['totalPayed'] as double;
    dueMoney = map['dueMoney'] as double;
  }
}
