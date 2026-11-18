// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'dart:typed_data';

/// What this phone keeps outside the app's memory, in named files inside folders.
abstract class LocalStore {
  /// A store over the phone's storage, or a test's memory.
  const LocalStore();

  /// The text kept under [name] in [folder]; empty when none is.
  Future<String> read(String folder, String name);

  /// Keeps [text] under [name] in [folder].
  Future<void> write(String folder, String name, String text);

  /// The bytes kept under [name] in [folder]; empty when none are.
  Future<Uint8List> readBytes(String folder, String name);

  /// Keeps [bytes] under [name] in [folder].
  Future<void> writeBytes(String folder, String name, List<int> bytes);

  /// Forgets [name] in [folder].
  Future<void> delete(String folder, String name);

  /// The names kept in [folder].
  Future<List<String>> namesIn(String folder);

  /// Forgets everything in [folder].
  Future<void> clear(String folder);
}
