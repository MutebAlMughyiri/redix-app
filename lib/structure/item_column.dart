// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import '../format/number_format.dart';
import '../words/words.dart';

/// What a column holds (FR-41), as the API names it, each knowing its word.
enum ColumnDataType {
  /// Free text.
  text('columns.typeText'),

  /// A number, such as an area.
  number('columns.typeNumber'),

  /// An amount of money.
  amount('columns.typeAmount'),

  /// A date.
  date('columns.typeDate'),

  /// A choice from a list.
  list('columns.typeList'),

  /// A picture or a PDF: the attachment's alone, never offered to a person.
  file('columns.typeFile');

  const ColumnDataType(this.wordKey);

  /// The key of the word that names this type.
  final String wordKey;

  /// The types a person chooses among.
  static const offered = [text, number, amount, date, list];
}

/// The sign a list's choice gives the amount of the entry that chooses it (redix-api #129), each knowing its word.
enum ChoiceSign {
  /// It says nothing of the amount.
  none('columns.signNone'),

  /// The amount counts as it is: «شراء», «إضافة مبلغ».
  plus('columns.signPlus'),

  /// The amount counts the other way: «مرتجع» takes away, «سحب مبلغ» takes out.
  minus('columns.signMinus');

  const ChoiceSign(this.wordKey);

  /// The key of the word that names this sign.
  final String wordKey;
}

/// One choice of a list column, as its definition keeps it (redix-api #129): its id, which an entry keeps, its name, and its sign.
class ColumnChoice {
  /// The choice the API describes in [json].
  ColumnChoice.fromJson(Map<String, dynamic> json) : id = json['id'] as String, name = json['name'] as String, sign = ChoiceSign.values.byName(json['sign'] as String);

  /// The choice's id: what an entry's value holds once it is chosen.
  final String id;

  /// The choice's name, as it was typed.
  final String name;

  /// The sign it gives the amount.
  final ChoiceSign sign;

  /// The choice as a column's list shows it in [words]: its name, then its sign's word when it gives one, «مرتجع (−)» (redix-api #129).
  String labelIn(Words words) => sign == ChoiceSign.none ? name : '$name (${words.text(sign.wordKey)})';
}

/// A column (العمود) of one item or of the default template, as the API answers it. The rules live in the API; the app only draws what it is told.
class ItemColumn {
  /// The column the API describes in [json].
  ItemColumn.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      key = json['key'] as String,
      name = json['name'] as String,
      choices = [for (final choice in json['choices'] as List<dynamic>) ColumnChoice.fromJson(choice as Map<String, dynamic>)],
      dataType = ColumnDataType.values.byName(json['dataType'] as String),
      isCore = json['isCore'] as bool,
      isCustom = json['isCustom'] as bool,
      isRequired = json['isRequired'] as bool,
      showInReports = json['showInReports'] as bool,
      isEntryField = json['isEntryField'] as bool;

  /// The [values] typed, by column key, as the API takes them from an entry's [columns].
  static Map<String, String> valuesToSend(List<ItemColumn> columns, Map<String, String> values) => {
    for (final MapEntry(:key, :value) in values.entries) key: columns.where((column) => column.key == key).map((column) => column.valueToSend(value)).firstOrNull ?? value,
  };

  /// The column's id.
  final String id;

  /// What names this column in an entry's values.
  final String key;

  /// The column's name, as it was typed.
  final String name;

  /// The choices of a list kept in its definition, each with its id and sign; empty otherwise, a register's list included.
  final List<ColumnChoice> choices;

  /// What it holds.
  final ColumnDataType dataType;

  /// True when it is renamed and reordered, and never deleted (BR-20).
  final bool isCore;

  /// True when a person added it.
  final bool isCustom;

  /// Whether entry asks for it.
  final bool isRequired;

  /// Whether it prints in the reports.
  final bool showInReports;

  /// True for a column the entry answers in a field of its own, its date, supplier, amount, account, method, file, contract or description «الوصف» (redix-api #129); false for one Add entry draws as a field of
  /// the column itself, the unit price, the quantity, the product, «نوع القيد» and «نوع الحركة» among them (redix-api #129, R3).
  final bool isEntryField;

  /// The sign of what [values] chose in the one list of [columns], a table's, whose choices carry a sign (redix-api #129); none when there is none or nothing was chosen. It says
  /// whether a total kept negative was typed as a plain amount, as a credit note's is.
  static ChoiceSign signOf(List<ItemColumn> columns, Map<String, String> values) => columns
      .where((column) => column.isSigned)
      .expand((column) => column.choices.where((choice) => choice.id == values[column.key]))
      .map((choice) => choice.sign)
      .followedBy(const [ChoiceSign.none])
      .first;

  /// True for a list whose choices give the amount a sign; a table has one at most (redix-api #129).
  bool get isSigned => choices.any((choice) => choice.sign != ChoiceSign.none);

  /// Whether it can gain choices: only a list a person added, since the others read a register.
  bool get gainsChoices => dataType == ColumnDataType.list && isCustom;

  /// What the API is sent for [typed]: a number in Western digits with no separators, anything else as it is.
  String valueToSend(String typed) {
    final number = dataType == ColumnDataType.number || dataType == ColumnDataType.amount ? parseNumber(typed) : double.nan;
    return number.isNaN ? typed : number.toString();
  }
}
