// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../models/Product.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProductAdapter extends TypeAdapter<Product> {
  @override
  final int typeId = 5;

  @override
  Product read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Product(
      name: fields[0] == null ? '' : fields[0] as String,
      ownerName: fields[1] == null ? '' : fields[1] as String,
      barcode: fields[4] == null ? '' : fields[4] as String,
      buyprice: fields[2] == null ? 0 : fields[2] as double,
      sellprice: fields[3] == null ? 0 : fields[3] as double,
      count: fields[5] == null ? 0 : fields[5] as int,
      weightable: fields[6] == null ? false : fields[6] as bool,
      wholeUnit: fields[7] == null ? '' : fields[7] as String,
      offer: fields[8] == null ? false : fields[8] as bool,
      offerCount: fields[9] == null ? 0 : fields[9] as double,
      offerPrice: fields[10] == null ? 0 : fields[10] as double,
      priceHistory: fields[11] == null
          ? {}
          : (fields[11] as Map).cast<DateTime, double>(),
      endDate: fields[12] as DateTime,
      hot: fields[13] == null ? false : fields[13] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Product obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.ownerName)
      ..writeByte(2)
      ..write(obj.buyprice)
      ..writeByte(3)
      ..write(obj.sellprice)
      ..writeByte(4)
      ..write(obj.barcode)
      ..writeByte(5)
      ..write(obj.count)
      ..writeByte(6)
      ..write(obj.weightable)
      ..writeByte(7)
      ..write(obj.wholeUnit)
      ..writeByte(8)
      ..write(obj.offer)
      ..writeByte(9)
      ..write(obj.offerCount)
      ..writeByte(10)
      ..write(obj.offerPrice)
      ..writeByte(11)
      ..write(obj.priceHistory)
      ..writeByte(12)
      ..write(obj.endDate)
      ..writeByte(13)
      ..write(obj.hot);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
