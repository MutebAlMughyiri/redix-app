import 'package:flutter/material.dart';

import '../ui/part_keys.dart';
import '../words/words.dart';
import 'categories_screen.dart';
import 'category.dart';

/// What an item is for (FR-38): its side first, expenses or revenue, then one of that side's types, for the dialogs that add an item and change its type.
class ItemTypeChoice extends StatelessWidget {
  /// The choice standing at [value], calling [onChanged] with another.
  const ItemTypeChoice({super.key, required this.value, required this.onChanged});

  /// The type chosen.
  final ItemType value;

  /// Called with the type chosen instead.
  final ValueChanged<ItemType> onChanged;

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(words.categoriesSide, key: CategoriesScreen.sideHeadingKey, style: Theme.of(context).textTheme.titleSmall),
        SegmentedButton<bool>(
          key: CategoriesScreen.sideChoiceKey,
          showSelectedIcon: false,
          segments: [
            ButtonSegment(value: false, label: Text(words.categoriesSideExpenses, key: CategoriesScreen.sideKey(isRevenue: false))),
            ButtonSegment(value: true, label: Text(words.categoriesSideRevenue, key: CategoriesScreen.sideKey(isRevenue: true))),
          ],
          selected: {value.isRevenue},
          onSelectionChanged: (side) => onChanged(ItemType.values.firstWhere((type) => type.isRevenue == side.single)),
        ),
        Text(words.categoriesItemType, key: CategoriesScreen.typeHeadingKey, style: Theme.of(context).textTheme.titleSmall),
        RadioGroup<ItemType>(
          groupValue: value,
          onChanged: (type) => onChanged(type ?? value),
          child: Column(
            children: [
              for (final type in ItemType.values.where((type) => type.isRevenue == value.isRevenue))
                RadioListTile<ItemType>(key: CategoriesScreen.itemTypeKey(type), contentPadding: EdgeInsets.zero, value: type, title: Text(words.text(type.wordKey), key: CategoriesScreen.itemTypeKey(type).title)),
            ],
          ),
        ),
      ],
    );
  }
}
