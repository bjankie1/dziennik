import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/auth_providers.dart';
import '../main_navigation_screen.dart';
import 'login_screen.dart';
import 'librus_connect_screen.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authStateAsync = ref.watch(authStateProvider);
    final appUser = ref.watch(appUserProvider);

    // 1. Check if user is authenticated with Firebase / Google
    return authStateAsync.when(
      data: (user) {
        if (user == null && appUser == null) {
          return const LoginScreen();
        }

        // 2. User is authenticated, check Librus connection
        final librusConnAsync = ref.watch(librusConnectionStateProvider);
        return librusConnAsync.when(
          data: (isConnected) {
            if (isConnected) {
              return const MainNavigationScreen();
            }
            return const LibrusConnectScreen();
          },
          loading: () => const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
          error: (_, _) => const LibrusConnectScreen(),
        );
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (_, _) => const LoginScreen(),
    );
  }
}
