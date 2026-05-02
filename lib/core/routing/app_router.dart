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
import '../../presentation/cloud/backup_picker_screen.dart';
import '../../presentation/cloud/cloud_login_screen.dart';
import '../../presentation/onboarding/onboarding_screen.dart';
import '../../presentation/settings/settings_screen.dart';
import '../../presentation/settings/prestation_catalog_screen.dart';
import '../../presentation/settings/prestation_edit_screen.dart';
import '../../presentation/settings/species_edit_screen.dart';
import '../../presentation/settings/species_management_screen.dart';
import '../../presentation/map/map_screen.dart';
import '../../presentation/tours/tour_completion_screen.dart';
import '../../presentation/tours/tour_detail_screen.dart';
import '../../presentation/tours/tour_draft_screen.dart';
import '../../presentation/tours/tour_manual_picker_screen.dart';
import '../../presentation/tours/tour_optimized_config_screen.dart';
import '../../presentation/tours/tours_list_screen.dart';
import '../../state/providers.dart';

/// Page builder helper — fade + slight slide-up pour push routes.
/// Durée 200ms in / 160ms out, courbe `easeOutCubic`.
CustomTransitionPage<void> _fadeSlidePage(
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 200),
    reverseTransitionDuration: const Duration(milliseconds: 160),
    transitionsBuilder: (context, animation, secondaryAnimation, c) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.025),
            end: Offset.zero,
          ).animate(curved),
          child: c,
        ),
      );
    },
  );
}

class AppRouter {
  AppRouter._();

