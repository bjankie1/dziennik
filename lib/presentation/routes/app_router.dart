import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_providers.dart';
import '../providers/school_providers.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/librus_connect_screen.dart';
import '../screens/main_navigation_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/schedule/schedule_screen.dart';
import '../screens/grades/grades_screen.dart';
import '../screens/attendance/attendance_screen.dart';
import '../screens/messages/messages_screen.dart';
import '../screens/messages/message_thread_screen.dart';
import '../../domain/models/message_thread.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'rootNav');
final shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shellNav');

final appRouterProvider = Provider<GoRouter>((ref) {
  final authStateAsync = ref.watch(authStateProvider);
  final appUser = ref.watch(appUserProvider);
  final librusConnAsync = ref.watch(librusConnectionStateProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/pulpit',
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final isAuthLoading = authStateAsync.isLoading;
      final hasUser = authStateAsync.value != null || appUser != null;
      final isLibrusConnected = librusConnAsync.value ?? false;

      final isLoggingIn = state.matchedLocation == '/logowanie';
      final isConnectingLibrus = state.matchedLocation == '/polacz-librus';

      if (isAuthLoading) {
        return null; // Don't redirect while determining initial auth
      }

      // 1. Unauthenticated -> force login, preserve redirect param
      if (!hasUser) {
        if (!isLoggingIn) {
          final target = state.uri.toString();
          if (target != '/' && target != '/pulpit' && target != '/logowanie') {
            return '/logowanie?redirect=${Uri.encodeComponent(target)}';
          }
          return '/logowanie';
        }
        return null;
      }

      // 2. Authenticated, but not connected to Librus
      if (!isLibrusConnected) {
        if (!isConnectingLibrus) {
          return '/polacz-librus';
        }
        return null;
      }

      // 3. Fully connected, but accessing auth screens -> forward to target redirect or /pulpit
      if (isLoggingIn || isConnectingLibrus) {
        final redirectParam = state.uri.queryParameters['redirect'];
        if (redirectParam != null && redirectParam.isNotEmpty) {
          return Uri.decodeComponent(redirectParam);
        }
        return '/pulpit';
      }

      // 4. Root "/" forwards to "/pulpit"
      if (state.matchedLocation == '/') {
        return '/pulpit';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/logowanie',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/polacz-librus',
        builder: (context, state) => const LibrusConnectScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainNavigationScreen(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Pulpit
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/pulpit',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          // Branch 1: Plan lekcji
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/plan-lekcji',
                builder: (context, state) {
                  // If query param "data=YYYY-MM-DD" is present, parse and update providers
                  final dateParam = state.uri.queryParameters['data'];
                  if (dateParam != null) {
                    try {
                      final parsed = DateTime.parse(dateParam);
                      final monday = DateTime(parsed.year, parsed.month, parsed.day)
                          .subtract(Duration(days: parsed.weekday - 1));
                      final dayIndex = (parsed.weekday - 1).clamp(0, 4);
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        ref.read(selectedWeekMondayProvider.notifier).setMonday(monday);
                        ref.read(selectedScheduleDayProvider.notifier).setDay(dayIndex);
                      });
                    } catch (_) {}
                  }
                  return const ScheduleScreen();
                },
              ),
            ],
          ),
          // Branch 2: Oceny
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/oceny',
                builder: (context, state) {
                  final semParam = state.uri.queryParameters['semestr'];
                  final term = int.tryParse(semParam ?? '');
                  return GradesScreen(initialTerm: term);
                },
              ),
            ],
          ),
          // Branch 3: Frekwencja
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/frekwencja',
                builder: (context, state) {
                  final filterParam = state.uri.queryParameters['filtr'];
                  int? filter;
                  if (filterParam == 'wszystkie') filter = 0;
                  if (filterParam == 'do-usprawiedliwienia') filter = 1;
                  if (filterParam == 'usprawiedliwione') filter = 2;
                  return AttendanceScreen(initialFilter: filter);
                },
              ),
            ],
          ),
          // Branch 4: Wiadomości
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/wiadomosci',
                builder: (context, state) => const MessagesScreen(),
                routes: [
                  GoRoute(
                    path: ':threadId',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) {
                      final threadId = state.pathParameters['threadId'] ?? '';
                      final extra = state.extra;

                      if (extra is MessageThread) {
                        return MessageThreadScreen(thread: extra);
                      }

                      // Deep link from external URL: fetch or find from messages provider
                      final messagesAsync = ref.watch(messagesProvider);
                      final thread = messagesAsync.value?.where((m) => m.id == threadId).firstOrNull;

                      if (thread != null) {
                        return MessageThreadScreen(thread: thread);
                      }

                      return Scaffold(
                        appBar: AppBar(
                          title: const Text('Szczegóły wiadomości'),
                          leading: IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () => context.go('/wiadomosci'),
                          ),
                        ),
                        body: messagesAsync.isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text('Nie znaleziono wiadomości.'),
                                    const SizedBox(height: 12),
                                    ElevatedButton(
                                      onPressed: () => context.go('/wiadomosci'),
                                      child: const Text('Wróć do wiadomości'),
                                    ),
                                  ],
                                ),
                              ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
