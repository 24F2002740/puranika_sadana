import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _languageSelectedKey = 'language_selected';

  Future<void> saveLoginSession(bool isLoggedIn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, isLoggedIn);
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  Future<void> markLanguageSelected() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_languageSelectedKey, true);
  }

  Future<bool> isLanguageSelected() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_languageSelectedKey) ?? false;
  }
  
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isLoggedInKey);
  }
}