  static GoRouter forRef(Ref ref) {
    return GoRouter(
      initialLocation: '/clients',
      redirect: (context, state) async {
        // Magic link callback : le SDK Supabase capture le token depuis
        // le launch URI lui-même (hors go_router). Notre seul boulot ici est
        // d'absorber l'URI proprement ; les listeners (cloud_login_screen
        // T21, _FirstSigninResolverHost T23, onboarding T24) feront le reste.
        // Match défensif : selon la version de go_router, l'URI peut arriver
        // comme `coupelaine://auth/callback?...`, `/auth/callback`, ou
        // `/callback` (si `auth` est parsé comme host).
        final loc = state.uri.toString();
        if (loc.contains('auth/callback') || loc.contains('://auth')) {
          return '/';
        }
        if (state.matchedLocation.startsWith('/onboarding')) return null;
        final s = await ref.read(settingsRepositoryProvider).read();
        if (s == null) return '/onboarding';
        // After a restore, BackupPickerScreen calls `context.go('/')` to pop
        // back to the root. There's no `/` route — bounce to the default tab.
        if (state.matchedLocation == '/') return '/clients';
        return null;
      },
      routes: [
        GoRoute(
          path: '/onboarding',
          pageBuilder: (_, state) =>
              _fadeSlidePage(state, const OnboardingScreen()),
        ),
        GoRoute(
          path: '/onboarding/cloud-login',
          pageBuilder: (_, state) =>
              _fadeSlidePage(state, const CloudLoginScreen()),
        ),
        GoRoute(
          path: '/settings/cloud-login',
          pageBuilder: (_, state) =>
              _fadeSlidePage(state, const CloudLoginScreen()),
        ),
        GoRoute(
          path: '/settings/backups',
          pageBuilder: (_, state) =>
              _fadeSlidePage(state, const BackupPickerScreen()),
        ),
        GoRoute(
          path: '/onboarding/restore-pick',
          pageBuilder: (_, state) => _fadeSlidePage(
            state,
            const BackupPickerScreen(requireTypedConfirmation: false),
          ),
        ),
        GoRoute(
          path: '/settings/species',
          pageBuilder: (_, state) =>
              _fadeSlidePage(state, const SpeciesManagementScreen()),
        ),
        GoRoute(
          path: '/settings/species/:id',
          pageBuilder: (_, state) => _fadeSlidePage(
            state,
            SpeciesEditScreen(
              speciesId: int.parse(state.pathParameters['id']!),
            ),
          ),
        ),
        GoRoute(
          path: '/settings/prestations',
          pageBuilder: (_, state) =>
              _fadeSlidePage(state, const PrestationCatalogScreen()),
        ),
        GoRoute(
          path: '/settings/prestations/new',
          pageBuilder: (_, state) =>
              _fadeSlidePage(state, const PrestationEditScreen()),
        ),
        GoRoute(
          path: '/settings/prestations/:id',
          pageBuilder: (_, state) => _fadeSlidePage(
            state,
            PrestationEditScreen(
              id: int.parse(state.pathParameters['id']!),
            ),
          ),
        ),
        GoRoute(
          path: '/proximity/:pivotId',
          pageBuilder: (_, state) => _fadeSlidePage(
            state,
            ProximityScreen(
              pivotId: int.parse(state.pathParameters['pivotId']!),
            ),
          ),
        ),
        GoRoute(
          path: '/tours/draft',
          pageBuilder: (_, state) {
            final raw = state.uri.queryParameters['pivot'];
            return _fadeSlidePage(
              state,
              TourDraftScreen(
                pivotId: raw == null ? null : int.parse(raw),
              ),
            );
          },
        ),
        GoRoute(
          path: '/tours/:id/edit',
          pageBuilder: (_, state) => _fadeSlidePage(
            state,
            TourDraftScreen(
              editingTourId: int.parse(state.pathParameters['id']!),
            ),
          ),
        ),
        GoRoute(
          path: '/tours/new/manual',
          pageBuilder: (_, state) =>
              _fadeSlidePage(state, const TourManualPickerScreen()),
        ),
        GoRoute(
          path: '/tours/new/optimized',
          pageBuilder: (_, state) =>
              _fadeSlidePage(state, const TourOptimizedConfigScreen()),
        ),
        StatefulShellRoute(
          builder: (context, state, shell) => _ShellScaffold(shell: shell),
          // Custom container : on garde toutes les branches mountées (Stack +
          // Offstage) pour préserver l'état par tab, et on fade-in la branche
          // active. Pas d'`indexedStack` par défaut (qui ne s'anime pas).
          navigatorContainerBuilder: (context, shell, children) {
            return Stack(
              children: [
                for (var i = 0; i < children.length; i++)
                  Offstage(
                    offstage: shell.currentIndex != i,
                    child: TickerMode(
                      enabled: shell.currentIndex == i,
                      child: AnimatedOpacity(
                        opacity: shell.currentIndex == i ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 140),
                        curve: Curves.easeOut,
                        child: children[i],
                      ),
                    ),
                  ),
              ],
            );
          },
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/clients',
                builder: (_, __) => const ClientsListScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    pageBuilder: (_, state) =>
                        _fadeSlidePage(state, const ClientFormScreen()),
                  ),
                  GoRoute(
                    path: ':id',
                    pageBuilder: (_, state) => _fadeSlidePage(
                      state,
                      ClientDetailScreen(
                        clientId: int.parse(state.pathParameters['id']!),
                      ),
                    ),
                    routes: [
                      GoRoute(
                        path: 'edit',
                        pageBuilder: (_, state) => _fadeSlidePage(
                          state,
                          ClientFormScreen(
                            clientId: int.parse(state.pathParameters['id']!),
                          ),
                        ),
                      ),
                      GoRoute(
                        path: 'history',
                        pageBuilder: (_, state) => _fadeSlidePage(
                          state,
                          ClientHistoryScreen(
                            clientId: int.parse(state.pathParameters['id']!),
                          ),
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
                    pageBuilder: (_, state) => _fadeSlidePage(
                      state,
                      TourDetailScreen(
                        tourId: int.parse(state.pathParameters['id']!),
                      ),
                    ),
                    routes: [
                      GoRoute(
                        path: 'complete',
                        pageBuilder: (_, state) => _fadeSlidePage(
                          state,
                          TourCompletionScreen(
                            tourId: int.parse(state.pathParameters['id']!),
                          ),
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
      // Note: pas d'AnimatedSwitcher autour de `shell` — StatefulNavigationShell
      // est une instance unique avec un GlobalKey interne ; le wrapper duplique
      // le key pendant la transition. Les transitions inter-tabs restent
      // instantanées (par défaut). Les transitions push (sub-routes) sont
      // animées via `_fadeSlidePage` sur chaque GoRoute.
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
