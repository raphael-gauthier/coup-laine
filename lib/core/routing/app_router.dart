import 'package:flutter/material.dart';
import 'package:coup_laine/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/clients/client_detail_screen.dart';
import '../../presentation/clients/client_history_screen.dart';
import '../../presentation/proximity/proximity_screen.dart';
import '../../presentation/clients/client_form_screen.dart';
import '../../presentation/clients/clients_list_screen.dart';
import '../../presentation/onboarding/onboarding_screen.dart';
import '../../presentation/settings/settings_screen.dart';
import '../../presentation/map/map_screen.dart';
import '../../presentation/tours/tour_completion_screen.dart';
import '../../presentation/tours/tour_detail_screen.dart';
import '../../presentation/tours/tour_draft_screen.dart';
import '../../presentation/tours/tour_manual_picker_screen.dart';
import '../../presentation/tours/tour_optimized_config_screen.dart';
import '../../presentation/tours/tours_list_screen.dart';
import '../../state/providers.dart';

class AppRouter {
  AppRouter._();

  static GoRouter forRef(Ref ref) {
    return GoRouter(
      initialLocation: '/clients',
      redirect: (context, state) async {
        if (state.matchedLocation == '/onboarding') return null;
        final s = await ref.read(settingsRepositoryProvider).read();
        return s == null ? '/onboarding' : null;
      },
      routes: [
        GoRoute(
          path: '/onboarding',
          builder: (_, __) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/proximity/:pivotId',
          builder: (_, state) => ProximityScreen(
            pivotId: int.parse(state.pathParameters['pivotId']!),
          ),
        ),
        GoRoute(
          path: '/tours/draft',
          builder: (_, state) {
            final raw = state.uri.queryParameters['pivot'];
            return TourDraftScreen(
              pivotId: raw == null ? null : int.parse(raw),
            );
          },
        ),
        GoRoute(
          path: '/tours/:id/edit',
          builder: (_, state) => TourDraftScreen(
            editingTourId: int.parse(state.pathParameters['id']!),
          ),
        ),
        GoRoute(
          path: '/tours/new/manual',
          builder: (_, __) => const TourManualPickerScreen(),
        ),
        GoRoute(
          path: '/tours/new/optimized',
          builder: (_, __) => const TourOptimizedConfigScreen(),
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => _ShellScaffold(shell: shell),
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/clients',
                builder: (_, __) => const ClientsListScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (_, __) => const ClientFormScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (_, state) => ClientDetailScreen(
                      clientId: int.parse(state.pathParameters['id']!),
                    ),
                    routes: [
                      GoRoute(
                        path: 'edit',
                        builder: (_, state) => ClientFormScreen(
                          clientId: int.parse(state.pathParameters['id']!),
                        ),
                      ),
                      GoRoute(
                        path: 'history',
                        builder: (_, state) => ClientHistoryScreen(
                          clientId: int.parse(state.pathParameters['id']!),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/tours',
                builder: (_, __) => const ToursListScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (_, state) => TourDetailScreen(
                      tourId: int.parse(state.pathParameters['id']!),
                    ),
                    routes: [
                      GoRoute(
                        path: 'complete',
                        builder: (_, state) => TourCompletionScreen(
                          tourId: int.parse(state.pathParameters['id']!),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/map',
                builder: (_, __) => const MapScreen(),
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/settings',
                builder: (_, __) => const SettingsScreen(),
              ),
            ]),
          ],
        ),
      ],
    );
  }
}

class _ShellScaffold extends StatelessWidget {
  final StatefulNavigationShell shell;
  const _ShellScaffold({required this.shell});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = context.theme;
    return Scaffold(
      backgroundColor: theme.colors.background,
      resizeToAvoidBottomInset: true,
      body: shell,
      bottomNavigationBar: FBottomNavigationBar(
        index: shell.currentIndex,
        onChange: (i) => shell.goBranch(i, initialLocation: true),
        children: [
          FBottomNavigationBarItem(
            icon: const Icon(FIcons.users),
            label: Text(l.tabClients),
          ),
          FBottomNavigationBarItem(
            icon: const Icon(FIcons.route),
            label: Text(l.tabTours),
          ),
          FBottomNavigationBarItem(
            icon: const Icon(FIcons.compass),
            label: Text(l.tabMap),
          ),
          FBottomNavigationBarItem(
            icon: const Icon(FIcons.settings),
            label: Text(l.tabSettings),
          ),
        ],
      ),
    );
  }
}
