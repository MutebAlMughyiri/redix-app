import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/structure/column_label.dart';
import 'package:redix/structure/item_column.dart';

void main() {
  final renamed = ItemColumn.fromJson({
    'id': 'column-1',
    'key': 'product',
    'name': 'المادة',
    'dataType': 'text',
    'isCore': false,
    'isCustom': false,
    'isRequired': false,
    'showInReports': true,
    'options': <String>[],
  });

  Future<String> labelIn(WidgetTester tester, Locale locale, List<ItemColumn> columns, String key) async {
    var label = '';
    await tester.pumpWidget(
      Localizations(
        locale: locale,
        delegates: const [DefaultWidgetsLocalizations.delegate],
        child: Builder(
          builder: (context) {
            label = columnLabel(context, columns, key, 'the word');
            return const SizedBox();
          },
        ),
      ),
    );
    return label;
  }

  testWidgets('in Arabic a built-in field carries the name its column was renamed to', (tester) async {
    expect(await labelIn(tester, const Locale('ar'), [renamed], 'product'), 'المادة');
  });

  testWidgets('in English it keeps its own word, because a column is named in one language', (tester) async {
    expect(await labelIn(tester, const Locale('en'), [renamed], 'product'), 'the word');
  });

  testWidgets('a field with no column keeps its own word', (tester) async {
    expect(await labelIn(tester, const Locale('ar'), [renamed], 'notes'), 'the word');
  });
}
