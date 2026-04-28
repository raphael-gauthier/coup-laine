import 'package:flutter/material.dart';
import 'package:coupe_laine/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/clients/client_detail_screen.dart';
import '../../presentation/proximity/proximity_screen.dart';
import '../../presentation/clients/client_form_screen.dart';
import '../../presentation/clients/clients_list_screen.dart';
import '../../presentation/onboarding/onboarding_screen.dart';
import '../../presentation/settings/settings_screen.dart';
import '../../presentation/tours/tour_detail_screen.dart';
import '../../presentation/tours/tour_draft_screen.dart';
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
          builder: (_, state) => TourDraftScreen(
            pivotId: int.parse(state.uri.queryParameters['pivot']!),
          ),
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
                  ),
                ],
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
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) =>
            shell.goBranch(i, initialLocation: i == shell.currentIndex),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.people_outline),
            selectedIcon: const Icon(Icons.people),
            label: l.tabClients,
          ),
          NavigationDestination(
            icon: const Icon(Icons.alt_route_outlined),
            selectedIcon: const Icon(Icons.alt_route),
            label: l.tabTours,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: l.tabSettings,
          ),
        ],
      ),
    );
  }
}
