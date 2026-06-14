import 'package:skilllink_app/services/local_storage.dart';
class LocalStorage {

  static const String KEY_UID = "uid";
  static const String KEY_ROLE = "role";
  static const String KEY_LOGGED_IN = "logged_in";

  static get SharedPreferences => null;

  // Save user session
  static Future<void> saveUser({
    required String uid,
    required String role,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(KEY_UID, uid);
    await prefs.setString(KEY_ROLE, role);
    await prefs.setBool(KEY_LOGGED_IN, true);
  }

  // Get login status
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(KEY_LOGGED_IN) ?? false;
  }

  // Get role
  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(KEY_ROLE);
  }

  // Get UID
  static Future<String?> getUid() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(KEY_UID);
  }

  // Clear session (logout)
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}