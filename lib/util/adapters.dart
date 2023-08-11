import 'package:dukkan/util/product.dart';
import 'package:hive/hive.dart';

import 'Log.dart';

class ProductAdapter extends TypeAdapter<Product> {
  @override
  Product read(BinaryReader reader) {
    return Product(
      name: reader.read(),
      ownerName: reader.read(),
      buyprice: reader.read(),
      sellprice: reader.read(),
      count: reader.read(),
      weightable: reader.read(),
      wholeUnit: reader.read(),
    );
  }

  @override
  int get typeId => 0;

  @override
  void write(BinaryWriter writer, Product obj) {
    writer.write(obj.name);
    writer.write(obj.ownerName);
    writer.write(obj.buyprice);
    writer.write(obj.sellprice);
    writer.write(obj.count);
    writer.write(obj.weightable);
    writer.write(obj.wholeUnit);
  }
}

class LogAdapter extends TypeAdapter<Log> {
  @override
  Log read(BinaryReader reader) {
    var price = reader.read();
    var profit = reader.read();
    var date = reader.read();
    var products = List<Product>.from(reader.read());
    return Log(price: price, profit: profit, date: date, products: products);
  }

  @override
  int get typeId => 1;

  @override
  void write(BinaryWriter writer, Log obj) {
    writer.write(obj.price);
    writer.write(obj.profit);
    writer.write(obj.date);
    writer.write(obj.products);
  }
}
