double getWholeUnitNumber(String wholeUnit) {
  switch (wholeUnit) {
    case 'كيلو':
      return 1000;
    case 'رطل':
      return 450;
    case 'تمنة':
      return 850;
    case '':
      return 1;
    default:
      return double.tryParse(wholeUnit) ?? 0;
  }
}

double padd({required String original, required String wholeUnit}) {
  return double.parse(original) / getWholeUnitNumber(wholeUnit);
}

double unPadd({required String padded, required String wholeUnit}) {
  return (double.tryParse(padded) ?? 0) * getWholeUnitNumber(wholeUnit);
}
