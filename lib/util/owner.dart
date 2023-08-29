class Owner {
  String ownerName;
  DateTime lastPaymentDate;
  double lastPayment;
  double totalPayed;
  double dueMoney;
  Owner({
    required this.ownerName,
    required this.lastPaymentDate,
    required this.lastPayment,
    required this.totalPayed,
    required this.dueMoney,
  });
}
