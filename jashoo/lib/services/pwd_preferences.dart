import 'package:shared_preferences/shared_preferences.dart';

/// PWD Preferences Service
/// Stores user preference for voice navigation mode
class PWDPreferences {
  static const String _KEY_PWD_MODE_ENABLED = 'pwd_voice_mode_enabled';
  static const String _KEY_SHOW_AUTO_SUGGEST = 'pwd_show_auto_suggest';

  /// Check if PWD voice mode should auto-start
  static Future<bool> isPWDModeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_KEY_PWD_MODE_ENABLED) ?? false;
  }

  /// Save PWD voice mode preference
  static Future<void> setPWDModeEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_KEY_PWD_MODE_ENABLED, enabled);
  }

  /// Check if auto-suggest should be shown
  static Future<bool> shouldShowAutoSuggest() async {
    final prefs = await SharedPreferences.getInstance();
    // Show auto-suggest if user hasn't made a choice yet
    return !prefs.containsKey(_KEY_PWD_MODE_ENABLED) ||
        prefs.getBool(_KEY_SHOW_AUTO_SUGGEST) != false;
  }

  /// Disable auto-suggest (user has made a choice)
  static Future<void> disableAutoSuggest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_KEY_SHOW_AUTO_SUGGEST, false);
  }

  /// Reset all preferences (for testing)
  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_KEY_PWD_MODE_ENABLED);
    await prefs.remove(_KEY_SHOW_AUTO_SUGGEST);
  }
}
