// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../models/Owner.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OwnerAdapter extends TypeAdapter<Owner> {
  @override
  final int typeId = 4;

  @override
  Owner read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Owner(
      ownerName: fields[0] as String,
      lastPaymentDate: fields[1] as DateTime,
      lastPayment: fields[2] as double,
      totalPayed: fields[3] as double,
      dueMoney: fields[4] as double,
    );
  }

  @override
  void write(BinaryWriter writer, Owner obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.ownerName)
      ..writeByte(1)
      ..write(obj.lastPaymentDate)
      ..writeByte(2)
      ..write(obj.lastPayment)
      ..writeByte(3)
      ..write(obj.totalPayed)
      ..writeByte(4)
      ..write(obj.dueMoney);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OwnerAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
