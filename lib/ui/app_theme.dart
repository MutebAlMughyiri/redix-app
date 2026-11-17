import 'package:flutter/material.dart';

import 'app_color.dart';

/// The app's look for [brightness], grown from [AppColor.seed]: the light and the dark mode both come from here, so a change to one is a change to both (redix-app #87).
/// Every card takes the one gap below it from here, and every title starts on the language's side, on iPhone too (redix-app #96).
ThemeData appThemeOf(Brightness brightness) => ThemeData(
  colorSchemeSeed: AppColor.seed,
  brightness: brightness,
  fontFamily: 'IBMPlexSansArabic',
  inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
  cardTheme: const CardThemeData(margin: EdgeInsets.only(bottom: 8)),
  appBarTheme: const AppBarTheme(centerTitle: false),
);
