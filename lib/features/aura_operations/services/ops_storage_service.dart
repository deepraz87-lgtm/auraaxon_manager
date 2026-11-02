import 'package:shared_preferences/shared_preferences.dart';

class OpsStorageService {
  static const String _keyHostUrl = 'aura_ops_host_url';
  static const String _keyAuthToken = 'aura_ops_auth_token';
  static const String _defaultHostUrl = 'http://localhost:8484';

  Future<String> getHostUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyHostUrl) ?? _defaultHostUrl;
  }

  Future<void> setHostUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyHostUrl, url.trim());
  }

  Future<String> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAuthToken) ?? '';
  }

  Future<void> setAuthToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAuthToken, token.trim());
  }
}
