import 'package:flutter/material.dart';

import '../ui/api_list_body.dart';
import '../ui/part_keys.dart';
import '../ui/picker_field.dart';
import '../words/words.dart';
import 'category.dart';
import 'offered_items.dart';

/// The field that chooses an item, opening a sheet of what is on offer, by category, with every name in full.
class ItemPicker extends StatelessWidget {
  /// The field labelled [label], showing [itemName], choosing among [items] and answering [onChanged]. A [none] that is not empty also offers no item at all, answered as [Item.none].
  const ItemPicker({super.key, required this.items, required this.label, this.none = '', required this.itemName, required this.onChanged});

  /// What is on offer.
  final OfferedItems items;

  /// What is being chosen.
  final String label;

  /// The word for choosing no item; empty when one has to be chosen.
  final String none;

  /// The chosen item's name; empty for none.
  final String itemName;

  /// Called with the item chosen.
  final ValueChanged<Item> onChanged;

  /// The choice of the item [id]; of no item when that is empty.
  static Key optionKey(String id) => Key('itemPicker.option.$id');

  /// The heading of the category [id].
  static Key categoryKey(String id) => Key('itemPicker.category.$id');

  Future<void> _choose(BuildContext context) async {
    final chosen = await showModalBottomSheet<Item>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheet) => FractionallySizedBox(
        heightFactor: 0.9,
        child: Column(
          children: [
            if (none.isNotEmpty) ListTile(key: optionKey(''), title: Text(none, key: optionKey('').title), onTap: () => Navigator.of(sheet).pop(Item.none())),
            Expanded(
              child: ApiListBody(
                list: items,
                emptyText: Words.of(sheet).categoriesEmpty,
                itemBuilder: (category) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(category.name, key: categoryKey(category.id), style: Theme.of(sheet).textTheme.titleSmall),
                    for (final item in category.items) ListTile(key: optionKey(item.id), title: Text(item.name, key: optionKey(item.id).title), onTap: () => Navigator.of(sheet).pop(item)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (chosen != null) {
      onChanged(chosen);
    }
  }

  @override
  Widget build(BuildContext context) => PickerField(key: key.field, label: label, value: itemName.isEmpty ? none : itemName, onTap: () => _choose(context));
}
