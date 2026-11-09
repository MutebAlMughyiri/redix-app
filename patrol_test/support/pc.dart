import 'package:http/http.dart' as http;

/// What a case on the phone cannot do for itself, asked of `tool/patrol_pc_helper.ps1` on the PC.
class Pc {
  Pc._();

  /// Cuts the phone's link to the API. It travels by USB through `adb reverse`, so airplane mode would not cut it.
  static Future<void> cutNetwork() => _ask('network/off');

  /// Puts the phone's link to the API back.
  static Future<void> restoreNetwork() => _ask('network/on');

  static Future<void> _ask(String what) async {
    final answer = await http.get(Uri.parse('http://127.0.0.1:5011/$what'));
    if (answer.statusCode != 200) {
      throw StateError('The PC answered ${answer.statusCode} to $what');
    }
  }
}
