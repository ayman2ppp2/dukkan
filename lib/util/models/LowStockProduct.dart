import 'package:dukkan/util/models/Product.dart';

class LowStockProduct {
  final Product product;
  final double percentRemaining;
  final int currentStock;
  final int soldLast30Days;

  LowStockProduct({
    required this.product,
    required this.percentRemaining,
    required this.currentStock,
    required this.soldLast30Days,
  });
}