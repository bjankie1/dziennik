import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'librus_auth_service.dart';
import '../../domain/models/user_role.dart';
import '../../presentation/providers/auth_providers.dart';

class LibrusConnectionService {
  static const String _keyConnected = 'librus_is_connected';
  static const String _keyLogin = 'librus_login_name';
  static const String _keyDemo = 'librus_demo_mode';
  static const String _keyExplicitDisconnect = 'librus_explicit_disconnect';
  static const String _keyRole = 'app_user_role';
  static const String _keyStudentLogin = 'app_user_student_login';
  static const String _keyPrimaryLogin = 'app_user_primary_login';
  static const String _keyFamilyId = 'app_user_family_id';

  final LibrusAuthService _authService;
  final SharedPreferences? _prefs;

  LibrusConnectionService({
    LibrusAuthService? authService,
    SharedPreferences? prefs,
  })  : _authService = authService ?? LibrusAuthService(),
        _prefs = prefs;

  Future<SharedPreferences> _getPrefs() async {
    return _prefs ?? await SharedPreferences.getInstance();
  }

  bool isConnectedSync() {
    if (_prefs != null) {
      return _prefs.getBool(_keyConnected) ?? false;
    }
    return false;
  }

  Future<bool> isConnected() async {
    final prefs = await _getPrefs();

    // 1. Check local storage first (instant return without network latency)
    final localConnected = prefs.getBool(_keyConnected);
    if (localConnected == true) {
      return true;
    }

    // 2. Check if user explicitly disconnected
    final isExplicit = prefs.getBool(_keyExplicitDisconnect) ?? false;
    if (isExplicit) {
      return false;
    }

    // 3. Check backend persistence in Firestore (autologin across devices / reloads)
    try {
      final user = FirebaseAuth.instance.currentUser;
      final savedEmail = prefs.getString('app_user_email');
      final userId = user?.uid ?? savedEmail;

      if (userId != null && userId.isNotEmpty) {
        final res = await http
            .get(Uri.parse('/api/getConnection?userId=$userId'))
            .timeout(const Duration(seconds: 4));
        if (res.statusCode == 200) {
          final data = json.decode(res.body);
          if (data['connected'] == true && data['librusLogin'] != null) {
            final login = data['librusLogin'] as String;
            await prefs.setBool(_keyConnected, true);
            await prefs.setString(_keyLogin, login);
            await prefs.setBool(_keyDemo, data['isDemoMode'] == true);
            await prefs.setBool(_keyExplicitDisconnect, false);

            final roleStr = data['role'] as String? ?? 'parent';
            await prefs.setString(_keyRole, roleStr);
            if (data['studentLogin'] != null) {
              await prefs.setString(_keyStudentLogin, data['studentLogin'] as String);
            } else {
              await prefs.remove(_keyStudentLogin);
            }
            if (data['primaryLogin'] != null) {
              await prefs.setString(_keyPrimaryLogin, data['primaryLogin'] as String);
            } else {
              await prefs.remove(_keyPrimaryLogin);
            }
            if (data['familyId'] != null) {
              await prefs.setString(_keyFamilyId, data['familyId'] as String);
            } else {
              await prefs.remove(_keyFamilyId);
            }

            return true;
          }
        }
      }
    } catch (_) {}

    return false;
  }

  Future<String?> getConnectedLogin() async {
    final prefs = await _getPrefs();
    final login = prefs.getString(_keyLogin);
    if (login != null && login.isNotEmpty) return login;
    return null;
  }

  Future<bool> isDemoMode() async {
    final prefs = await _getPrefs();
    return prefs.getBool(_keyDemo) ?? false;
  }

  Future<AppUser?> getSavedAppUser() async {
    final prefs = await _getPrefs();
    final email = prefs.getString('app_user_email');
    if (email == null || email.isEmpty) return null;

    final name = prefs.getString('app_user_name') ?? 'Użytkownik';
    final photo = prefs.getString('app_user_photo');
    final roleStr = prefs.getString(_keyRole);
    final studentLogin = prefs.getString(_keyStudentLogin);
    final primaryLogin = prefs.getString(_keyPrimaryLogin);
    final familyId = prefs.getString(_keyFamilyId);

    return AppUser(
      displayName: name,
      email: email,
      photoUrl: photo,
      role: UserRole.fromString(roleStr),
      studentLogin: studentLogin,
      primaryLogin: primaryLogin,
      familyId: familyId,
    );
  }

