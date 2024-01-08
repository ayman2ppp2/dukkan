import 'package:hive/hive.dart';
part '../adapters/Owner.g.dart';

@HiveType(typeId: 4)
class Owner {
  @HiveField(0)
  late String ownerName;
  @HiveField(1)
  late DateTime lastPaymentDate;
  @HiveField(2)
  late double lastPayment;
  @HiveField(3)
  late double totalPayed;
  @HiveField(4)
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
