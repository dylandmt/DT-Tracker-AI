import 'package:shared_preferences/shared_preferences.dart';

class OnboardingController {
  static const _generalKeyPrefix = 'onboarding_general_completed_';
  static const _tipPrefix = 'onboarding_tip_';

  OnboardingController(this._preferences);

  final SharedPreferences _preferences;

  bool hasCompletedGeneral(String userId) =>
      _preferences.getBool('$_generalKeyPrefix$userId') ?? false;
  bool hasSeenTip(String key) =>
      _preferences.getBool('$_tipPrefix$key') ?? false;

  Future<void> completeGeneral(String userId) =>
      _preferences.setBool('$_generalKeyPrefix$userId', true);
  Future<void> markTipSeen(String key) =>
      _preferences.setBool('$_tipPrefix$key', true);

  Future<void> reset(String userId) async {
    await _preferences.remove('$_generalKeyPrefix$userId');
    for (final key in _preferences.getKeys().where(
      (key) => key.startsWith(_tipPrefix),
    )) {
      await _preferences.remove(key);
    }
  }
}
