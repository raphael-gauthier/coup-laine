// lib/core/ui/confirm_dialog.dart
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

/// Dialog de confirmation pour action destructive (suppression, reset, etc.).
/// Pattern unifié v3 : title direct, body court qui explique la conséquence,
/// actions `Annuler outline` + `<actionLabel> destructive`. Haptique heavy
/// quand l'utilisateur confirme.
///
/// Retourne `true` si confirmé, `false` ou `null` si annulé.
Future<bool> showDestructiveConfirm(
  BuildContext context, {
  required String title,
  required String body,
  String cancelLabel = 'Annuler',
  String confirmLabel = 'Supprimer',
}) async {
  final ok = await showFDialog<bool>(
    context: context,
    builder: (ctx, style, animation) => FDialog(
      style: style,
      animation: animation,
      title: Text(title),
      body: Text(body),
      actions: [
        FButton(
          variant: FButtonVariant.outline,
          onPress: () => Navigator.of(ctx).pop(false),
          child: Text(cancelLabel),
        ),
        FButton(
          variant: FButtonVariant.destructive,
          onPress: () {
            HapticFeedback.heavyImpact();
            Navigator.of(ctx).pop(true);
          },
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return ok == true;
}
