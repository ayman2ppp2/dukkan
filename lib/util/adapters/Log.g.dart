// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../models/Log.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LogAdapter extends TypeAdapter<Log> {
  @override
  final int typeId = 10;

  @override
  Log read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    // Isar isar = Isar.getInstance('isarInstance')!;

    // IsarLinks<Product> temp = IsarLinks<Product>();

    List<Product> temp2 = (fields[0] as List).cast<Product>();
    var temp = temp2.map((e) => e.toEmbedded()).toList();
    // temp.addAll(temp2);

    var temp3 = Log.named1(
      price: fields[1] as double,
      profit: fields[2] as double,
      date: fields[3] as DateTime,
      products: temp,
      discount: fields[4] == null ? 0 : fields[4] as double,
      loaned: fields[5] == null ? false : fields[5] as bool,
      loanerID: fields[6] == null ? 0 : fastHash(fields[6] as String),
    );
    // temp3.products.addAll(temp);
    return temp3;
  }

  int fastHash(String string) {
    var hash = 0xcbf29ce484222325;

    var i = 0;
    while (i < string.length) {
      final codeUnit = string.codeUnitAt(i++);
      hash ^= codeUnit >> 8;
      hash *= 0x100000001b3;
      hash ^= codeUnit & 0xFF;
      hash *= 0x100000001b3;
    }

    return hash;
  }

  @override
  void write(BinaryWriter writer, Log obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.products)
      ..writeByte(1)
      ..write(obj.price)
      ..writeByte(2)
      ..write(obj.profit)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.discount)
      ..writeByte(5)
      ..write(obj.loaned)
      ..writeByte(6)
      ..write(obj.loanerID);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
