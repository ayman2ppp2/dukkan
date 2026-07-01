import 'package:isar_community/isar.dart';

part 'Loaner.g.dart';

@collection
class Loaner {
  Loaner({
    required this.name,
    required this.phoneNumber,
    required this.location,
    required this.lastPayment,
    required this.balance,
  });
  Loaner.named({
    required this.name,
    required this.ID,
    required this.phoneNumber,
    required this.location,
    required this.lastPaymentTemp,
    required this.lastPaymentDate,
    required this.balance,
  });

  @Index(type: IndexType.value)
  String? name;

  Id ID = Isar.autoIncrement;

  String? phoneNumber;

  String? location;

  List<EmbeddedMap>? lastPayment;
  @ignore
  double? lastPaymentTemp;

  @ignore
  DateTime? lastPaymentDate;

  @Name("loanedAmount")
  double? balance;

  DateTime? zeroingDate;

  Loaner.fromMap({required Map map}) {
    name = map['name'];
    phoneNumber = map['phoneNumber'];
    location = map['location'];
    lastPayment = [
      EmbeddedMap.named(
          key: (map['lastPaymentDate'] as DateTime).toIso8601String(),
          value: (map['lastPayment'] as double).toString())
    ];
    balance = (map['loanedAmount'] ?? map['balance']) as double?;
    ID = convertId(map['ID']).toInt();
  }
  Map<String, dynamic> toMap() {
    return {
      'ID': this.ID,
      'name': this.name,
      'phoneNumber': this.phoneNumber,
      'location': this.location,
      'lastPayment': this.lastPaymentTemp,
      'lastPaymentDate': this.lastPaymentDate,
      'balance': this.balance,
      'zeroingDate': this.zeroingDate,
    };
  }

  int convertId(id) {
    if (id == -3750763034362895579) {
      return 0;
    } else {
      int largeNumber = id;
      int fourDigitNumber = (largeNumber % 10000).toInt();
      return fourDigitNumber;
    }
  }
}

@Embedded()
class EmbeddedMap {
  String? key;
  String? value;
  double? remaining;
  String? type; // "sale" | "payment" | "withdraw"
  String? notes;
  EmbeddedMap();
  EmbeddedMap.named({required this.key, required this.value});
}
