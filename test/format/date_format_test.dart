import 'package:flutter_test/flutter_test.dart';
import 'package:redix/format/date_format.dart';

void main() {
  test('a date shows as dd.MM.yyyy, with two digits for the day and the month', () {
    expect(formatDate(DateTime(2026, 3, 1)), '01.03.2026');
    expect(formatDate(DateTime(2026, 11, 25)), '25.11.2026');
  });
}
