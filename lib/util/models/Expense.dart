import 'package:isar/isar.dart';
part 'Expense.g.dart';

@Collection()
class Expense {
  Expense();
  Expense.named(
      {required this.name,
      required this.amount,
      required this.period,
      required this.payDate,
      required this.lastCalculationDate,
      required this.fixed});

  @Index(
    unique: true,
    replace: true,
  )
  Id ID = Isar.autoIncrement;
  String? name;
  double? amount;
  @Index()
  int? period;
  int? payDate;
  @Index()
  bool? fixed;
  DateTime? lastCalculationDate = DateTime.now();
}
