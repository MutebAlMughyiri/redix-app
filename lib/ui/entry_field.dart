import 'package:flutter/material.dart';

/// One typed field of an entry's form, the same on every kind of entry: text, or a number on the phone's number keyboard, which has a minus sign when it [isSigned]. It answers [onChanged], with [errorText] under it when something is wrong, which is how a text field is told.
TextField entryField({required Key key, required TextEditingController controller, required String label, required ValueChanged<String> onChanged, bool isNumber = false, bool isSigned = false, int maxLines = 1, String? errorText}) => TextField(
  key: key,
  controller: controller,
  maxLines: maxLines,
  keyboardType: isNumber ? TextInputType.numberWithOptions(decimal: true, signed: isSigned) : null,
  decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), errorText: errorText),
  onChanged: onChanged,
);
