// lib/presentation/widgets/app_error_state.dart
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

import '../../core/design_tokens.dart';
import 'app_primary_button.dart';

/// État d'erreur standardisé. Icône triangleAlert destructive, message
/// clair, bouton « Réessayer » primary, bouton « Détails » outline qui
/// toggle l'affichage de `details` (typiquement le stack trace).
class AppErrorState extends StatefulWidget {
  final String message;
  final String? details;
  final VoidCallback? onRetry;
  final String retryLabel;
  final String detailsLabel;

  const AppErrorState({
    super.key,
    required this.message,
    this.details,
    this.onRetry,
    this.retryLabel = 'Réessayer',
    this.detailsLabel = 'Détails',
  });

  @override
  State<AppErrorState> createState() => _AppErrorStateState();
}

class _AppErrorStateState extends State<AppErrorState> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.huge,
        AppSpacing.xl,
        AppSpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(FIcons.triangleAlert,
              size: AppSizes.heroIconCircle, color: theme.colors.destructive),
          const SizedBox(height: AppSpacing.lg),
          Text(
            widget.message,
            textAlign: TextAlign.center,
            style: theme.typography.xl2.copyWith(color: theme.colors.foreground),
          ),
          if (widget.onRetry != null) ...[
            const SizedBox(height: AppSpacing.xl),
            AppPrimaryButton(
              label: widget.retryLabel,
              onPress: widget.onRetry,
            ),
          ],
          if (widget.details != null) ...[
            const SizedBox(height: AppSpacing.sm),
            FButton(
              variant: FButtonVariant.outline,
              size: FButtonSizeVariant.sm,
              onPress: () => setState(() => _expanded = !_expanded),
              child: Text(_expanded ? 'Masquer ${widget.detailsLabel.toLowerCase()}' : widget.detailsLabel),
            ),
            if (_expanded) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: theme.colors.muted,
                  borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                ),
                child: Text(
                  widget.details!,
                  style: theme.typography.xs.copyWith(
                    color: theme.colors.mutedForeground,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
