import 'dart:io' show HttpDate;

import 'package:http/http.dart' as http;

import '../offline/local_store.dart';

/// The server's clock as the phone knows it (redix-app #107, D2): the phone's own, corrected by how far it was from the server's at the last answer, which the
/// answer's Date header says, and kept, so a phone whose clock is wrong still dates an entry by the server's day, online and offline.
class ServerClock {
  /// The clock whose correction is kept in [_store]; [_phoneNow] is the phone's own clock.
  ServerClock(this._store, [this._phoneNow = DateTime.now]);

  final LocalStore _store;
  final DateTime Function() _phoneNow;
  var _correction = Duration.zero;

  static const _folder = 'clock';
  static const _name = 'correction';

  /// Reads the correction kept at the last answer, for a phone opened with no network.
  Future<void> open() async => _correction = Duration(microseconds: int.tryParse(await _store.read(_folder, _name)) ?? 0);

  /// Learns from an answer the API just gave how far the phone's clock is from the server's, and keeps it once it moved by a second or more: the Date header
  /// counts whole seconds.
  Future<void> learn(http.Response response) async {
    final date = response.headers['date'] ?? '';
    if (date.isEmpty) {
      return;
    }
    final correction = HttpDate.parse(date).difference(_phoneNow());
    if ((correction - _correction).abs() < const Duration(seconds: 1)) {
      return;
    }
    _correction = correction;
    await _store.write(_folder, _name, '${correction.inMicroseconds}');
  }

  /// Now, by the server's clock.
  DateTime now() => _phoneNow().add(_correction);
}
