import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'librus_auth_service.dart';

class LibrusConnectionService {
  static const String _keyConnected = 'librus_is_connected';
  static const String _keyLogin = 'librus_login_name';
  static const String _keyDemo = 'librus_demo_mode';
  static const String _keyExplicitDisconnect = 'librus_explicit_disconnect';

  final LibrusAuthService _authService;

  LibrusConnectionService({LibrusAuthService? authService})
      : _authService = authService ?? LibrusAuthService();

  Future<bool> isConnected() async {
    final prefs = await SharedPreferences.getInstance();
    final isExplicit = prefs.getBool(_keyExplicitDisconnect) ?? false;
    if (isExplicit) return false;

    // Check if connection is already active in local storage
    final localConnected = prefs.getBool(_keyConnected);
    if (localConnected != null) return localConnected;

    // Check backend persistence in Firestore
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final res = await http.get(Uri.parse('/api/getConnection?userId=${user.uid}'))
            .timeout(const Duration(seconds: 3));
        if (res.statusCode == 200) {
          final data = json.decode(res.body);
          if (data['connected'] == true && data['librusLogin'] != null) {
            final login = data['librusLogin'] as String;
            await prefs.setBool(_keyConnected, true);
            await prefs.setString(_keyLogin, login);
            await prefs.setBool(_keyDemo, data['isDemoMode'] == true);
            return true;
          }
        }
      }
    } catch (_) {}

    return false;
  }

  Future<String?> getConnectedLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final login = prefs.getString(_keyLogin);
    if (login != null && login.isNotEmpty) return login;
    return null;
  }

  Future<bool> isDemoMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyDemo) ?? false;
  }

  Future<bool> connectWithCredentials(String login, String password) async {
    try {
      await _authService.login(login, password);
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyConnected, true);
    await prefs.setString(_keyLogin, login);
    await prefs.setBool(_keyDemo, false);
    await prefs.setBool(_keyExplicitDisconnect, false);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await http.get(Uri.parse('/api/saveConnection?userId=${user.uid}&login=$login&email=${user.email ?? ""}')).timeout(const Duration(seconds: 4));
      }
    } catch (_) {}

    return true;
  }

  Future<void> connectDemoMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyConnected, true);
    await prefs.setString(_keyLogin, 'konto_demo@librus.pl');
    await prefs.setBool(_keyDemo, true);
    await prefs.setBool(_keyExplicitDisconnect, false);
  }

  Future<void> disconnect() async {
    await _authService.logout();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyConnected, false);
    await prefs.remove(_keyLogin);
    await prefs.setBool(_keyDemo, false);
    await prefs.setBool(_keyExplicitDisconnect, true);
  }
}
