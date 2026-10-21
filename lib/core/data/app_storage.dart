import 'package:shared_preferences/shared_preferences.dart';

class AppStorage {
  final SharedPreferences _prefs;

  AppStorage(this._prefs);

  static const _hasCompletedOnboardingKey = 'has_completed_onboarding';

  bool get hasCompletedOnboarding =>
      _prefs.getBool(_hasCompletedOnboardingKey) ?? false;

  Future<void> setHasCompletedOnboarding(bool value) async {
    await _prefs.setBool(_hasCompletedOnboardingKey, value);
  }

  static const _hasSeenHomeCoachMarksKey = 'has_seen_home_coach_marks';

  /// The home spotlight tour (location → services → orders tab) was shown.
  bool get hasSeenHomeCoachMarks =>
      _prefs.getBool(_hasSeenHomeCoachMarksKey) ?? false;

  Future<void> setHasSeenHomeCoachMarks(bool value) async {
    await _prefs.setBool(_hasSeenHomeCoachMarksKey, value);
  }

  static const _marketingOptInKey = 'marketing_opt_in';

  /// Last "รับข่าวสารและโปรโมชั่น" choice sent to the backend. The API has no
  /// getter for it, so this is what the switch shows; the backend default
  /// (opted in) applies until the customer changes it.
  bool get marketingOptIn => _prefs.getBool(_marketingOptInKey) ?? true;

  Future<void> setMarketingOptIn(bool value) async {
    await _prefs.setBool(_marketingOptInKey, value);
  }
}
