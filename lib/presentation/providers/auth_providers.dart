import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/auth/firebase_auth_service.dart';
import '../../data/services/librus_connection_service.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden in ProviderScope');
});

class AppUser {
  final String displayName;
  final String email;
  final String? photoUrl;

  const AppUser({
    required this.displayName,
    required this.email,
    this.photoUrl,
  });
}

class AppUserNotifier extends Notifier<AppUser?> {
  static const _keyEmail = 'app_user_email';
  static const _keyName = 'app_user_name';
  static const _keyPhoto = 'app_user_photo';
  static const _keyIsLoggedIn = 'app_user_is_logged_in';

  @override
  AppUser? build() {
    try {
      final prefs = ref.watch(sharedPreferencesProvider);
      final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
      final email = prefs.getString(_keyEmail);
      final name = prefs.getString(_keyName);
      final photo = prefs.getString(_keyPhoto);

      if (isLoggedIn && email != null && email.isNotEmpty) {
        return AppUser(
          displayName: name ?? 'Użytkownik',
          email: email,
          photoUrl: photo,
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
      } else {
        prefs.setBool(_keyIsLoggedIn, false);
        prefs.remove(_keyEmail);
        prefs.remove(_keyName);
        prefs.remove(_keyPhoto);
      }
    } catch (_) {}
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
