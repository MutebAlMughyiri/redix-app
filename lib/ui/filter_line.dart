import 'package:flutter/material.dart';

import '../format/parts_line.dart';
import 'part_keys.dart';

/// The one line of filters under a list's search line (redix-app #104), which never takes two lines: a choice among a few is [segmented], a filter on or off is
/// [toggle], and a choice among many is [choices], one chip that opens its list and says what is chosen. A segmented choice alone fills the line, its segments sharing
/// the width; several members sit in one line scrolled sideways when a phone is too narrow.
class FilterLine extends StatelessWidget {
  /// The line of [members], each made by one of this class's builders.
  const FilterLine({super.key, required this.members});

  /// The filters, in order.
  final List<Widget> members;

  /// One of a few [values], the one [selected] marked, each named by [labelOf] and keyed by [keyOf], calling [onChanged] with the one chosen.
  static Widget segmented<T>({required Key key, required List<T> values, required T selected, required String Function(T value) labelOf, required Key Function(T value) keyOf, required ValueChanged<T> onChanged}) =>
      SegmentedButton<T>(
        key: key,
        showSelectedIcon: false,
        expandedInsets: EdgeInsets.zero,
        segments: [for (final value in values) ButtonSegment(value: value, label: KeyedSubtree(key: keyOf(value), child: Text(labelOf(value), key: keyOf(value).label)))],
        selected: {selected},
        onSelectionChanged: (chosen) => onChanged(chosen.single),
      );

  /// A filter named [label], on while [isOn], calling [onChanged] with its new state.
  static Widget toggle({required Key key, required String label, required bool isOn, required ValueChanged<bool> onChanged}) =>
      FilterChip(key: key, label: Text(label, key: key.label), selected: isOn, onSelected: onChanged);

  /// A chip named [label] opening the list of [values], each named by [labelOf] and keyed by [keyOf], those [chosen] ticked; tapping one calls [onToggled] with it.
  /// While some are chosen the chip names them after its label.
  static Widget choices<T>({
    required Key key,
    required String label,
    required List<T> values,
    required Set<T> chosen,
    required String Function(T value) labelOf,
    required Key Function(T value) keyOf,
    required ValueChanged<T> onToggled,
  }) => MenuAnchor(
    menuChildren: [
      for (final value in values)
        KeyedSubtree(
          key: keyOf(value),
          child: CheckboxMenuButton(value: chosen.contains(value), closeOnActivate: false, onChanged: (_) => onToggled(value), child: Text(labelOf(value), key: keyOf(value).label)),
        ),
    ],
    builder: (context, menu, _) => FilterChip(
      key: key,
      label: Text(chosen.isEmpty ? label : '$label: ${partsLine([for (final value in values) if (chosen.contains(value)) labelOf(value)])}', key: key.label),
      selected: chosen.isNotEmpty,
      avatar: Icon(menu.isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down, key: key.icon),
      showCheckmark: false,
      onSelected: (_) => menu.isOpen ? menu.close() : menu.open(),
    ),
  );

  /// A chip named [label] doing [onPressed] at once, such as clearing the filters.
  static Widget action({required Key key, required String label, required VoidCallback onPressed}) => ActionChip(key: key, label: Text(label, key: key.label), onPressed: onPressed);

  @override
  Widget build(BuildContext context) => members.length == 1 ? members.single : SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(spacing: 8, children: members));
}
