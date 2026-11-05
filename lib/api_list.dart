import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import 'api.dart';
import 'auth/session.dart';

/// A copy of [list] with the row at [from] moved to [to], as a drag ends.
List<E> moved<E>(List<E> list, int from, int to) {
  final order = [...list];
  order.insert(to, order.removeAt(from));
  return order;
}

/// A list the API owns, as it last answered, and the way to change it. Nothing about it is kept on the phone.
abstract class ApiList<T> extends ChangeNotifier {
  /// The list at the API [_path], made from JSON by [_fromJson], whose word keys start with [_wordPrefix].
  ApiList(this._session, this._path, this._wordPrefix, this._fromJson) {
    _session.addListener(_forgetAtSignOut);
  }

  final Session _session;
  final String _path;
  final String _wordPrefix;
  final T Function(Map<String, dynamic>) _fromJson;

  var _all = <T>[];
  var _message = '';
  var _isLoading = false;
  var _lastAnswer = const <String, dynamic>{};

  /// Every item, in the order the API gives.
  List<T> get all => _all;

  /// The word key of why the list could not be read; empty when it could.
  String get message => _message;

  /// True while the list is being read.
  bool get isLoading => _isLoading;

  /// What the API answered the last change, when that was a JSON object: for a change whose answer says more than a code.
  @protected
  Map<String, dynamic> get lastAnswer => _lastAnswer;

  /// What one user read never shows to the next on this phone, even for the moment the next list takes to load (BR-33).
  void _forgetAtSignOut() {
    if (!_session.isOpen) {
      _all = [];
    }
  }

  @override
  void dispose() {
    _session.removeListener(_forgetAtSignOut);
    super.dispose();
  }

  /// Reads the list for a screen that is opening. The read waits for the frame in progress, because another screen sharing this list may still be building.
  void loadOnOpen() {
    _isLoading = true;
    SchedulerBinding.instance.addPostFrameCallback((_) => load());
  }

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

  /// Sends a change to the API [path] and, once it has answered, reads the list again, so what someone else changed shows as it is now.
  /// Returns an empty string once changed, otherwise the word key of the refusal.
  @protected
  Future<String> change(String path, Map<String, Object> body) async {
    try {
      final response = await _session.post(path, body);
      await load();
      final answer = response.body.isEmpty ? null : jsonOf(response);
      _lastAnswer = answer is Map<String, dynamic> ? answer : const {};
      return response.statusCode < 300 ? '' : '$_wordPrefix.${_lastAnswer['code'] as String? ?? 'refused'}';
    } on Exception catch (error) {
      debugPrint('$path not changed: $error');
      return '$_wordPrefix.noConnection';
    }
  }

  /// Shows [order] at once, so what was dragged stays where it was dropped, and sends the change to the API [path]. Whatever is refused, or never arrives, goes back to what the API holds.
  /// Returns an empty string once changed, otherwise the word key of the refusal.
  @protected
  Future<String> reorder(String path, Map<String, Object> body, List<T> order) async {
    _all = order;
    notifyListeners();
    final refusal = await change(path, body);
    if (refusal.isNotEmpty) {
      await load();
    }
    return refusal;
  }
}
