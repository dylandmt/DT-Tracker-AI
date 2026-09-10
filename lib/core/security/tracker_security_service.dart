import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

/// Stores the unlink PIN in the platform's protected storage.
class TrackerSecurityService {
  TrackerSecurityService({
    required FirebaseAuth firebaseAuth,
    required FlutterSecureStorage storage,
    required LocalAuthentication localAuthentication,
  }) : _firebaseAuth = firebaseAuth,
       _storage = storage,
       _localAuthentication = localAuthentication;

  final FirebaseAuth _firebaseAuth;
  final FlutterSecureStorage _storage;
  final LocalAuthentication _localAuthentication;

  String get _userId {
    final userId = _firebaseAuth.currentUser?.uid;
    if (userId == null) throw StateError('No authenticated user');
    return userId;
  }

  String get _pinKey => 'tracker_unlink_pin_$_userId';
  String get _biometricsKey => 'tracker_unlink_biometrics_$_userId';

  Future<bool> hasPin() async => await _storage.read(key: _pinKey) != null;

  Future<void> savePin(String pin, {required bool biometricsEnabled}) async {
    await _storage.write(key: _pinKey, value: pin);
    await setBiometricsEnabled(biometricsEnabled);
  }

  Future<bool> verifyPin(String pin) async =>
      await _storage.read(key: _pinKey) == pin;

  Future<bool> isBiometricsEnabled() async =>
      await _storage.read(key: _biometricsKey) == 'true';

  Future<void> setBiometricsEnabled(bool enabled) async {
    await _storage.write(key: _biometricsKey, value: enabled.toString());
  }

  Future<void> revokePin() async {
    await _storage.delete(key: _pinKey);
    await _storage.delete(key: _biometricsKey);
  }

  Future<bool> canUseBiometrics() async {
    try {
      return await _localAuthentication.isDeviceSupported() &&
          await _localAuthentication.canCheckBiometrics &&
          (await _localAuthentication.getAvailableBiometrics()).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticateWithBiometrics({
    required String localizedReason,
  }) async {
    if (!await isBiometricsEnabled() || !await canUseBiometrics()) return false;

    try {
      return await _localAuthentication.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          sensitiveTransaction: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
