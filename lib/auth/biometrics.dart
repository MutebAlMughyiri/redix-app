import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../words/words.dart';

/// The fingerprint or face check (UC-011, FR-35). What it guards is one fixed word, and being able to read it is the check. The session's tokens are never behind it:
/// they change at every renewal, and an iPhone asks again at every write to a guarded item.
class Biometrics {
  /// The check, through the phone's [_storage].
  const Biometrics([this._storage = const FlutterSecureStorage()]);

  final FlutterSecureStorage _storage;
  static const _key = 'biometrics';
  static const _word = 'on';
  static const _apple = IOSOptions(accessControlFlags: [AccessControlFlag.biometryCurrentSet]);

  AndroidOptions _android(Words words) => AndroidOptions.biometric(
    enforceBiometrics: true,
    biometricType: AndroidBiometricType.strongBiometricOnly,
    storageNamespace: _key,
    biometricPromptTitle: words.biometricsPromptTitle,
    biometricPromptSubtitle: words.biometricsSignIn,
    biometricPromptNegativeButton: words.biometricsPromptCancel,
  );

  /// Whether the person holding the phone passes. Any other answer, a new fingerprint on the phone included, means the password.
  Future<bool> passes(Words words) async {
    try {
      return await _storage.read(key: _key, aOptions: _android(words), iOptions: _apple) == _word;
    } on PlatformException catch (error) {
      debugPrint('Biometrics did not pass: $error');
      return false;
    }
  }

  /// Puts the word behind the check and asks for it once, so it turns on only for someone who can pass.
  Future<bool> turnOn(Words words) async {
    try {
      await _storage.write(key: _key, value: _word, aOptions: _android(words), iOptions: _apple);
    } on PlatformException catch (error) {
      debugPrint('Biometrics not available: $error');
      return false;
    }
    return passes(words);
  }
}
