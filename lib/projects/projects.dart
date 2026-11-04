import 'package:flutter/foundation.dart';

import '../api.dart';
import '../auth/session.dart';
import 'project.dart';

/// The projects as the API last answered them (UC-006), and the one way to change them. Nothing about them is kept on the phone.
class Projects extends ChangeNotifier {
  /// The projects of the user signed in through [_session].
  Projects(this._session);

  final Session _session;

  var _all = <Project>[];
  var _message = '';
  var _isLoading = false;

  /// Every project, in the order the API gives: running ones first, then the newest.
  List<Project> get all => _all;

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
      final response = await _session.get('/projects');
      if (response.statusCode == 200) {
        _all = [for (final project in jsonOf(response) as List<dynamic>) Project.fromJson(project as Map<String, dynamic>)];
      } else {
        _message = 'projects.loadFailed';
      }
    } on Exception catch (error) {
      debugPrint('Projects not read: $error');
      _message = 'projects.loadFailed';
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Creates a project with its [units], all or nothing. Returns an empty string once created, otherwise the word key of the refusal.
  Future<String> create(String name, DateTime startDate, List<String> units) =>
      _change('/projects', {'name': name, 'startDate': startDate.toIso8601String().substring(0, 10), 'units': units});

  /// Adds a unit named [name] to [project]. Returns an empty string once added, otherwise the word key of the refusal.
  Future<String> addUnit(Project project, String name) => _change('/projects/${project.id}/units', {'name': name});

  /// Closes [project], which is read-only from then on. Returns an empty string once closed, otherwise the word key of the refusal.
  Future<String> close(Project project) => _change('/projects/${project.id}/close', {});

  /// Sends a change and, once the API has answered, reads the list again, so a project another owner changed shows as it is now.
  Future<String> _change(String path, Map<String, Object> body) async {
    try {
      final response = await _session.post(path, body);
      await load();
      if (response.statusCode < 300) {
        return '';
      }
      return 'projects.${(jsonOf(response) as Map<String, dynamic>)['code'] as String? ?? 'refused'}';
    } on Exception catch (error) {
      debugPrint('Project not changed: $error');
      return 'projects.noConnection';
    }
  }
}
