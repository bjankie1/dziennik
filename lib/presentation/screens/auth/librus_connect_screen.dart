import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/models/user_role.dart';
import '../../providers/auth_providers.dart';

class LibrusConnectScreen extends ConsumerStatefulWidget {
  const LibrusConnectScreen({super.key});

  @override
  ConsumerState<LibrusConnectScreen> createState() => _LibrusConnectScreenState();
}

class _LibrusConnectScreenState extends ConsumerState<LibrusConnectScreen> {
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  UserRole _selectedRole = UserRole.parent;
  bool _obscurePassword = true;
  bool _isConnecting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleConnect() async {
    final login = _loginController.text.trim();
    final password = _passwordController.text;

    if (login.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Wprowadź login oraz hasło do konta Librus Synergia.';
      });
      return;
    }

    setState(() {
      _isConnecting = true;
      _errorMessage = null;
    });

    try {
      final success = await ref
          .read(librusConnectionStateProvider.notifier)
          .connectLibrus(
            login,
            password,
            role: _selectedRole,
          );

      if (success) {
        ref.read(appUserProvider.notifier).updateRole(_selectedRole);
      } else {
        setState(() {
          _errorMessage =
              'Nie udało się połączyć z serwerem Librus.\nSprawdź poprawność danych lub skorzystaj z trybu demo.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Błąd połączenia: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _isConnecting = false);
      }
    }
  }

  Future<void> _handleUseDemo() async {
    setState(() {
      _isConnecting = true;
      _errorMessage = null;
    });

    await ref.read(librusConnectionStateProvider.notifier).connectDemo();
    ref.read(appUserProvider.notifier).updateRole(_selectedRole);

    if (mounted) {
      setState(() => _isConnecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appUser = ref.watch(appUserProvider);
    final fbUser = ref.watch(firebaseAuthServiceProvider).currentUser;
    final displayName = appUser?.displayName ?? fbUser?.displayName ?? 'Bartosz Jankiewicz';
    final email = appUser?.email ?? fbUser?.email ?? 'bartosz.jankiewicz@gmail.com';
    final photoUrl = appUser?.photoUrl ?? fbUser?.photoURL;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Połączenie z Librusem',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              ref.read(appUserProvider.notifier).setUser(null);
              await ref.read(firebaseAuthServiceProvider).signOut();
            },
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Wyloguj'),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // User info header
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.primaryFixed,
                          backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                          child: photoUrl == null
                              ? const Icon(Icons.person, color: AppColors.primary)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                email,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.check_circle, color: AppColors.secondary, size: 20),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'Konto Librus Synergia',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Wprowadź login i hasło, którymi logujesz się na synergia.librus.pl, aby połączyć aplikację.',
                    style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),

                  // Role Selector
                  SegmentedButton<UserRole>(
                    segments: const [
                      ButtonSegment<UserRole>(
                        value: UserRole.parent,
                        icon: Icon(Icons.family_restroom, size: 18),
                        label: Text('Konto Rodzica'),
                      ),
                      ButtonSegment<UserRole>(
                        value: UserRole.student,
                        icon: Icon(Icons.school, size: 18),
                        label: Text('Konto Ucznia (Oskar)'),
                      ),
                    ],
                    selected: {_selectedRole},
                    onSelectionChanged: (newSelection) {
                      setState(() {
                        _selectedRole = newSelection.first;
                      });
                    },
                    style: const ButtonStyle(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Role Explanation Subtitle Banner
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: _selectedRole.isStudent
                          ? AppColors.primaryFixed.withValues(alpha: 0.5)
                          : AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedRole.isStudent
                            ? AppColors.primary.withValues(alpha: 0.25)
                            : AppColors.outlineVariant.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          _selectedRole.isStudent ? Icons.info_outline : Icons.verified_user_outlined,
                          size: 18,
                          color: _selectedRole.isStudent ? AppColors.primary : AppColors.secondary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _selectedRole.isStudent
                                ? 'Podgląd ocen, planu i terminarza; wysyłanie próśb o usprawiedliwienie do rodzica; wysyłanie wiadomości jako Oskar.'
                                : 'Pełne uprawnienia do zatwierdzania e-usprawiedliwień kodem PIN.',
                            style: TextStyle(
                              fontSize: 12,
                              color: _selectedRole.isStudent ? AppColors.primary : AppColors.onSurfaceVariant,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Form Container
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.surfaceContainerHigh),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Login lub adres e-mail',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.onSurfaceVariant),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _loginController,
                          decoration: InputDecoration(
                            hintText: 'np. 1234567u lub jan.kowalski@email.com',
                            hintStyle: const TextStyle(fontSize: 13, color: AppColors.outline),
                            filled: true,
                            fillColor: AppColors.surfaceContainerLow,
                            prefixIcon: const Icon(Icons.person_outline, size: 20, color: AppColors.outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        const Text(
                          'Hasło do Synergii',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.onSurfaceVariant),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            hintText: 'Hasło do konta Librus',
                            hintStyle: const TextStyle(fontSize: 13, color: AppColors.outline),
                            filled: true,
                            fillColor: AppColors.surfaceContainerLow,
                            prefixIcon: const Icon(Icons.lock_outline, size: 20, color: AppColors.outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                size: 20,
                                color: AppColors.outline,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.errorContainer,
                              borderRadius: BorderRadius.circular(10),
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
                          const SizedBox(height: 14),
                        ],

                        SizedBox(
                          height: 50,
                          child: FilledButton.icon(
                            onPressed: _isConnecting ? null : _handleConnect,
                            icon: _isConnecting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.sync, size: 18),
                            label: const Text(
                              'Połącz i synchronizuj dane',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        SizedBox(
                          height: 46,
                          child: OutlinedButton.icon(
                            onPressed: _isConnecting ? null : _handleUseDemo,
                            icon: const Icon(Icons.dataset_outlined, size: 18),
                            label: const Text(
                              'Użyj konta demo (Maja Kowalska 3B LO)',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.outlineVariant),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Privacy Guarantee Banner
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.shield_outlined, size: 20, color: AppColors.secondary),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Bezpieczeństwo: Twoje hasło i token sesji są zapisywane wyłącznie w szyfrowanym magazynie Twojej przeglądarki/urządzenia i nie są zapisywane w żadnej bazie zewnętrznej.',
                            style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant, height: 1.4),
                          ),
                        ),
                      ],
                    ),
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
