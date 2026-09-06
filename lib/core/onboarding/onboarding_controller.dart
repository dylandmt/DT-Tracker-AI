import 'package:shared_preferences/shared_preferences.dart';

class OnboardingController {
  static const _generalKey = 'onboarding_general_completed';
  static const _tipPrefix = 'onboarding_tip_';

  OnboardingController(this._preferences);

  final SharedPreferences _preferences;

  bool get hasCompletedGeneral => _preferences.getBool(_generalKey) ?? false;
  bool hasSeenTip(String key) =>
      _preferences.getBool('$_tipPrefix$key') ?? false;

  Future<void> completeGeneral() => _preferences.setBool(_generalKey, true);
  Future<void> markTipSeen(String key) =>
      _preferences.setBool('$_tipPrefix$key', true);

  Future<void> reset() async {
    await _preferences.remove(_generalKey);
    for (final key in _preferences.getKeys().where(
      (key) => key.startsWith(_tipPrefix),
    )) {
      await _preferences.remove(key);
    }
  }
}
