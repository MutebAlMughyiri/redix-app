import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:http/http.dart' as http;

import 'api.dart';
import 'auth/session.dart';

/// Something the API owns, as it last answered, and the way to change it. Nothing about it is kept on the phone.
abstract class ApiObject<T> extends ChangeNotifier {
  /// What the API at [_path] answers, made from JSON by [_fromJson], whose word keys start with [_wordPrefix]; [_empty] until it answers.
  ApiObject(this._session, this._path, this._wordPrefix, this._fromJson, this._empty) : _value = _empty {
    _session.addListener(_forgetAtSignOut);
  }

  final Session _session;
  String _path;
  final String _wordPrefix;
  final T Function(Object? json) _fromJson;
  final T _empty;

  T _value;
  var _message = '';
  var _isLoading = false;
  var _lastAnswer = const <String, dynamic>{};

  /// What the API last answered.
  T get value => _value;

  /// The word key saying it could not be read.
  @protected
  String get loadFailedKey => '$_wordPrefix.loadFailed';

  /// The word key of why it could not be read; empty when it could.
  String get message => _message;

  /// True while it is being read.
  bool get isLoading => _isLoading;

  /// Points at the API [path], for something whose address follows what is asked. What is still on its way from the old address never shows.
  @protected
  void pointAt(String path) => _path = path;

  /// The API path it reads now.
  @protected
  String get pointedAt => _path;

  /// Shows [value], found some other way than by reading the API.
  @protected
  void show(T value) {
    _value = value;
    _message = '';
    notifyListeners();
  }

  /// What the API answered the last change, when that was a JSON object: for a change whose answer says more than a code.
  @protected
  Map<String, dynamic> get lastAnswer => _lastAnswer;

  /// The id the last change answered with, such as a new entry's; empty when it answered none.
  String get lastId => _lastAnswer['id'] as String? ?? '';

  /// What one user read never shows to the next on this phone, even for the moment the next one takes to load (BR-33).
  void _forgetAtSignOut() {
    if (!_session.isOpen) {
      _value = _empty;
    }
  }

  @override
  void dispose() {
    _session.removeListener(_forgetAtSignOut);
    super.dispose();
  }

  /// Reads it for a screen that is opening. The read waits for the frame in progress, because another screen sharing this may still be building.
  void loadOnOpen() {
    _isLoading = true;
    SchedulerBinding.instance.addPostFrameCallback((_) => load());
  }

  /// Reads it from the API.
  Future<void> load() async {
    final path = _path;
    _isLoading = true;
    _message = '';
    notifyListeners();
    var value = _value;
    var message = '';
    try {
      final response = await _session.get(path);
      if (response.statusCode == 200) {
        value = _fromJson(jsonOf(response));
      } else {
        message = loadFailedKey;
      }
    } on Exception catch (error) {
      debugPrint('$path not read: $error');
      message = loadFailedKey;
    }
    if (path == _path) {
      _value = value;
      _message = message;
      _isLoading = false;
      notifyListeners();
    }
  }

  /// What the API at [path] answers now, made as this is, without showing it: the next page of a list read a page at a time (redix-app #89). One that cannot be read throws.
  @protected
  Future<T> readAt(String path) async {
    final response = await _session.get(path);
    if (response.statusCode != 200) {
      throw http.ClientException('$path answered ${response.statusCode}');
    }
    return _fromJson(jsonOf(response));
  }

  /// Sends a change to the API [path] and, once it has answered, reads this again, so what someone else changed shows as it is now.
  /// Returns an empty string once changed, otherwise the word key of the refusal, under [wordPrefix] when that is not empty, for a change other screens also make.
  @protected
  Future<String> change(String path, Map<String, Object> body, {String wordPrefix = ''}) => _send(path, () => _session.post(path, body), wordPrefix);

  /// Sends the file [bytes], named [name], with the form [fields] beside it, to the API [path], and answers as [change] does.
  @protected
  Future<String> sendFile(String path, String name, List<int> bytes, {Map<String, String> fields = const {}}) => _send(path, () => _session.postFile(path, name, bytes, fields: fields), '');

  Future<String> _send(String path, Future<http.Response> Function() send, String wordPrefix) async {
    final prefix = wordPrefix.isEmpty ? _wordPrefix : wordPrefix;
    try {
      final response = await send();
      await load();
      _lastAnswer = answerOf(response);
      return response.statusCode < 300 ? '' : refusalOf(_lastAnswer, prefix);
    } on Exception catch (error) {
      debugPrint('$path not changed: $error');
      return '$prefix.noConnection';
    }
  }
}
