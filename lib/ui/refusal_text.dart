import 'package:flutter/material.dart';

import 'app_color.dart';

/// A refusal or a failure said in words, keyed [key], in the one refusal color (redix-api #108).
Text refusalText(BuildContext context, String text, Key key) => Text(text, key: key, style: TextStyle(color: AppColor.refusal.of(context)));
