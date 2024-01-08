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
    return Log(
      price: fields[1] as double,
      profit: fields[2] as double,
      date: fields[3] as DateTime,
      products: (fields[0] as List).cast<Product>(),
      discount: fields[4] == null ? 0 : fields[4] as double,
      loaned: fields[5] == null ? false : fields[5] as bool,
      loanerID: fields[6] == null ? '' : fields[6] as String,
    );
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
