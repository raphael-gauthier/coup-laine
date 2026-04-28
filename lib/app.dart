import 'package:flutter/material.dart';
import 'package:coupe_laine/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

import 'core/theme/app_themes.dart';
import 'state/providers.dart';

class CoupeLaineApp extends ConsumerWidget {
  const CoupeLaineApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        return FTheme(
          data: fTheme,
          child: FToaster(child: child ?? const SizedBox.shrink()),
        );
      },
      routerConfig: router,
    );
  }
}
