import 'package:hive/hive.dart';

part '../adapters/Loaner.g.dart';

@HiveType(typeId: 3)
class Loaner {
  Loaner({
    required this.name,
    required this.ID,
    required this.phoneNumber,
    required this.location,
    required this.lastPayment,
    required this.lastPaymentDate,
    required this.loanedAmount,
  });
  @HiveField(0)
  String name;
  @HiveField(1)
  String ID;
  @HiveField(2)
  String phoneNumber;
  @HiveField(3)
  String location;
  @HiveField(4)
  double lastPayment;
  @HiveField(5)
  double loanedAmount;
  @HiveField(6)
  DateTime lastPaymentDate;
}
