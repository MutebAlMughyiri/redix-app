import 'package:flutter/material.dart';

import 'part_keys.dart';

/// One choice in a row's menu, keyed [key], saying [label], doing [onTap] when chosen.
PopupMenuItem<VoidCallback> rowMenuItem(Key key, String label, VoidCallback onTap) => PopupMenuItem(key: key, value: onTap, child: Text(label, key: key.label));

/// A row's ⋮ menu, keyed [key], holding [items]: each row says which choices it has (redix-api #108).
PopupMenuButton<VoidCallback> rowMenu(Key key, List<PopupMenuEntry<VoidCallback>> items) => PopupMenuButton<VoidCallback>(key: key, onSelected: (action) => action(), itemBuilder: (_) => items);
