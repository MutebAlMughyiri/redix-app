import 'package:flutter_test/flutter_test.dart';
import 'package:redix/expenses/unit_split.dart';
import 'package:redix/projects/project.dart';

void main() {
  final units = [for (final (index, name) in ['الغربية', 'الشرقية', 'الشمالية'].indexed) Unit.fromJson({'id': 'unit-$index', 'name': name})];

  test('equal parts are to two decimals and the last takes what is left, so they make 100', () {
    expect(UnitSplit.equalParts(3), [33.33, 33.33, 33.34]);
    expect(UnitSplit.equalParts(2), [50, 50]);
    expect(UnitSplit.equalParts(0), isEmpty);
  });

  test('a unit with nothing typed takes no part', () {
    final split = UnitSplit()
      ..isSplit = true
      ..isEqual = false
      ..percents.addAll({'unit-0': '60', 'unit-2': '٤٠'});

    expect(split.toSend(units), [
      {'unitId': 'unit-0', 'percent': 60},
      {'unitId': 'unit-2', 'percent': 40},
    ]);
  });

  test('an entry being changed opens equal when its parts are the equal ones, and by percentage otherwise', () {
    final equal = UnitSplit()..take(units, [for (final (index, percent) in [33.33, 33.33, 33.34].indexed) {'unitId': 'unit-$index', 'percent': percent}]);
    final typed = UnitSplit()
      ..take(units, [
        {'unitId': 'unit-0', 'percent': 70},
        {'unitId': 'unit-1', 'percent': 30},
      ]);
    final none = UnitSplit()..take(units, const []);

    expect((equal.isSplit, equal.isEqual), (true, true));
    expect((typed.isSplit, typed.isEqual), (true, false));
    expect(typed.percents, {'unit-0': '70', 'unit-1': '30'});
    expect(none.isSplit, isFalse);
  });

  test('nothing is sent while it is not split', () {
    expect(UnitSplit().toSend(units), isEmpty);
  });
}
