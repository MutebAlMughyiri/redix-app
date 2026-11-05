const _easternDigits = '٠١٢٣٤٥٦٧٨٩';

/// A number as a person types it: no separators, and as few decimals as it needs, at most two, so 15 is 15 and 7.5 is 7.5.
String formatPlain(double number) => number.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');

/// An amount in riyals as the app shows it: two decimals, thousands separators, and a negative in brackets, as 1,234.56 and (120.40) (NFR-04). It rounds half up from the four decimals the API keeps (BR-13), so 2,955.385 shows 2,955.39, though the double nearest it lies just below.
String formatMoney(double amount) {
  final tenThousandths = BigInt.parse(amount.abs().toStringAsFixed(4).replaceFirst('.', ''));
  final digits = ((tenThousandths + BigInt.from(50)) ~/ BigInt.from(100)).toString().padLeft(3, '0');
  final whole = digits.substring(0, digits.length - 2).replaceAllMapped(RegExp(r'\B(?=(\d{3})+$)'), (_) => ',');
  final money = '$whole.${digits.substring(digits.length - 2)}';
  return amount < 0 ? '($money)' : money;
}

/// A partner's share as a percentage, with the ten decimals the current statement prints (BR-28).
String formatShare(double percent) => percent.toStringAsFixed(10);

/// What a person [typed], with any Arabic digits as Western ones, which is how the API keeps a number.
String westernDigits(String typed) => typed.replaceAllMapped(RegExp('[$_easternDigits]'), (digit) => _easternDigits.indexOf(digit[0]!).toString());

/// The number in what a person [typed], in Arabic or Western digits and with any thousands separators; not a number ([double.nan]) when it holds none.
double parseNumber(String typed) => double.tryParse(westernDigits(typed.trim().replaceAll(',', '').replaceAll('٬', '').replaceAll('٫', '.'))) ?? double.nan;
