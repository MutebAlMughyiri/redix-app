const _easternDigits = '٠١٢٣٤٥٦٧٨٩';

/// A number as a person types it: no separators, and as few decimals as it needs, at most two, so 15 is 15 and 7.5 is 7.5.
String formatPlain(double number) => number.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');

/// An amount in riyals as the app shows it: two decimals, thousands separators, and a negative in brackets, as 1,234.56 and (120.40) (NFR-04).
String formatMoney(double amount) {
  final digits = amount.abs().toStringAsFixed(2);
  final whole = digits.substring(0, digits.length - 3).replaceAllMapped(RegExp(r'\B(?=(\d{3})+$)'), (_) => ',');
  final money = '$whole${digits.substring(digits.length - 3)}';
  return amount < 0 ? '($money)' : money;
}

/// The number in what a person [typed], in Arabic or Western digits and with any thousands separators; not a number ([double.nan]) when it holds none.
double parseNumber(String typed) {
  final western = typed.trim().replaceAll(',', '').replaceAll('٬', '').replaceAll('٫', '.').replaceAllMapped(RegExp('[$_easternDigits]'), (digit) => _easternDigits.indexOf(digit[0]!).toString());
  return double.tryParse(western) ?? double.nan;
}
