import 'package:flutter/material.dart';

import '../ui/change_dialog.dart';
import '../ui/one_field_dialog.dart';
import '../words/words.dart';
import 'categories.dart';
import 'category.dart';
import 'item_type_choice.dart';

/// Asks for a new item's name and type, which is set once (FR-38).
class AddItemDialog extends StatefulWidget {
  /// The dialog adding an item to [category] through [categories].
  const AddItemDialog({super.key, required this.category, required this.categories});

  /// The category the item joins.
  final Category category;

  /// The way to change it.
  final Categories categories;

  @override
  State<AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<AddItemDialog> {
  final _name = TextEditingController();
  var _type = ItemType.both;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return ChangeDialog(
      title: words.categoriesAddItem,
      saveLabel: words.categoriesAddItem,
      onSave: () => widget.categories.addItem(widget.category, _name.text, _type),
      children: [
        TextField(
          key: OneFieldDialog.fieldKey,
          controller: _name,
          autofocus: true,
          decoration: InputDecoration(labelText: words.categoriesItemName),
        ),
        const SizedBox(height: 16),
        ItemTypeChoice(value: _type, onChanged: (type) => setState(() => _type = type)),
      ],
    );
  }
}
