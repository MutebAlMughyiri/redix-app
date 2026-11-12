import 'package:flutter/material.dart';

import 'part_keys.dart';

/// One choice in a row's menu, keyed [key], saying [label], doing [onTap] when chosen. With a [reason] it shows gray and cannot be chosen, and says why under its label,
/// as Delete on an account something names (redix-app #89). The reason is a line of the menu's own gray text, not a list tile, so a menu opened from a shaded row keeps
/// its own ground: a list tile would take the row's shade with the theme Flutter copies into the menu (findings row 206).
PopupMenuItem<VoidCallback> rowMenuItem(Key key, String label, VoidCallback onTap, {String reason = ''}) => PopupMenuItem(
  key: key,
  value: onTap,
  enabled: reason.isEmpty,
  child: reason.isEmpty
      ? Text(label, key: key.label)
      : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, key: key.label),
            Builder(builder: (context) => Text(reason, key: key.subtitle, style: TextStyle(fontSize: Theme.of(context).textTheme.bodySmall?.fontSize))),
          ],
        ),
);

/// A row's ⋮ menu, keyed [key], holding [items]: each row says which choices it has (redix-api #108).
PopupMenuButton<VoidCallback> rowMenu(Key key, List<PopupMenuEntry<VoidCallback>> items) => PopupMenuButton<VoidCallback>(key: key, onSelected: (action) => action(), itemBuilder: (_) => items);
