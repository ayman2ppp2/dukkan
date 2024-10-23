class ProdStats {
  final String name;
  final double count;
  final DateTime date;
  ProdStats({required this.name, required this.count, required this.date});
}

class SalesStats {
  @override
  String toString() {
    return '$date:$sales';
  }

  final DateTime date;
  final double sales;
  SalesStats({required this.date, required this.sales});
}
