import 'package:flutter/material.dart';
import 'package:coup_laine/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_themes.dart';
import 'presentation/cloud/first_signin_resolver_dialog.dart';
import 'state/providers.dart';

class CoupeLaineApp extends ConsumerWidget {
  const CoupeLaineApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Démarrer le scheduler (effet de bord : s'abonne au lifecycle).
    ref.watch(backupSchedulerProvider);
    final router = ref.watch(goRouterProvider);
    final modeAsync = ref.watch(themeModeProvider);
    final mode = modeAsync.value ?? ThemeMode.system;

    final lightFTheme = appLightTheme;
    final darkFTheme = appDarkTheme;

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (ctx) => AppLocalizations.of(ctx)!.appTitle,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        ...FLocalizations.localizationsDelegates,
      ],
      supportedLocales: const [Locale('fr'), Locale('en')],
      locale: const Locale('fr'),
      theme: lightFTheme.toApproximateMaterialTheme(),
      darkTheme: darkFTheme.toApproximateMaterialTheme(),
      themeMode: mode,
      builder: (context, child) {
        final brightness = Theme.of(context).brightness;
        final fTheme = brightness == Brightness.dark ? darkFTheme : lightFTheme;
        // Paint the theme background under everything so the SafeArea
        // status-bar inset on top-level routes (i.e. routes outside the
        // shell scaffold) doesn't reveal the OS-default black behind.
        return FTheme(
          data: fTheme,
          child: FToaster(
            // The first-sign-in resolver listener lives here (inside
            // MaterialApp's builder) — at this position we have access to
            // Localizations, FToaster, and the GoRouter delegate, none of
            // which exist at CoupeLaineApp's own build context.
            child: _FirstSigninResolverHost(
              child: ColoredBox(
                color: fTheme.colors.background,
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          ),
        );
      },
      routerConfig: router,
    );
  }
}

/// Listens for `false → true` transitions of [isCloudOptedInProvider]
/// (i.e. successful first sign-in) and either auto-pushes a backup
/// (cloud account empty) or shows the resolver dialog (existing backups).
///
/// Skipped while we're in onboarding mode — Task 24 wires its own local
/// listener so the onboarding flow can drive the choice with its own UI.
class _FirstSigninResolverHost extends ConsumerWidget {
  final Widget child;
  const _FirstSigninResolverHost({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<bool>(isCloudOptedInProvider, (previous, current) async {
      if (previous != false || current != true) return;

      // GUARD: don't run the resolver in onboarding mode (T24 will handle
      // that flow with its own local listener).
      final routerPath = ref
          .read(goRouterProvider)
          .routerDelegate
          .currentConfiguration
          .uri
          .path;
      if (routerPath.startsWith('/onboarding')) return;

      final t = AppLocalizations.of(context)!;
      final service = ref.read(backupServiceProvider);
      try {
        final pushed = await service.resolveInitialStateAfterOptIn();
        if (!context.mounted) return;
        if (pushed) {
          showFToast(
            context: context,
            title: Text(t.firstSigninInitialBackup),
          );
          return;
        }
        final choice = await showFirstSigninResolverDialog(context);
        if (!context.mounted) return;
        if (choice == FirstSigninChoice.keepLocal) {
          await service.runBackup();
          if (!context.mounted) return;
          showFToast(
            context: context,
            title: Text(t.firstSigninInitialBackup),
          );
        } else if (choice == FirstSigninChoice.restoreCloud) {
          GoRouter.of(context).push('/onboarding/restore-pick');
        }
      } catch (e) {
        debugPrint('First sign-in resolution failed: $e');
      }
    });
    return child;
  }
}
