// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// The checks both test folders make of what a screen shows, in one copy (findings row 226, Muteb, 16 Nov 2026): the widget tests reach them through app_harness.dart, and the
// phone's cases through patrol_test/support/steps.dart, so a fix to one check reaches both.

/// Whether what holds the focus, the field the keyboard types into, sits inside the element keyed [key].
bool holdsFocus(Key key) {
  var inside = false;
  FocusManager.instance.primaryFocus?.context?.visitAncestorElements((element) => !(inside = element.widget.key == key));
  return inside;
}

/// True when the element keyed [key] sits in its screen's title bar: within the height the screen's app bar takes from the top.
bool isInTitleBar(WidgetTester tester, Key key) => tester.getRect(find.byKey(key)).bottom <= Scaffold.of(tester.element(find.byKey(key))).appBarMaxHeight!;

/// True when the button keyed [key] works; a screen's add button shows grayed without the permission rather than hidden (issue #85).
bool isEnabled(WidgetTester tester, Key key) => works(tester.widget(find.byKey(key)));

/// True when [widget], a button, a menu's choice or a card, does something when tapped; without its permission a report's control shows gray, never hidden (redix-api #131).
bool works(Widget widget) => switch (widget) {
  final IconButton icon => icon.onPressed != null,
  final PopupMenuItem<Object?> choice => choice.enabled,
  final InkWell card => card.onTap != null,
  final widget => (widget as ButtonStyleButton).enabled,
};

/// Every widget whose key starts with [start].
Finder keyStartingWith(String start) => find.byWidgetPredicate((widget) => widget.key is ValueKey<String> && (widget.key! as ValueKey<String>).value.startsWith(start));

/// Every widget keyed by [keyOf] for any id, such as the rows of a list whose ids a test does not know: the widgets whose key starts as [keyOf] keys an empty id.
Finder keyedBy(Key Function(String id) keyOf) => keyStartingWith((keyOf('') as ValueKey<String>).value);
