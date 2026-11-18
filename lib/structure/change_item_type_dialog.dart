// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';

import '../ui/change_dialog.dart';
import '../words/words.dart';
import 'categories.dart';
import 'category.dart';
import 'item_type_choice.dart';

/// Asks what an item is for now, starting from what it is. The API refuses it once the item has entries, and the dialog says so.
class ChangeItemTypeDialog extends StatefulWidget {
  /// The dialog changing [item] through [categories].
  const ChangeItemTypeDialog({super.key, required this.item, required this.categories});

  /// The item to change.
  final Item item;

  /// The way to change it.
  final Categories categories;

  @override
  State<ChangeItemTypeDialog> createState() => _ChangeItemTypeDialogState();
}

class _ChangeItemTypeDialogState extends State<ChangeItemTypeDialog> {
  late var _type = widget.item.type;

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return ChangeDialog(
      title: words.categoriesChangeType,
      saveLabel: words.categoriesSave,
      onSave: () => widget.categories.changeItemType(widget.item, _type),
      children: [ItemTypeChoice(value: _type, onChanged: (type) => setState(() => _type = type))],
    );
  }
}
