// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../models/Loaner.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LoanerAdapter extends TypeAdapter<Loaner> {
  @override
  final int typeId = 3;

  @override
  Loaner read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Loaner.named(
      name: fields[0] as String,
      ID: fastHash(fields[1] as String),
      phoneNumber: fields[2] as String,
      location: fields[3] as String,
      lastPaymentTemp: fields[4] as double,
      lastPaymentDate: fields[6] as DateTime,
      loanedAmount: fields[5] as double,
    );
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
  void write(BinaryWriter writer, Loaner obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.ID)
      ..writeByte(2)
      ..write(obj.phoneNumber)
      ..writeByte(3)
      ..write(obj.location)
      ..writeByte(4)
      ..write(obj.lastPayment)
      ..writeByte(5)
      ..write(obj.loanedAmount)
      ..writeByte(6)
      ..write(obj.lastPaymentDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoanerAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
