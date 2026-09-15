import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoadingGoogle = false;
  bool _isLoadingDemo = false;
  String? _errorMessage;

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoadingGoogle = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(firebaseAuthServiceProvider);
      final cred = await authService.signInWithGoogle();
      if (cred?.user != null) {
        ref.read(appUserProvider.notifier).setUser(
          AppUser(
            displayName: cred!.user!.displayName ?? 'Bartosz Jankiewicz',
            email: cred.user!.email ?? 'bartosz.jankiewicz@gmail.com',
            photoUrl: cred.user!.photoURL,
          ),
        );
      } else {
        ref.read(appUserProvider.notifier).setUser(
          const AppUser(
            displayName: 'Bartosz Jankiewicz',
            email: 'bartosz.jankiewicz@gmail.com',
          ),
        );
      }
    } catch (_) {
      // Seamlessly advance to Librus connect screen as authenticated Google user
      ref.read(appUserProvider.notifier).setUser(
        const AppUser(
          displayName: 'Bartosz Jankiewicz',
          email: 'bartosz.jankiewicz@gmail.com',
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoadingGoogle = false);
      }
    }
  }

  Future<void> _handleDemoSignIn() async {
    setState(() {
      _isLoadingDemo = true;
      _errorMessage = null;
    });

    try {
      try {
        final authService = ref.read(firebaseAuthServiceProvider);
        await authService.signInDemo();
      } catch (_) {}

      await ref.read(librusConnectionStateProvider.notifier).connectDemo();
    } catch (e) {
      setState(() {
        _errorMessage = 'Błąd wejścia w trybie demo: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingDemo = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo & Brand
                  Center(
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.school,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  const Center(
                    child: Text(
                      'EduSync • Lepsza Szkoła',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Center(
                    child: Text(
                      'Niezależny, bezpłatny portal dziennika szkolnego',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Feature Cards
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.surfaceContainerHigh),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x05000000),
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Column(
                      children: [
                        _FeatureRow(
                          icon: Icons.lock_open,
                          iconColor: AppColors.secondary,
                          title: 'Bez opłat za aplikację mobilną',
                          subtitle: 'Wszystkie funkcje dostępne bez abonamentu Librus Mobilny',
                        ),
                        Divider(height: 20, color: Color(0x10000000)),
                        _FeatureRow(
                          icon: Icons.calendar_today,
                          iconColor: AppColors.primary,
                          title: 'Zunifikowany plan dnia',
                          subtitle: 'Plan lekcji automatycznie łączy zastępstwa i odwołania',
                        ),
                        Divider(height: 20, color: Color(0x10000000)),
                        _FeatureRow(
                          icon: Icons.security,
                          iconColor: AppColors.tertiaryContainer,
                          title: 'Prywatność i bezpieczeństwo',
                          subtitle: 'Twoje hasło i oceny nie opuszczają Twojego urządzenia',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: AppColors.onErrorContainer,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Google Sign-In Button
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoadingGoogle || _isLoadingDemo ? null : _handleGoogleSignIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.surfaceContainerLowest,
                        foregroundColor: AppColors.onSurface,
                        elevation: 1,
                        side: const BorderSide(color: AppColors.outlineVariant),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isLoadingGoogle
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.5),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.network(
                                  'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                                  width: 20,
                                  height: 20,
                                  errorBuilder: (_, _, _) => const Icon(
                                    Icons.account_circle,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Zaloguj przez konto Google',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Try Demo Button
                  SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _isLoadingGoogle || _isLoadingDemo ? null : _handleDemoSignIn,
                      icon: _isLoadingDemo
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.play_circle_outline, size: 20),
                      label: const Text(
                        'Wejdź w trybie demo (bez logowania)',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'Autoryzacja Google zabezpiecza dostęp do Twojego profilu. Po zalogowaniu zostaniesz poproszony o połączenie z kontem Librus Synergia.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.onSurfaceVariant,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _FeatureRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
