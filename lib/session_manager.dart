import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

class SessionManager {
  static const _kUserKey = 'auth_username';
  static const _kPassKey = 'auth_password';

  static Future<void> saveCredentials(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUserKey, username);
    await prefs.setString(_kPassKey, password);
  }

  static Future<(String?, String?)> getCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getString(_kUserKey), prefs.getString(_kPassKey));
  }

  static Future<bool> isLoggedIn() async {
    final (u, p) = await getCredentials();
    return (u != null && u.isNotEmpty) && (p != null && p.isNotEmpty);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kUserKey);
    await prefs.remove(_kPassKey);
  }
  // ADD THESE METHODS TO YOUR EXISTING FILE
  static Future<void> clearAuthData() async {
    await AuthService.clearAuthData();
  }

  static Future<Map<String, dynamic>?> getAuthUser() async {
    return await AuthService.getUserData();
  }
}
