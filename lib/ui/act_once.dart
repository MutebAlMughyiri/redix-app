// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'dart:async';

import 'package:flutter/widgets.dart';

/// What a tap does; it ends when the work does, and a tap that opens a screen ends when that screen closes.
typedef TapAction = FutureOr<void> Function();

/// One action at a time for the buttons [builder] makes (Muteb, 10 Nov 2026): the first tap runs, and every button made with `once` stays gray until that action ends, so a double tap cannot act twice.
class ActOnce extends StatefulWidget {
  /// Buttons made by [builder], each passing its action through `once` as its `onPressed` or `onTap`.
  const ActOnce({super.key, required this.builder});

  /// Makes the buttons. `once` answers what the button should call, or null, which grays it, while an action runs or when the action given is null.
  final Widget Function(VoidCallback? Function(TapAction? action) once) builder;

  @override
  State<ActOnce> createState() => _ActOnceState();
}

class _ActOnceState extends State<ActOnce> {
  var _running = false;

  VoidCallback? _once(TapAction? action) => action == null || _running ? null : () => _run(action);

  Future<void> _run(TapAction action) async {
    if (_running) {
      return;
    }
    setState(() => _running = true);
    try {
      await action();
    } finally {
      if (mounted) {
        setState(() => _running = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => widget.builder(_once);
}
