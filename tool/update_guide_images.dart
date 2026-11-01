import 'dart:io';

/// Copies the screenshots the last `patrol test` run pulled into `patrol_test/screenshots/` to `docs/guide/images/{tag}.png`,
/// the newest of each tag, so the user guide links stay the same while its pictures follow the app. Then clears the pulled folder.
/// Run after `patrol test`: `dart run tool/update_guide_images.dart`
void main() {
  final pulled = Directory('patrol_test/screenshots');
  final shots = pulled.listSync(recursive: true).whereType<File>().where((file) => file.path.endsWith('.png')).toList()
    ..sort((first, second) => fileName(first).compareTo(fileName(second)));

  final newest = {for (final shot in shots) tagOf(shot): shot};
  Directory('docs/guide/images').createSync(recursive: true);
  for (final MapEntry(key: tag, value: shot) in newest.entries) {
    shot.copySync('docs/guide/images/$tag.png');
  }
  pulled.deleteSync(recursive: true);
  stdout.writeln('${newest.length} guide images updated');
}

/// The file name: Patrol names each screenshot `{milliseconds}_{tag}.png`, so names sort by time.
String fileName(File file) => file.uri.pathSegments.last;

/// The tag the test gave the screenshot.
String tagOf(File file) {
  final name = fileName(file);
  return name.substring(name.indexOf('_') + 1, name.length - '.png'.length);
}
