import '../format/number_format.dart';

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

/// A column (العمود) of one item or of the default template, as the API answers it. The rules live in the API; the app only draws what it is told.
class ItemColumn {
  /// The column the API describes in [json].
  ItemColumn.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      key = json['key'] as String,
      name = json['name'] as String,
      options = (json['options'] as List<dynamic>).cast<String>(),
      dataType = ColumnDataType.values.byName(json['dataType'] as String),
      isCore = json['isCore'] as bool,
      isCustom = json['isCustom'] as bool,
      isRequired = json['isRequired'] as bool,
      showInReports = json['showInReports'] as bool;

  /// The column's id.
  final String id;

  /// What names this column in an entry's values.
  final String key;

  /// The column's name, as it was typed.
  final String name;

  /// The choices of a list; empty otherwise.
  final List<String> options;

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

  /// What the API is sent for [typed]: a number in Western digits with no separators, anything else as it is.
  String valueToSend(String typed) {
    final number = dataType == ColumnDataType.number || dataType == ColumnDataType.amount ? parseNumber(typed) : double.nan;
    return number.isNaN ? typed : number.toString();
  }
}
