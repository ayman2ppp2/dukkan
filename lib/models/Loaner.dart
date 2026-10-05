import 'package:dukkan/utils/json_values.dart';
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
    name = map['name'] as String?;
    phoneNumber = map['phoneNumber'] as String?;
    location = map['location'] as String?;
    lastPayment = [
      EmbeddedMap.named(
          key: dateTimeOrNull(map['lastPaymentDate'])?.toIso8601String(),
          value: doubleOrNull(map['lastPayment'])?.toString())
    ];
    balance = doubleOrNull(map['loanedAmount'] ?? map['balance']);
    final rawId = intValueOrNull(map['ID']);
    if (rawId != null) ID = convertId(rawId).toInt();
  }

  Map<String, dynamic> toMap() {
    return {
      'ID': this.ID,
      'name': this.name,
      'phoneNumber': this.phoneNumber,
      'location': this.location,
      'lastPayment': this.lastPaymentTemp,
      'lastPaymentDate': this.lastPaymentDate?.toIso8601String(),
      'balance': this.balance,
      'zeroingDate': this.zeroingDate?.toIso8601String(),
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
