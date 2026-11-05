import 'dart:typed_data';

/// What the camera or the files gave: a file, nothing when the person went back, or why neither.
class PickedFile {
  /// The file named [name] at [path], holding [bytes].
  PickedFile(this.name, this.path, this.bytes) : failure = '';

  /// Nothing, for a person who went back without choosing.
  PickedFile.none() : name = '', path = '', bytes = Uint8List(0), failure = '';

  /// Nothing, because of the word key [failure].
  PickedFile.failed(this.failure) : name = '', path = '', bytes = Uint8List(0);

  /// The file's name.
  final String name;

  /// Where it is on the phone.
  final String path;

  /// What it holds, already compressed if it is a picture.
  final Uint8List bytes;

  /// The word key of why there is no file; empty otherwise.
  final String failure;

  /// True when there is no file.
  bool get isNone => bytes.isEmpty;

  /// True for a PDF, which shows no picture.
  bool get isPdf => name.toLowerCase().endsWith('.pdf');
}
