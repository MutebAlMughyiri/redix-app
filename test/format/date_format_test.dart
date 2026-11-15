import 'package:flutter_test/flutter_test.dart';
import 'package:redix/format/date_format.dart';

void main() {
  test('a date shows as dd.MM.yyyy, with two digits for the day and the month', () {
    expect(formatDate(DateTime(2026, 3, 1)), '01.03.2026');
    expect(formatDate(DateTime(2026, 11, 25)), '25.11.2026');
  });

  test('a moment the API sends in UTC is the same moment in the phone\'s own time, so its date and hour are the phone\'s', () {
    final moment = momentOf('2026-11-15T22:30:00Z');

    expect(moment.isUtc, isFalse);
    expect(moment.isAtSameMomentAs(DateTime.utc(2026, 11, 15, 22, 30)), isTrue);
    expect(formatTime(moment), formatTime(DateTime.utc(2026, 11, 15, 22, 30).toLocal()));
  });
}
