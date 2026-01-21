import 'package:shared_preferences/shared_preferences.dart';

class UserSession {
  static const _keyUsername = 'username';

  static Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_keyUsername);
    if (name == null || name.trim().isEmpty) return null;
    return name.trim();
  }

  static Future<void> setUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUsername, username.trim());
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUsername);
  }
}
