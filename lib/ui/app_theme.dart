import 'package:flutter/material.dart';

import 'app_color.dart';

/// The app's look for [brightness], grown from [AppColor.seed]: the light and the dark mode both come from here, so a change to one is a change to both (redix-app #87).
ThemeData appThemeOf(Brightness brightness) => ThemeData(
  colorSchemeSeed: AppColor.seed,
  brightness: brightness,
  fontFamily: 'IBMPlexSansArabic',
  inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
);
