import 'package:flutter/material.dart';

import '../words/words.dart';
import 'categories_screen.dart';
import 'category.dart';

/// What an item is for, chosen among every type, for the dialogs that add an item and change its type.
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
        Text(words.categoriesItemType, style: Theme.of(context).textTheme.titleSmall),
        RadioGroup<ItemType>(
          groupValue: value,
          onChanged: (type) => onChanged(type ?? value),
          child: Column(
            children: [
              for (final type in ItemType.values)
                RadioListTile<ItemType>(key: CategoriesScreen.itemTypeKey(type), contentPadding: EdgeInsets.zero, value: type, title: Text(words.text(type.wordKey))),
            ],
          ),
        ),
      ],
    );
  }
}
