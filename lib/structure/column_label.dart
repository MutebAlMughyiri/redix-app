import 'package:flutter/widgets.dart';

import 'item_column.dart';

/// What an entry form calls the built-in field [key]. In Arabic it is the name of its column, as the project renamed it, because a column's name is typed in one language; otherwise it is [word].
String columnLabel(BuildContext context, List<ItemColumn> columns, String key, String word) {
  if (Localizations.localeOf(context).languageCode != 'ar') {
    return word;
  }
  return columns.where((column) => column.key == key).map((column) => column.name).firstOrNull ?? word;
}
