// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'attachments.dart';
import 'picked_file.dart';

/// An entry's file, the same for every entry (the owner, 8 Nov 2026): the file picked, why it could not be, and its id once the API keeps it, so it is kept once however often the
/// entry is sent.
class EntryFile {
  /// The file picked; none until one is.
  var picked = PickedFile.none();

  /// The word key of why the last file could not be taken; empty when it could.
  var message = '';

  /// The id the API kept it under; empty until kept.
  var attachmentId = '';

  /// Takes [file] when there is one, forgetting the one kept before, and says why when it could not be taken.
  void take(PickedFile file) {
    message = file.failure;
    if (!file.isNone) {
      picked = file;
      attachmentId = '';
    }
  }

  /// Shows [file], the one the entry already holds, without sending it again.
  void showKept(PickedFile file) {
    picked = file;
  }

  /// Keeps the file through [attachments] once; an empty string when kept or when there is none, otherwise the word key of the refusal.
  Future<String> keep(Attachments attachments) async {
    if (picked.isNone || attachmentId.isNotEmpty) {
      return '';
    }
    final refusal = await attachments.keep(picked);
    if (refusal.isEmpty) {
      attachmentId = attachments.kept.id;
    }
    return refusal;
  }
}
