import 'package:coup_laine/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

/// Choix de l'utilisateur lorsqu'un compte cloud déjà peuplé est détecté
/// à la première connexion.
enum FirstSigninChoice { keepLocal, restoreCloud }

/// Modal non-dismissible : à la première connexion réussie, si le compte
/// cloud a déjà des backups, on demande à l'utilisateur s'il préfère garder
/// les données locales (et les pousser) ou restaurer depuis le cloud.
///
/// Renvoie le choix, ou `null` si l'utilisateur a fermé via system back.
Future<FirstSigninChoice?> showFirstSigninResolverDialog(
  BuildContext context,
) {
  final l = AppLocalizations.of(context)!;
  return showFDialog<FirstSigninChoice>(
    context: context,
    barrierDismissible: false,
    builder: (ctx, style, animation) => FDialog(
      style: style,
      animation: animation,
      title: Text(l.firstSigninTitle),
      body: Text(l.firstSigninMessage),
      actions: [
        FButton(
          variant: FButtonVariant.outline,
          onPress: () =>
              Navigator.of(ctx).pop(FirstSigninChoice.keepLocal),
          child: Text(l.firstSigninKeepLocal),
        ),
        FButton(
          onPress: () =>
              Navigator.of(ctx).pop(FirstSigninChoice.restoreCloud),
          child: Text(l.firstSigninRestoreCloud),
        ),
      ],
    ),
  );
}