  Future<bool> connectWithCredentials(
    String login,
    String password, {
    UserRole role = UserRole.parent,
    String? primaryLogin,
    String? familyId,
  }) async {
    try {
      await _authService.login(login, password);
    } catch (_) {}

    final prefs = await _getPrefs();
    await prefs.setBool(_keyConnected, true);
    await prefs.setString(_keyLogin, login);
    await prefs.setBool(_keyDemo, false);
    await prefs.setBool(_keyExplicitDisconnect, false);

    await prefs.setString(_keyRole, role.name);
    if (role.isStudent) {
      await prefs.setString(_keyStudentLogin, login);
    } else {
      await prefs.remove(_keyStudentLogin);
    }

    final resolvedPrimaryLogin = primaryLogin ?? (role.isParent ? login : null);
    if (resolvedPrimaryLogin != null) {
      await prefs.setString(_keyPrimaryLogin, resolvedPrimaryLogin);
    } else {
      await prefs.remove(_keyPrimaryLogin);
    }

    final resolvedFamilyId = familyId ?? 'jankiewicz_family';
    await prefs.setString(_keyFamilyId, resolvedFamilyId);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final savedEmail = prefs.getString('app_user_email');
      final userId = user?.uid ?? savedEmail ?? 'bartosz.jankiewicz@gmail.com';
      final email = user?.email ?? savedEmail ?? 'bartosz.jankiewicz@gmail.com';

      final roleParam = '&role=${role.name}';
      final studentLoginParam = role.isStudent ? '&studentLogin=$login' : '';
      final primaryLoginParam = resolvedPrimaryLogin != null ? '&primaryLogin=$resolvedPrimaryLogin' : '';
      final familyIdParam = '&familyId=$resolvedFamilyId';

      await http
          .get(Uri.parse(
              '/api/saveConnection?userId=$userId&login=$login&email=$email$roleParam$studentLoginParam$primaryLoginParam$familyIdParam'))
          .timeout(const Duration(seconds: 4));
    } catch (_) {}

    return true;
  }

  Future<void> connectDemoMode() async {
    final prefs = await _getPrefs();
    await prefs.setBool(_keyConnected, true);
    await prefs.setString(_keyLogin, 'konto_demo@librus.pl');
    await prefs.setBool(_keyDemo, true);
    await prefs.setBool(_keyExplicitDisconnect, false);
  }

  /// Zwykłe wylogowanie z aplikacji — czyści stan lokalny, ale NIE usuwa powiązania w Firestore.
  Future<void> clearLocalSession() async {
    final prefs = await _getPrefs();
    await prefs.setBool(_keyConnected, false);
    await prefs.remove(_keyLogin);
    await prefs.remove(_keyRole);
    await prefs.remove(_keyStudentLogin);
    await prefs.remove(_keyPrimaryLogin);
    await prefs.remove(_keyFamilyId);
  }

  /// Świadome rozłączenie konta Librus — trwale czyści powiązanie w Firestore i lokalnie.
  Future<void> disconnect() async {
    await _authService.logout();
    final prefs = await _getPrefs();
    await prefs.setBool(_keyConnected, false);
    await prefs.remove(_keyLogin);
    await prefs.setBool(_keyDemo, false);
    await prefs.setBool(_keyExplicitDisconnect, true);
    await prefs.remove(_keyRole);
    await prefs.remove(_keyStudentLogin);
    await prefs.remove(_keyPrimaryLogin);
    await prefs.remove(_keyFamilyId);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final savedEmail = prefs.getString('app_user_email');
      final userId = user?.uid ?? savedEmail;
      if (userId != null && userId.isNotEmpty) {
        await http
            .get(Uri.parse('/api/saveConnection?userId=$userId&unbind=true'))
            .timeout(const Duration(seconds: 4));
      }
    } catch (_) {}
  }
}
