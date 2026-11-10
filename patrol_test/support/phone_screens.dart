import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:patrol/patrol.dart';
import 'package:path_provider/path_provider.dart';

import 'pc.dart';
import 'steps.dart';

/// How long the phone gets to open one of its own screens: a file may first have to come from the API.
const _phoneScreenTimeout = Duration(seconds: 30);

const _notepadPackage = 'com.huawei.notepad';
const _noteBody = '$_notepadPackage:id/notetext_textview';
const _shareSheetFileName = 'android:id/content_preview_filename';
const _pickerRow = 'android:id/title';

/// Keeps [bytes] as [name] in the app's own folder on the phone, the one place both the app and the PC can reach, and answers its path.
Future<String> keptInTheAppsFolder(String name, List<int> bytes) async {
  final file = File('${(await getExternalStorageDirectory())!.path}/$name');
  await file.writeAsBytes(bytes);
  return file.path;
}

/// The phone's own screens the app hands over to, met the way a person meets them: every case that shares, prints or picks a file goes through here.
extension PhoneScreens on PatrolIntegrationTester {
  AndroidAutomator get _android => platform.android;

  /// Taps what hands over to one of the phone's own screens, where the app stops drawing, so nothing waits for it to settle.
  Future<void> tapToThePhone(Key key) async {
    await goTo(this(key));
    await this(key).tap(settlePolicy: SettlePolicy.noSettle);
  }

  /// In the phone's share sheet, sends the text to Notepad and answers what Notepad received. Cancel closes it with no note kept.
  Future<String> textSharedToNotepad() async {
    await _android.tap(const AndroidSelector(text: 'Notepad'), timeout: _phoneScreenTimeout);
    await _android.waitUntilVisible(const AndroidSelector(resourceName: _noteBody), timeout: _phoneScreenTimeout);
    final text = await _textOf(_noteBody);
    await _android.tap(const AndroidSelector(contentDescription: 'Cancel', applicationPackage: _notepadPackage));
    await pumpAndSettle();
    return text;
  }

  /// The phone's share sheet opens on a file whose name holds [namePart], and the person backs out of it.
  Future<void> shareSheetOffers(String namePart) async {
    await _android.waitUntilVisible(AndroidSelector(resourceName: _shareSheetFileName, textContains: namePart), timeout: _phoneScreenTimeout);
    await _android.pressBack();
    await pumpAndSettle();
  }

  /// The phone's print screen opens, and the person backs out of it.
  Future<void> printScreenOpens() async {
    await _android.waitUntilVisible(const AndroidSelector(text: 'Select printer', applicationPackage: 'com.android.printspooler'), timeout: _phoneScreenTimeout);
    await _android.pressBack();
    await pumpAndSettle();
  }

  /// The person taps [key] and, in the phone's own file picker, picks the file [name] holding [bytes] from Downloads.
  Future<void> pickFromThePhone(Key key, String name, List<int> bytes) async {
    await keptInTheAppsFolder(name, bytes);
    await Pc.copyToDownloads(name);
    await tapToThePhone(key);
    await _android.tap(const AndroidSelector(contentDescription: 'Show roots'), timeout: _phoneScreenTimeout);
    await _android.tap(const AndroidSelector(resourceName: _pickerRow, text: 'Downloads'), timeout: _phoneScreenTimeout);
    await _android.tap(AndroidSelector(resourceName: _pickerRow, text: name), timeout: _phoneScreenTimeout);
    await pumpAndSettle();
  }

  /// After a failed case, closes whichever of the phone's screens it left open, keeping no note, and comes back to the app.
  Future<void> backToTheApp() async {
    await Pc.closeNotepad();
    await platform.mobile.openApp();
  }

  Future<String> _textOf(String resourceName) async {
    String textIn(AndroidNativeView view) => view.resourceName == resourceName ? view.text ?? '' : view.children.map(textIn).where((text) => text.isNotEmpty).firstOrNull ?? '';
    final found = await _android.getNativeViews(null);
    return found.roots.map(textIn).where((text) => text.isNotEmpty).firstOrNull ?? '';
  }
}
