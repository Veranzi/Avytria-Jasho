import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage PWD (Persons with Disabilities) accessibility settings
class PWDService {
  static const String _pwdModeKey = 'pwd_mode_enabled';
  
  /// Check if PWD mode is enabled
  static Future<bool> isPWDModeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_pwdModeKey) ?? false;
  }
  
  /// Enable PWD mode
  static Future<void> enablePWDMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pwdModeKey, true);
  }
  
  /// Disable PWD mode
  static Future<void> disablePWDMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pwdModeKey, false);
  }
  
  /// Toggle PWD mode
  static Future<bool> togglePWDMode() async {
    final currentState = await isPWDModeEnabled();
    if (currentState) {
      await disablePWDMode();
      return false;
    } else {
      await enablePWDMode();
      return true;
    }
  }
}

