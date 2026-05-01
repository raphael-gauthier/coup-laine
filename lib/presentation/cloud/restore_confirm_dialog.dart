import 'package:coup_laine/l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

import '../../core/design_tokens.dart';

/// Mot-clé à taper pour confirmer la restauration. Hardcodé en FR car
/// l'app est FR-first ; les utilisateurs de la locale EN devront aussi
/// taper "RESTAURER" — choix documenté dans le plan T22.
const String _confirmKeyword = 'RESTAURER';

/// Affiche un dialogue de confirmation destructive pour la restauration
/// d'un backup. Si [requireTypedConfirmation] est `true`, le bouton
/// « Restaurer » reste désactivé tant que l'utilisateur n'a pas tapé
/// exactement [_confirmKeyword] dans le champ. Sinon (flow onboarding),
/// le bouton est toujours actif.
///
/// Retourne `true` si confirmé, `false` ou `null` (barrier dismiss) si
/// annulé — l'appelant doit traiter `null` comme false.
Future<bool> showRestoreConfirmDialog({
  required BuildContext context,
  required bool requireTypedConfirmation,
}) async {
  final ok = await showFDialog<bool>(
    context: context,
    builder: (ctx, style, animation) {
      return _RestoreConfirmDialog(
        style: style,
        animation: animation,
        requireTypedConfirmation: requireTypedConfirmation,
      );
    },
  );
  return ok == true;
}

class _RestoreConfirmDialog extends StatefulWidget {
  final FDialogStyle style;
  final Animation<double> animation;
  final bool requireTypedConfirmation;

  const _RestoreConfirmDialog({
    required this.style,
    required this.animation,
    required this.requireTypedConfirmation,
  });

  @override
  State<_RestoreConfirmDialog> createState() => _RestoreConfirmDialogState();
}

class _RestoreConfirmDialogState extends State<_RestoreConfirmDialog> {
  final _ctrl = TextEditingController();
  bool _matches = false;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_onChanged);
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onChanged);
    _ctrl.dispose();
    super.dispose();
  }

  void _onChanged() {
    final next = _ctrl.text.trim() == _confirmKeyword;
    if (next != _matches) setState(() => _matches = next);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = context.theme;
    final canConfirm = widget.requireTypedConfirmation ? _matches : true;

    return FDialog(
      style: widget.style,
      animation: widget.animation,
      title: Text(l.restoreConfirmTitleSettings),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.restoreConfirmMessageSettings,
            style: theme.typography.sm.copyWith(
              color: theme.colors.foreground,
            ),
          ),
          if (widget.requireTypedConfirmation) ...[
            const SizedBox(height: AppSpacing.md),
            FTextField(
              control: FTextFieldControl.managed(controller: _ctrl),
              hint: l.restoreConfirmTypePromptSettings,
              autocorrect: false,
              textCapitalization: TextCapitalization.characters,
            ),
          ],
        ],
      ),
      actions: [
        FButton(
          variant: FButtonVariant.outline,
          onPress: () => Navigator.of(context).pop(false),
          child: Text(l.restoreConfirmCancelButton),
        ),
        FButton(
          variant: FButtonVariant.destructive,
          onPress: canConfirm
              ? () {
                  HapticFeedback.heavyImpact();
                  Navigator.of(context).pop(true);
                }
              : null,
          child: Text(l.restoreConfirmConfirmButton),
        ),
      ],
    );
  }
}
