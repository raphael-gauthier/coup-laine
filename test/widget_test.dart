import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:coup_laine/l10n/app_localizations.dart';

void main() {
  testWidgets('App localisation loads French strings', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('fr'), Locale('en')],
        locale: Locale('fr'),
        home: Scaffold(body: _LocalizedHello()),
      ),
    );
    await tester.pumpAndSettle();
    final l = AppLocalizations.of(
      tester.element(find.byType(_LocalizedHello)),
    )!;
    expect(find.text(l.appTitle), findsOneWidget);
  });
}

class _LocalizedHello extends StatelessWidget {
  const _LocalizedHello();

  @override
  Widget build(BuildContext context) {
    return Text(AppLocalizations.of(context)!.appTitle);
  }
}
