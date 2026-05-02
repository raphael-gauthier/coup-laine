import 'package:coup_laine/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/design_tokens.dart';
import '../../domain/models/backup_meta.dart';
import '../../infra/services/json_export_service.dart';
import '../../state/providers.dart';
import '../clients/clients_list_screen.dart'
    show
        clientsAsyncProvider,
        clientsPendingProvider,
        clientNotesMapProvider,
        settingsForChipProvider;
import '../map/map_screen.dart' show settingsForMapProvider;
import '../tours/tours_list_screen.dart' show toursAsyncProvider;
import '../widgets/app_empty_state.dart';
import '../widgets/app_error_state.dart';
import '../widgets/app_header.dart';
import '../widgets/app_list_tile.dart';
import 'restore_confirm_dialog.dart';

/// Liste des backups dispo pour le user courant. `autoDispose` car la liste
/// peut changer entre deux ouvertures (autre device qui push, rotation
/// 3-deep). Forme la donnée en récupérant la liste brute du service.
final _backupsListProvider =
    FutureProvider.autoDispose<List<BackupMeta>>((ref) {
  return ref.watch(backupServiceProvider).listAvailable();
});

/// Écran de sélection d'un backup à restaurer. Deux entrées possibles :
/// - `/settings/backups` (Settings → Restaurer) → `requireTypedConfirmation: true`
/// - `/onboarding/restore-pick` (Onboarding) → `requireTypedConfirmation: false`
class BackupPickerScreen extends ConsumerWidget {
  final bool requireTypedConfirmation;

  const BackupPickerScreen({
    super.key,
    this.requireTypedConfirmation = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final async = ref.watch(_backupsListProvider);

    return FScaffold(
      child: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppHeader(title: l.backupPickerTitle),
            Expanded(
              child: async.when(
                loading: () => const Center(child: FCircularProgress()),
                error: (e, _) => AppErrorState(
                  message: e.toString(),
                  onRetry: () => ref.invalidate(_backupsListProvider),
                ),
                data: (list) => list.isEmpty
                    ? AppEmptyState(
                        icon: FIcons.cloudOff,
                        title: l.backupPickerTitle,
                        body: l.backupPickerEmpty,
                      )
                    : _BackupList(
                        backups: list,
                        requireTypedConfirmation: requireTypedConfirmation,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackupList extends ConsumerWidget {
  final List<BackupMeta> backups;
  final bool requireTypedConfirmation;

  const _BackupList({
    required this.backups,
    required this.requireTypedConfirmation,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      padding: AppSizes.screenPadding,
      itemCount: backups.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, i) {
        final meta = backups[i];
        final l = AppLocalizations.of(context)!;
        return AppListTile(
          variant: AppListTileVariant.standard,
          prefix: const Icon(FIcons.cloud),
          title: _formatLabel(context, meta.createdAt),
          subtitle: l.backupPickerSizeKb((meta.sizeBytes / 1024).round()),
          onTap: () => _handleTap(context, ref, meta),
        );
      },
    );
  }

  Future<void> _handleTap(
    BuildContext context,
    WidgetRef ref,
    BackupMeta meta,
  ) async {
    final confirmed = await showRestoreConfirmDialog(
      context: context,
      requireTypedConfirmation: requireTypedConfirmation,
    );
    if (!confirmed) return;
    if (!context.mounted) return;
    await _runRestore(context, ref, meta);
  }
}

String _formatLabel(BuildContext context, DateTime when) {
  final l = AppLocalizations.of(context)!;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final whenDay = DateTime(when.year, when.month, when.day);
  final hm = DateFormat.Hm().format(when);
  if (whenDay == today) return l.backupPickerToday(hm);
  final yesterday = today.subtract(const Duration(days: 1));
  if (whenDay == yesterday) return l.backupPickerYesterday(hm);
  return DateFormat.yMMMMd().add_Hm().format(when);
}

/// Lance la restauration : spinner non-dismissible, await restore, invalide
/// les providers root, pop jusqu'à la racine, snackbar de succès. Erreur
/// "schema futur" différenciée du cas générique.
Future<void> _runRestore(
  BuildContext context,
  WidgetRef ref,
  BackupMeta meta,
) async {
  final l = AppLocalizations.of(context)!;

  // Spinner barrier-dismissible-false
  showFDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx, style, animation) => FDialog(
      style: style,
      animation: animation,
      title: Text(l.restoreInProgress),
      body: const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Center(child: FCircularProgress()),
      ),
      actions: const [],
    ),
  );

  try {
    await ref.read(backupServiceProvider).restore(meta);
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // dismiss spinner

    // Invalide les providers root qui lisent les tables affectées par
    // l'import. Liste explicite — pas de "invalidate everything".
    ref.invalidate(settingsRepositoryFutureProvider);
    ref.invalidate(settingsForMapProvider);
    ref.invalidate(settingsForChipProvider);
    ref.invalidate(clientsAsyncProvider);
    ref.invalidate(clientsPendingProvider);
    ref.invalidate(clientNotesMapProvider);
    ref.invalidate(toursAsyncProvider);
    ref.invalidate(activeSpeciesProvider);
    ref.invalidate(archivedSpeciesProvider);
    ref.invalidate(allCategoriesByIdProvider);
    ref.invalidate(categoryDisplayInfoProvider);
    ref.invalidate(activeCategoriesBySpeciesProvider);
    ref.invalidate(activePrestationsProvider);
    ref.invalidate(archivedPrestationsProvider);
    ref.invalidate(activePrestationsByCategoryProvider);
    ref.invalidate(prestationCountActiveProvider);
    ref.invalidate(themeModeProvider);

    if (!context.mounted) return;
    showFToast(context: context, title: Text(l.restoreSuccess));
    // Pop jusqu'à la racine (sortir du picker + de tout sub-écran).
    context.go('/');
  } on JsonImportException catch (e) {
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    final isFutureSchema = e.message.contains('non supportée');
    showFToast(
      context: context,
      title: Text(
        isFutureSchema ? l.restoreFailedFutureSchema : l.restoreFailedGeneric,
      ),
    );
  } catch (_) {
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    showFToast(context: context, title: Text(l.restoreFailedGeneric));
  }
}
