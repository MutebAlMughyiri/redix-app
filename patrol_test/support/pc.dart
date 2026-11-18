// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:http/http.dart' as http;

/// What a case on the phone cannot do for itself, asked of `tool/patrol_pc_helper.ps1` on the PC.
class Pc {
  Pc._();

  /// Cuts the phone's link to the API. It travels by USB through `adb reverse`, so airplane mode would not cut it.
  static Future<void> cutNetwork() => _ask('network/off');

  /// Puts the phone's link to the API back.
  static Future<void> restoreNetwork() => _ask('network/on');

  /// Opens [link] as a tap on it in another app would.
  static Future<void> openLink(String link) => _ask('link?${Uri.encodeComponent(link)}');

  /// Opens [link] as a tap on the «إضافة قيد» home-screen widget does: straight to the app, its button's link or a row's (redix-app #86).
  static Future<void> tapTheWidget(String link) => _ask('widget?${Uri.encodeComponent(link)}');

  /// Copies the file named [name] from the app's own folder on the phone to its Download folder, where the phone's file picker lists it.
  static Future<void> copyToDownloads(String name) => _ask('to-downloads?${Uri.encodeComponent(name)}');

  /// Shares the phone's file at [path], of the type [mimeType], into the app, as another app's share sheet does.
  static Future<void> shareIntoTheApp(String path, String mimeType) => _ask('share-in?${Uri.encodeComponent('$mimeType|$path')}');

  /// Turns the phone's own dark mode on, as its settings would.
  static Future<void> turnPhoneDark() => _ask('phone/dark');

  /// Turns the phone's own dark mode off.
  static Future<void> turnPhoneLight() => _ask('phone/light');

  /// Puts the phone's own dark mode back as it was before a case changed it, whichever its owner chose.
  static Future<void> restorePhone() => _ask('phone/restore');

  /// Closes Notepad with nothing saved, so a case leaves no note on the phone.
  static Future<void> closeNotepad() => _ask('notepad/close');

  /// Throws unless a file whose name starts with [start] reached the phone's Download folder in the last two minutes, and removes what it found so the case leaves nothing behind.
  static Future<void> expectDownloaded(String start) => _ask('downloaded?${Uri.encodeComponent(start)}');

  /// Keeps one line about a case in a file on the PC: whether it passed, how long it took, and why it failed.
  static Future<void> note(String line) => _ask('note?${Uri.encodeComponent(line.length > 1500 ? line.substring(0, 1500) : line)}');

  static Future<void> _ask(String what) async {
    final answer = await http.get(Uri.parse('http://127.0.0.1:5011/$what'));
    if (answer.statusCode != 200) {
      throw StateError('The PC answered ${answer.statusCode} to $what');
    }
  }
}
