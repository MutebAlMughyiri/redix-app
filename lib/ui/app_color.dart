// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';

/// Every color the app shows, in one place (the owner, 9 Nov 2026: "create one enum class color to store all colors of the app ... this will help us to unify the colors and
/// unify design and ease of mantinance and change the design later"). A screen never picks a color of its own: it names what the color is for, and this says which color
/// that is, taken from the theme so that a light and a dark mode both follow (redix-app #87). Changing a color here changes it on every screen that uses it.
enum AppColor {
  /// A refusal, an error, a rejected entry, a contract gone beyond its value, the red bar of a row that can be removed, and a button that removes.
  refusal(_error),

  /// Text and icons on [refusal].
  onRefusal(_onError),

  /// The ground behind a row being swiped away, and a chip saying a contract went beyond its value.
  refusalSurface(_errorContainer),

  /// Text and icons on [refusalSurface].
  onRefusalSurface(_onErrorContainer),

  /// What is disabled or says less: a disabled account, item, supplier, user or payment method, a category's name while disabled, and a column's lock.
  quiet(_onSurfaceVariant),

  /// Plain text, where a widget must name its color.
  text(_onSurface),

  /// A line that says less: an open-value contract's progress bar.
  outline(_outline),

  /// The frame of a card.
  frame(_outlineVariant),

  /// The ground of something empty or neutral: the empty photo box, the figures band, a user's initial.
  mutedSurface(_surfaceContainerHighest),

  /// The ground of an odd row among rows one under another, the scheme's next tone after the page's: a shade darker in light, a shade lighter in dark (redix-app #108).
  oddRow(_surfaceContainerLow),

  /// The ground of what is active or the user's own: an active project's chip, my custody, the QR code's reading.
  activeSurface(_primaryContainer),

  /// The ground of what needs a look: what waits, on the summary.
  noticeSurface(_tertiaryContainer),

  /// The app's own color: the star of the default project.
  brand(_primary),

  /// An entry waiting for a decision: its frame and its status words (redix-app #90).
  waiting(_orange);

  const AppColor(this._from);

  final Color Function(ColorScheme colors) _from;

  /// The color every theme's colors grow from.
  static const seed = Color(0xFF0E6B68);

  /// This color in the theme of [context].
  Color of(BuildContext context) => _from(Theme.of(context).colorScheme);

  /// A text style of this color unless [condition] holds, when the text keeps the theme's own: a disabled name is quiet, an active one is not.
  TextStyle? textUnless(BuildContext context, bool condition) => condition ? null : TextStyle(color: of(context));

  static Color _error(ColorScheme colors) => colors.error;

  static Color _onError(ColorScheme colors) => colors.onError;

  static Color _errorContainer(ColorScheme colors) => colors.errorContainer;

  static Color _onErrorContainer(ColorScheme colors) => colors.onErrorContainer;

  static Color _onSurfaceVariant(ColorScheme colors) => colors.onSurfaceVariant;

  static Color _onSurface(ColorScheme colors) => colors.onSurface;

  static Color _outline(ColorScheme colors) => colors.outline;

  static Color _outlineVariant(ColorScheme colors) => colors.outlineVariant;

  static Color _surfaceContainerHighest(ColorScheme colors) => colors.surfaceContainerHighest;

  static Color _surfaceContainerLow(ColorScheme colors) => colors.surfaceContainerLow;

  static Color _primaryContainer(ColorScheme colors) => colors.primaryContainer;

  static Color _tertiaryContainer(ColorScheme colors) => colors.tertiaryContainer;

  static Color _primary(ColorScheme colors) => colors.primary;

  /// Orange 900 on the light ground, where 700 read at 2.6:1, and 700 on the dark one (findings row 191, the owner, 12 Nov 2026).
  static Color _orange(ColorScheme colors) => colors.brightness == Brightness.light ? Colors.orange.shade900 : Colors.orange.shade700;
}
