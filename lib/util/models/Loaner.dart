import 'package:hive/hive.dart';
import 'package:isar/isar.dart';

part '../adapters/Loaner.g.dart';
part 'Loaner.g.dart';

// @HiveType(typeId: 3)
@collection
class Loaner {
  Loaner({
    required this.name,
    // required this.ID,
    required this.phoneNumber,
    required this.location,
    required this.lastPayment,
    // required this.lastPaymentDate,
    required this.loanedAmount,
  });
  Loaner.named({
    required this.name,
    required this.ID,
    required this.phoneNumber,
    required this.location,
    required this.lastPaymentTemp,
    required this.lastPaymentDate,
    required this.loanedAmount,
  });

  // @ignore
  // String? oldId;

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

  double? loanedAmount;

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
    // {
    //   (map['lastPayment'] as DateTime).toIso8601String(),
    //   map['lastPaymentDate'] as double
    // } as Map<String, double>?;
    // // lastPaymentDate = map['lastPaymentDate'];
    loanedAmount = map['loanedAmount'];
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
      'loanedAmount': this.loanedAmount,
    };
  }

  int convertId(id) {
    if (id == -3750763034362895579) {
      return 0;
    } else {
      int largeNumber = id;

      // Convert to a 4-digit number using modulo
      int fourDigitNumber = (largeNumber % 10000).toInt();
      return fourDigitNumber;
      // print('4-digit number: $fourDigitNumber');
    }
  }
}

@Embedded()
class EmbeddedMap {
  String? key;
  String? value;
  double? remaining;
  EmbeddedMap();
  EmbeddedMap.named({required this.key, required this.value});
}
