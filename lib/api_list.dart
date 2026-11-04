import 'package:flutter/foundation.dart';

import 'api.dart';
import 'auth/session.dart';

/// A list the API owns, as it last answered, and the way to change it. Nothing about it is kept on the phone.
abstract class ApiList<T> extends ChangeNotifier {
  /// The list at the API [_path], made from JSON by [_fromJson], whose word keys start with [_wordPrefix].
  ApiList(this._session, this._path, this._wordPrefix, this._fromJson);

  final Session _session;
  final String _path;
  final String _wordPrefix;
  final T Function(Map<String, dynamic>) _fromJson;

  var _all = <T>[];
  var _message = '';
  var _isLoading = false;

  /// Every item, in the order the API gives.
  List<T> get all => _all;

  /// The word key of why the list could not be read; empty when it could.
  String get message => _message;

  /// True while the list is being read.
  bool get isLoading => _isLoading;

  /// Reads the list from the API.
  Future<void> load() async {
    _isLoading = true;
    _message = '';
    notifyListeners();
    try {
      final response = await _session.get(_path);
      if (response.statusCode == 200) {
        _all = [for (final item in jsonOf(response) as List<dynamic>) _fromJson(item as Map<String, dynamic>)];
      } else {
        _message = '$_wordPrefix.loadFailed';
      }
    } on Exception catch (error) {
      debugPrint('$_path not read: $error');
      _message = '$_wordPrefix.loadFailed';
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Sends a change to the API [path] and, once it has answered, reads the list again, so what another owner changed shows as it is now.
  /// Returns an empty string once changed, otherwise the word key of the refusal.
  @protected
  Future<String> change(String path, Map<String, Object> body) async {
    try {
      final response = await _session.post(path, body);
      await load();
      if (response.statusCode < 300) {
        return '';
      }
      return '$_wordPrefix.${(jsonOf(response) as Map<String, dynamic>)['code'] as String? ?? 'refused'}';
    } on Exception catch (error) {
      debugPrint('$path not changed: $error');
      return '$_wordPrefix.noConnection';
    }
  }
}
