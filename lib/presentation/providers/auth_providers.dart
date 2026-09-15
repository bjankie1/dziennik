import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/firebase_auth_service.dart';
import '../../data/services/librus_connection_service.dart';

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
  @override
  AppUser? build() {
    return null;
  }

  void setUser(AppUser? user) {
    state = user;
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
  return LibrusConnectionService();
});

class LibrusConnectionNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final service = ref.read(librusConnectionServiceProvider);
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
