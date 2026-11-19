// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import 'local_store.dart';

/// Keeps files in the app's private folder on the phone. A name may hold any character, because an address names a kept list.
class FolderStore extends LocalStore {
  /// The store over the folder [_root] gives, the app's private one on a phone.
  const FolderStore([this._root = getApplicationSupportDirectory]);

  final Future<Directory> Function() _root;

  Future<Directory> _folder(String folder) async {
    final root = await _root();
    return Directory('${root.path}/$folder').create(recursive: true);
  }

  Future<File> _file(String folder, String name) async => File('${(await _folder(folder)).path}/${base64Url.encode(utf8.encode(name))}');

  /// Each file's last write, which the next write of that file waits for: two writes of one copy at once, as a list's load and a project's sync
  /// make, filled one `.new` file together, mixed the two and lost the copy (findings row 268).
  static final _lastWrites = <String, Future<void>>{};

  /// Writes [file] whole, through its `.new` file that [fill] writes, once the file's last write has ended.
  Future<void> _replace(File file, Future<File> Function(File temporary) fill) {
    final write = (_lastWrites[file.path] ?? Future<void>.value()).then((_) async {
      final written = await fill(File('${file.path}.new'));
      await written.rename(file.path);
    });
    _lastWrites[file.path] = write.then((_) {}, onError: (Object _) {});
    return write;
  }

  @override
  Future<String> read(String folder, String name) async {
    final file = await _file(folder, name);
    return file.existsSync() ? file.readAsString() : '';
  }

  @override
  Future<void> write(String folder, String name, String text) async =>
      _replace(await _file(folder, name), (temporary) => temporary.writeAsString(text, flush: true));

  @override
  Future<Uint8List> readBytes(String folder, String name) async {
    final file = await _file(folder, name);
    return file.existsSync() ? file.readAsBytes() : Uint8List(0);
  }

  @override
  Future<void> writeBytes(String folder, String name, List<int> bytes) async =>
      _replace(await _file(folder, name), (temporary) => temporary.writeAsBytes(bytes, flush: true));

  @override
  Future<void> delete(String folder, String name) async {
    final file = await _file(folder, name);
    if (file.existsSync()) {
      await file.delete();
    }
  }

  @override
  Future<List<String>> namesIn(String folder) async {
    final found = await (await _folder(folder)).list().where((entry) => entry is File && !entry.path.endsWith('.new')).toList();
    return [for (final entry in found) utf8.decode(base64Url.decode(entry.uri.pathSegments.last))];
  }

  @override
  Future<void> clear(String folder) async {
    final found = await _folder(folder);
    await found.delete(recursive: true);
  }
}
