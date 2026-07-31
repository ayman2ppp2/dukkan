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

class LoanerComparison {
  final String name;
  final double loanedAmount;
  final double currentValue;
  LoanerComparison({
    required this.name,
    required this.loanedAmount,
    required this.currentValue,
  });
}

class YearlyTotals {
  final double yearlyProfit;
  final double yearlySales;
  final double yearlyInflation;
  YearlyTotals({
    required this.yearlyProfit,
    required this.yearlySales,
    this.yearlyInflation = 0,
  });
  double get profitPercent {
    if (yearlySales == 0) return 0;
    return (yearlyProfit / (yearlySales - yearlyProfit)) * 100;
  }
}
