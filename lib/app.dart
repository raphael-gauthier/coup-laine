import 'package:flutter/material.dart';
import 'package:coupe_laine/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

import 'state/providers.dart';

class CoupeLaineApp extends ConsumerWidget {
  const CoupeLaineApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    return MaterialApp.router(
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
      theme: FThemes.neutral.light.touch.toApproximateMaterialTheme(),
      builder: (context, child) => FTheme(
        data: FThemes.neutral.light.touch,
        child: FToaster(
          child: child ?? const SizedBox.shrink(),
        ),
      ),
      routerConfig: router,
    );
  }
}
