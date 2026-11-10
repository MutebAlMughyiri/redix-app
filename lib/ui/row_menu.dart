import 'package:flutter/material.dart';

import 'part_keys.dart';

/// One choice in a row's menu, keyed [key], saying [label], doing [onTap] when chosen. With a [reason] it shows gray and cannot be chosen, and says why under its label,
/// as Delete on an account something names (redix-app #89).
PopupMenuItem<VoidCallback> rowMenuItem(Key key, String label, VoidCallback onTap, {String reason = ''}) => PopupMenuItem(
  key: key,
  value: onTap,
  enabled: reason.isEmpty,
  child: reason.isEmpty
      ? Text(label, key: key.label)
      : ListTile(contentPadding: EdgeInsets.zero, enabled: false, title: Text(label, key: key.label), subtitle: Text(reason, key: key.subtitle)),
);

/// A row's ⋮ menu, keyed [key], holding [items]: each row says which choices it has (redix-api #108).
PopupMenuButton<VoidCallback> rowMenu(Key key, List<PopupMenuEntry<VoidCallback>> items) => PopupMenuButton<VoidCallback>(key: key, onSelected: (action) => action(), itemBuilder: (_) => items);
