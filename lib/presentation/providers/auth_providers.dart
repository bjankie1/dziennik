import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/auth/firebase_auth_service.dart';
import '../../data/services/librus_connection_service.dart';
import '../../domain/models/user_role.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden in ProviderScope');
});

class AppUser {
  final String displayName;
  final String email;
  final String? photoUrl;
  final UserRole role;
  final String? studentLogin;
  final String? primaryLogin;
  final String? familyId;

  const AppUser({
    required this.displayName,
    required this.email,
    this.photoUrl,
    this.role = UserRole.parent,
    this.studentLogin,
    this.primaryLogin,
    this.familyId,
  });

  bool get isParent => role.isParent;
  bool get isStudent => role.isStudent;

  AppUser copyWith({
    String? displayName,
    String? email,
    String? photoUrl,
    UserRole? role,
    String? studentLogin,
    String? primaryLogin,
    String? familyId,
  }) {
    return AppUser(
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      studentLogin: studentLogin ?? this.studentLogin,
      primaryLogin: primaryLogin ?? this.primaryLogin,
      familyId: familyId ?? this.familyId,
    );
  }
}

class AppUserNotifier extends Notifier<AppUser?> {
  static const _keyEmail = 'app_user_email';
  static const _keyName = 'app_user_name';
  static const _keyPhoto = 'app_user_photo';
  static const _keyIsLoggedIn = 'app_user_is_logged_in';
  static const _keyRole = 'app_user_role';
  static const _keyStudentLogin = 'app_user_student_login';
  static const _keyPrimaryLogin = 'app_user_primary_login';
  static const _keyFamilyId = 'app_user_family_id';

  @override
  AppUser? build() {
    try {
      final prefs = ref.watch(sharedPreferencesProvider);
      final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
      final email = prefs.getString(_keyEmail);
      final name = prefs.getString(_keyName);
      final photo = prefs.getString(_keyPhoto);
      final roleStr = prefs.getString(_keyRole);
      final studentLogin = prefs.getString(_keyStudentLogin);
      final primaryLogin = prefs.getString(_keyPrimaryLogin);
      final familyId = prefs.getString(_keyFamilyId);

      if (isLoggedIn && email != null && email.isNotEmpty) {
        return AppUser(
          displayName: name ?? 'Użytkownik',
          email: email,
          photoUrl: photo,
          role: UserRole.fromString(roleStr),
          studentLogin: studentLogin,
          primaryLogin: primaryLogin,
          familyId: familyId,
        );
      }
    } catch (_) {}
    return null;
  }

  void setUser(AppUser? user) {
    state = user;
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      if (user != null) {
        prefs.setBool(_keyIsLoggedIn, true);
        prefs.setString(_keyEmail, user.email);
        prefs.setString(_keyName, user.displayName);
        if (user.photoUrl != null) {
          prefs.setString(_keyPhoto, user.photoUrl!);
        } else {
          prefs.remove(_keyPhoto);
        }
        prefs.setString(_keyRole, user.role.name);
        if (user.studentLogin != null) {
          prefs.setString(_keyStudentLogin, user.studentLogin!);
        } else {
          prefs.remove(_keyStudentLogin);
        }
        if (user.primaryLogin != null) {
          prefs.setString(_keyPrimaryLogin, user.primaryLogin!);
        } else {
          prefs.remove(_keyPrimaryLogin);
        }
        if (user.familyId != null) {
          prefs.setString(_keyFamilyId, user.familyId!);
        } else {
          prefs.remove(_keyFamilyId);
        }
      } else {
        prefs.setBool(_keyIsLoggedIn, false);
        prefs.remove(_keyEmail);
        prefs.remove(_keyName);
        prefs.remove(_keyPhoto);
        prefs.remove(_keyRole);
        prefs.remove(_keyStudentLogin);
        prefs.remove(_keyPrimaryLogin);
        prefs.remove(_keyFamilyId);
      }
    } catch (_) {}
  }

  void updateRole(UserRole role) {
    if (state == null) return;
    final updated = state!.copyWith(role: role);
    setUser(updated);
  }
}

final appUserProvider =
    NotifierProvider<AppUserNotifier, AppUser?>(AppUserNotifier.new);

final firebaseAuthServiceProvider = Provider<FirebaseAuthService>((ref) {
  return FirebaseAuthService();
});

final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(firebaseAuthServiceProvider);
  return authService.authStateChanges;
});

final librusConnectionServiceProvider = Provider<LibrusConnectionService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LibrusConnectionService(prefs: prefs);
});

class LibrusConnectionNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final service = ref.watch(librusConnectionServiceProvider);
    return service.isConnected();
  }

  Future<bool> connectLibrus(String login, String password) async {
    final service = ref.read(librusConnectionServiceProvider);
    final success = await service.connectWithCredentials(login, password);
    state = AsyncValue.data(success);
    return success;
  }

  Future<void> connectDemo() async {
    state = const AsyncValue.loading();
    final service = ref.read(librusConnectionServiceProvider);
    await service.connectDemoMode();
    state = const AsyncValue.data(true);
  }

  Future<void> disconnect() async {
    state = const AsyncValue.loading();
    final service = ref.read(librusConnectionServiceProvider);
    await service.disconnect();
    state = const AsyncValue.data(false);
  }
}

final librusConnectionStateProvider =
    AsyncNotifierProvider<LibrusConnectionNotifier, bool>(LibrusConnectionNotifier.new);
