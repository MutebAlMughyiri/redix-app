const _easternDigits = '٠١٢٣٤٥٦٧٨٩';

/// A percentage as the app shows it: as few decimals as it needs, at most two, so 15 is 15 and 7.5 is 7.5.
String formatPercent(double percent) => percent.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');

/// The number in what a person [typed], in Arabic or Western digits and with any thousands separators; not a number ([double.nan]) when it holds none.
double parseNumber(String typed) {
  final western = typed.trim().replaceAll(',', '').replaceAll('٬', '').replaceAll('٫', '.').replaceAllMapped(RegExp('[$_easternDigits]'), (digit) => _easternDigits.indexOf(digit[0]!).toString());
  return double.tryParse(western) ?? double.nan;
}
