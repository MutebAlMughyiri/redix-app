// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'words.dart';

/// The language the user chose, on the sign-in screen or in Settings (UC-004), kept on the phone; empty while the app follows the phone's language.
class AppLanguage extends ChangeNotifier {
  static const _preferenceKey = 'language';

  var _chosen = '';

  /// The locale the app shows; null lets Flutter follow the phone, Arabic for any language the app does not have.
  Locale? get locale => _chosen.isEmpty ? null : Locale(_chosen);

  /// Reads the choice kept from an earlier start.
  Future<void> restore() async => _chosen = (await SharedPreferences.getInstance()).getString(_preferenceKey) ?? '';

  /// Switches the app to [language]. Its words are fetched first, so without a network nothing changes. Returns an empty string once
  /// switched, otherwise the word key of why not: `myAccount.languageNeedsNetwork`.
  Future<String> choose(String language) async {
    if ((await Words.load(language)).isEmpty) {
      return 'myAccount.languageNeedsNetwork';
    }
    _chosen = language;
    await (await SharedPreferences.getInstance()).setString(_preferenceKey, language);
    notifyListeners();
    return '';
  }
}
