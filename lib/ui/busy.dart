import 'dart:async';

import 'package:flutter/material.dart';

/// The spinner [whileBusy] shows.
const busySpinnerKey = Key('busy.spinner');

/// Shows a spinner over the screen while [work] runs, for what may take time: picking, reading or sending a file (Muteb, 11 Nov 2026). Nothing can be tapped meanwhile;
/// the spinner goes once [work] ends, however it ends, and this answers what [work] answered.
Future<T> whileBusy<T>(BuildContext context, Future<T> work) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  unawaited(showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const PopScope(canPop: false, child: Center(child: CircularProgressIndicator(key: busySpinnerKey))),
  ));
  try {
    return await work;
  } finally {
    navigator.pop();
  }
}
