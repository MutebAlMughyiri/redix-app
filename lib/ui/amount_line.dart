import 'package:flutter/material.dart';

import '../format/number_format.dart';
import 'part_keys.dart';

/// A [label] with its [amount] at the end of the line: the amount keyed [key], the label its label part, each in the style given or the theme's (redix-api #108).
Row amountLine(Key key, String label, double amount, {TextStyle? labelStyle, TextStyle? amountStyle}) => Row(
  children: [
    Expanded(child: Text(label, key: key.label, style: labelStyle)),
    Text(formatMoney(amount), key: key, style: amountStyle),
  ],
);
