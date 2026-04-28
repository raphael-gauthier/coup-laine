import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:coupe_laine/l10n/app_localizations.dart';

import 'core/config/env.dart';

class CoupeLaineApp extends StatelessWidget {
  const CoupeLaineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (ctx) => AppLocalizations.of(ctx)!.appTitle,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('fr'), Locale('en')],
      locale: const Locale('fr'),
      home: const _SmokeScreen(),
    );
  }
}

class _SmokeScreen extends StatelessWidget {
  const _SmokeScreen();

  @override
  Widget build(BuildContext context) {
    final keyLen = Env.orsApiKey.length;
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.appTitle)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(AppLocalizations.of(context)!.helloDebug),
            const SizedBox(height: 16),
            Text('ORS key length: $keyLen'),
          ],
        ),
      ),
    );
  }
}
