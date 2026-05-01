import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:coup_laine/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

import '../../core/design_tokens.dart';
import '../../core/ui/confirm_dialog.dart';
import '../../domain/models/settings.dart';
import '../../domain/use_cases/client_status.dart';
import '../../state/providers.dart';
import '../clients/clients_list_screen.dart' show clientsAsyncProvider, clientsPendingProvider;
import '../tours/tours_list_screen.dart' show toursAsyncProvider;
import '../widgets/address_autocomplete_field.dart';
import '../widgets/app_action_bar.dart';
import '../widgets/app_header.dart';
import '../widgets/app_list_tile.dart';
import '../widgets/app_option_tile.dart';
import '../widgets/app_primary_button.dart';
import '../widgets/app_section_card.dart';
import '../widgets/app_command_palette_actions.dart';
import '../widgets/color_swatch_picker.dart';

Color _hexToColor(String hex) {
  final cleaned = hex.replaceAll('#', '');
  return Color(int.parse(cleaned, radix: 16) | 0xFF000000);
}

String _colorToHex(Color c) {
  // Drop the alpha channel — we only persist RGB.
  final argb = c.toARGB32();
  final hex = (argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase();
  return '#$hex';
}

final _settingsAsyncProvider = FutureProvider<Settings?>((ref) {
  return ref.watch(settingsRepositoryProvider).read();
});

/// Nombre de backups disponibles pour le user courant. Renvoie 0 si pas
/// de session non-anonyme (au lieu de throw) pour simplifier l'UI.
final _backupCountProvider = FutureProvider.autoDispose<int>((ref) async {
  if (!ref.watch(isCloudOptedInProvider)) return 0;
  try {
    return await ref.watch(backupsRepositoryProvider).countForCurrentUser();
  } catch (_) {
    return 0;
  }
});

String _formatRelative(DateTime when) {
  final now = DateTime.now();
  final diff = now.difference(when);
  if (diff.inMinutes < 1) return 'à l\'instant';
  if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'il y a ${diff.inHours} h';
  return 'il y a ${diff.inDays} j';
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_settingsAsyncProvider);
    return FScaffold(
      resizeToAvoidBottomInset: true,
      child: SafeArea(
        top: true,
        bottom: false,
        child: async.when(
          loading: () => const Center(child: FCircularProgress()),
          error: (e, _) => Center(child: Text('$e')),
          data: (s) => s == null
              ? const SizedBox.shrink()
              : _SettingsForm(initial: s),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Form
// ---------------------------------------------------------------------------

class _SettingsForm extends ConsumerStatefulWidget {
  final Settings initial;
  const _SettingsForm({required this.initial});

  @override
  ConsumerState<_SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends ConsumerState<_SettingsForm> {
  late Settings _draft;

  // Controllers for numeric fields — kept alive for the widget lifetime.
  late final TextEditingController _radiusCtrl;
  late final TextEditingController _bracketKmCtrl;
  late final TextEditingController _tariffCtrl;

  @override
  void initState() {
    super.initState();
    _draft = widget.initial;
    _radiusCtrl = TextEditingController(text: _draft.defaultRadiusKm.toString());
    _bracketKmCtrl = TextEditingController(text: _draft.bracketKm.toString());
    _tariffCtrl = TextEditingController(text: _draft.travelFeeEurosPerBracket.toString());
  }

  @override
  void dispose() {
    _radiusCtrl.dispose();
    _bracketKmCtrl.dispose();
    _tariffCtrl.dispose();
    super.dispose();
  }

  bool get _isDirty =>
      _draft.baseAddressLabel != widget.initial.baseAddressLabel ||
      _draft.baseCoordinates != widget.initial.baseCoordinates ||
      _draft.defaultRadiusKm != widget.initial.defaultRadiusKm ||
      _draft.bracketKm != widget.initial.bracketKm ||
      _draft.travelFeeEurosPerBracket != widget.initial.travelFeeEurosPerBracket;

  Future<void> _persistMarkerColor(ClientStatus status, String hex) async {
    await ref.read(settingsRepositoryProvider).updateMarkerColor(status, hex);
    ref.invalidate(_settingsAsyncProvider);
    ref.invalidate(clientsAsyncProvider);
    if (!mounted) return;
    setState(() {
      _draft = switch (status) {
        ClientStatus.defaultStatus =>
          _draft.copyWith(markerDefaultColor: hex),
        ClientStatus.waiting =>
          _draft.copyWith(markerWaitingColor: hex),
        ClientStatus.scheduled =>
          _draft.copyWith(markerScheduledColor: hex),
        ClientStatus.done =>
          _draft.copyWith(markerDoneColor: hex),
        ClientStatus.noAnimals =>
          _draft.copyWith(markerNoAnimalsColor: hex),
        ClientStatus.banned =>
          _draft.copyWith(markerBannedColor: hex),
      };
    });
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context)!;
    final didBaseChange =
        _draft.baseAddressLabel != widget.initial.baseAddressLabel ||
            _draft.baseCoordinates != widget.initial.baseCoordinates;
    await ref.read(settingsRepositoryProvider).save(_draft);
    ref.invalidate(_settingsAsyncProvider);
    if (!mounted) return;
    if (didBaseChange) {
      final ok = await showFDialog<bool>(
        context: context,
        builder: (context, style, animation) => FDialog(
          style: style,
          animation: animation,
          body: Text(l.settingsBaseAddressChangedDialogBody),
          actions: [
            FButton(
              variant: FButtonVariant.outline,
              onPress: () => Navigator.of(context).pop(false),
              child: Text(l.commonLater),
            ),
            FButton(
              onPress: () => Navigator.of(context).pop(true),
              child: Text(l.commonRecompute),
            ),
          ],
        ),
      );
      if (ok == true) {
        await ref.read(distanceMatrixSyncProvider).recomputeAllForBase();
      }
    }
    if (!mounted) return;
    showFToast(context: context, title: Text(l.commonSaved));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = context.theme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppHeader(
          title: l.tabSettings,
          showBackButton: false,
          onTitleLongPress: () => showAppCommandPalette(context, ref),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: AppSizes.screenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- Adresse de base ---
                AppSectionCard(
                  icon: FIcons.house,
                  title: l.settingsBaseAddressTitle,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _draft.baseAddressLabel,
                        style: theme.typography.sm.copyWith(
                          color: theme.colors.mutedForeground,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AddressAutocompleteField(
                        labelText: l.settingsBaseAddressEdit,
                        onPicked: (r) => setState(() {
                          _draft = _draft.copyWith(
                            baseAddressLabel: r.label,
                            baseCoordinates: r.coordinates,
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // --- Apparence ---
                AppSectionCard(
                  icon: FIcons.palette,
                  title: l.settingsAppearanceTitle,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ThemeOption(
                        mode: ThemeModePreference.system,
                        icon: FIcons.monitor,
                        label: l.settingsThemeSystem,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _ThemeOption(
                        mode: ThemeModePreference.light,
                        icon: FIcons.sun,
                        label: l.settingsThemeLight,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _ThemeOption(
                        mode: ThemeModePreference.dark,
                        icon: FIcons.moon,
                        label: l.settingsThemeDark,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // --- Couleurs des marqueurs ---
                AppSectionCard(
                  icon: FIcons.droplet,
                  title: l.settingsMarkerColorsTitle,
                  child: Column(
                    children: [
                      _MarkerColorRow(
                        label: l.settingsMarkerDefault,
                        currentHex: _draft.markerDefaultColor,
                        defaultHex: '#9CA3AF',
                        onPicked: (hex) => _persistMarkerColor(ClientStatus.defaultStatus, hex),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _MarkerColorRow(
                        label: l.settingsMarkerWaiting,
                        currentHex: _draft.markerWaitingColor,
                        defaultHex: '#EAB308',
                        onPicked: (hex) => _persistMarkerColor(ClientStatus.waiting, hex),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _MarkerColorRow(
                        label: l.settingsMarkerScheduled,
                        currentHex: _draft.markerScheduledColor,
                        defaultHex: '#65A30D',
                        onPicked: (hex) => _persistMarkerColor(ClientStatus.scheduled, hex),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _MarkerColorRow(
                        label: l.settingsMarkerDone,
                        currentHex: _draft.markerDoneColor,
                        defaultHex: '#166534',
                        onPicked: (hex) => _persistMarkerColor(ClientStatus.done, hex),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _MarkerColorRow(
                        label: l.settingsMarkerNoAnimals,
                        currentHex: _draft.markerNoAnimalsColor,
                        defaultHex: '#1F2937',
                        onPicked: (hex) => _persistMarkerColor(ClientStatus.noAnimals, hex),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _MarkerColorRow(
                        label: l.settingsMarkerBanned,
                        currentHex: _draft.markerBannedColor,
                        defaultHex: '#B91C1C',
                        onPicked: (hex) => _persistMarkerColor(ClientStatus.banned, hex),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // --- Optimisation tournée ---
                AppSectionCard(
                  icon: FIcons.slidersHorizontal,
                  title: l.settingsDefaultsTitle,
                  child: Column(
                    children: [
                      FTextField(
                        control: FTextFieldControl.managed(
                          controller: _radiusCtrl,
                          onChange: (v) {
                            final n = int.tryParse(v.text);
                            if (n != null && n > 0) {
                              setState(() => _draft = _draft.copyWith(defaultRadiusKm: n));
                            }
                          },
                        ),
                        label: Text(l.settingsRadiusLabel),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      FTextField(
                        control: FTextFieldControl.managed(
                          controller: _bracketKmCtrl,
                          onChange: (v) {
                            final n = int.tryParse(v.text);
                            if (n != null && n > 0) {
                              setState(() => _draft = _draft.copyWith(bracketKm: n));
                            }
                          },
                        ),
                        label: Text(l.settingsBracketKmLabel),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      FTextField(
                        control: FTextFieldControl.managed(
                          controller: _tariffCtrl,
                          onChange: (v) {
                            final n = int.tryParse(v.text);
                            if (n != null && n > 0) {
                              setState(() => _draft = _draft.copyWith(travelFeeEurosPerBracket: n));
                            }
                          },
                        ),
                        label: Text(l.settingsTariffLabel),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // --- Espèces & catégories ---
                Consumer(
                  builder: (context, ref, _) {
                    final activeAsync = ref.watch(activeSpeciesProvider);
                    final catsAsync = ref.watch(activeCategoriesBySpeciesProvider);
                    final speciesCount =
                        activeAsync.hasValue ? activeAsync.value!.length : 0;
                    final catCount = catsAsync.hasValue
                        ? catsAsync.value!.values
                            .fold<int>(0, (a, b) => a + b.length)
                        : 0;
                    return AppListTile(
                      variant: AppListTileVariant.standard,
                      title: l.speciesManagementTitle,
                      subtitle: l.speciesManagementCountFmt(speciesCount, catCount),
                      suffix: const Icon(FIcons.chevronRight),
                      onTap: () => context.push('/settings/species'),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.sm),

                // --- Catalogue de prestations ---
                Consumer(
                  builder: (context, ref, _) {
                    final countAsync = ref.watch(prestationCountActiveProvider);
                    final subtitle = countAsync.when(
                      loading: () => '…',
                      error: (_, __) => '',
                      data: (n) => l.prestationCatalogCountFmt(n),
                    );
                    return AppListTile(
                      variant: AppListTileVariant.standard,
                      title: l.prestationCatalogTitle,
                      subtitle: subtitle,
                      suffix: const Icon(FIcons.chevronRight),
                      onTap: () => context.push('/settings/prestations'),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // --- Compte cloud ---
                const _CloudAccountSection(),
                const SizedBox(height: AppSpacing.md),

                // --- Données ---
                AppSectionCard(
                  icon: FIcons.database,
                  title: l.settingsDataTitle,
                  child: Column(
                    children: [
                      FTile(
                        prefix: const Icon(FIcons.upload),
                        title: Text(l.settingsExportData),
                        suffix: const Icon(FIcons.chevronRight),
                        onPress: () async {
                          final svc = ref.read(jsonExportServiceProvider);
                          final body = await svc.exportToJsonString();
                          final location = await getSaveLocation(
                            suggestedName:
                                'coup-laine-${DateTime.now().millisecondsSinceEpoch}.json',
                            acceptedTypeGroups: const [
                              XTypeGroup(
                                label: 'JSON',
                                extensions: ['json'],
                              ),
                            ],
                          );
                          if (location == null) return;
                          await File(location.path).writeAsString(body);
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      FTile(
                        prefix: const Icon(FIcons.download),
                        title: Text(l.settingsImportData),
                        suffix: const Icon(FIcons.chevronRight),
                        onPress: () async {
                          final picked = await openFile(
                            acceptedTypeGroups: [
                              const XTypeGroup(
                                label: 'JSON',
                                extensions: ['json'],
                              ),
                            ],
                          );
                          if (picked == null) return;
                          final body = await picked.readAsString();
                          if (!mounted) return;
                          final ok = await showDestructiveConfirm(
                            context, // ignore: use_build_context_synchronously
                            title: l.settingsImportConfirmTitle,
                            body: l.settingsImportConfirmBody,
                            confirmLabel: l.settingsImportConfirmAction,
                          );
                          if (ok) {
                            await ref
                                .read(jsonExportServiceProvider)
                                .importFromJsonString(body);
                            ref.invalidate(_settingsAsyncProvider);
                            ref.invalidate(clientsAsyncProvider);
                            ref.invalidate(clientsPendingProvider);
                            ref.invalidate(toursAsyncProvider);
                          }
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // --- Saison (destructive) ---
                      _SeasonResetTile(draft: _draft, onReset: (now) {
                        setState(() {
                          _draft = _draft.copyWith(seasonStartedAt: now);
                        });
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),

        // --- Save bar (shown only when dirty) ---
        if (_isDirty)
          AppActionBar(
            primary: AppPrimaryButton(
              label: l.settingsSave,
              onPress: _save,
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Theme option tile
// ---------------------------------------------------------------------------

class _ThemeOption extends ConsumerWidget {
  final ThemeModePreference mode;
  final IconData icon;
  final String label;

  const _ThemeOption({
    required this.mode,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final settingsAsync = ref.watch(_settingsAsyncProvider);
    final currentMode = settingsAsync.value?.themeMode ?? ThemeModePreference.system;
    final isActive = currentMode == mode;

    return AppOptionTile(
      leading: Icon(icon, size: 18, color: theme.colors.foreground),
      title: label,
      checked: isActive,
      onChanged: isActive
          ? null
          : (_) async {
              await ref.read(settingsRepositoryProvider).setThemeMode(mode);
              ref.invalidate(themeModeProvider);
              ref.invalidate(_settingsAsyncProvider);
            },
    );
  }
}

// ---------------------------------------------------------------------------
// Season reset tile (destructive)
// ---------------------------------------------------------------------------

class _SeasonResetTile extends ConsumerWidget {
  final Settings draft;
  final void Function(DateTime now) onReset;

  const _SeasonResetTile({required this.draft, required this.onReset});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = context.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.settingsSeasonStartedFmt(
            DateFormat('dd/MM/yyyy').format(draft.seasonStartedAt),
          ),
          style: theme.typography.sm.copyWith(
            color: theme.colors.mutedForeground,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        FButton(
          variant: FButtonVariant.destructive,
          prefix: const Icon(FIcons.rotateCcw),
          onPress: () async {
            final ok = await showDestructiveConfirm(
              context,
              title: l.settingsSeasonResetConfirmTitle,
              body: l.settingsSeasonResetConfirmBody,
              confirmLabel: l.settingsSeasonResetButton,
            );
            if (!ok) return;
            final now = DateTime.now();
            await ref.read(settingsRepositoryProvider).bumpSeasonStartedAt(now);
            await ref.read(clientRepositoryProvider).resetAllWaiting();
            // Invalidate settings + status providers so client detail / list /
            // map recompute their statuses with the new seasonStartedAt.
            ref.invalidate(settingsRepositoryFutureProvider);
            ref.invalidate(_settingsAsyncProvider);
            ref.invalidate(clientsAsyncProvider);
            ref.invalidate(toursAsyncProvider);
            if (!context.mounted) return;
            onReset(now);
            showFToast(
              context: context, // ignore: use_build_context_synchronously
              title: Text(l.settingsSeasonResetButton),
            );
          },
          child: Text(l.settingsSeasonResetButton),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Cloud account section
// ---------------------------------------------------------------------------

class _CloudAccountSection extends ConsumerWidget {
  const _CloudAccountSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = context.theme;
    final optedIn = ref.watch(isCloudOptedInProvider);
    final session = ref.watch(currentSessionProvider);
    final settingsAsync = ref.watch(_settingsAsyncProvider);

    return AppSectionCard(
      icon: FIcons.cloud,
      title: l.settingsCloudSection,
      child: !optedIn
          ? AppPrimaryButton(
              label: l.settingsCloudActivate,
              prefixIcon: FIcons.cloud,
              onPress: () => context.push('/settings/cloud-login'),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l.settingsCloudConnectedAs(session?.user.email ?? ''),
                  style: theme.typography.sm.copyWith(
                    color: theme.colors.foreground,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  settingsAsync.value?.lastBackupAt == null
                      ? l.settingsCloudLastBackupNever
                      : l.settingsCloudLastBackupAgo(
                          _formatRelative(settingsAsync.value!.lastBackupAt!),
                        ),
                  style: theme.typography.sm.copyWith(
                    color: theme.colors.mutedForeground,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _BackupNowButton(),
                const SizedBox(height: AppSpacing.sm),
                _RestoreButton(),
                const SizedBox(height: AppSpacing.sm),
                AppPrimaryButton(
                  label: l.settingsCloudSignOut,
                  variant: FButtonVariant.outline,
                  onPress: () => _confirmSignOut(context, ref),
                ),
              ],
            ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context)!;
    final ok = await showDestructiveConfirm(
      context,
      title: l.settingsCloudSignOut,
      body: l.settingsCloudSignOutConfirm,
      confirmLabel: l.settingsCloudSignOut,
    );
    if (!ok) return;
    await ref.read(authServiceProvider).signOut();
  }
}

class _BackupNowButton extends ConsumerStatefulWidget {
  @override
  ConsumerState<_BackupNowButton> createState() => _BackupNowButtonState();
}

class _BackupNowButtonState extends ConsumerState<_BackupNowButton> {
  bool _running = false;

  Future<void> _run() async {
    final l = AppLocalizations.of(context)!;
    setState(() => _running = true);
    try {
      await ref.read(backupServiceProvider).runBackup();
      ref.invalidate(_settingsAsyncProvider);
      ref.invalidate(settingsRepositoryFutureProvider);
      ref.invalidate(_backupCountProvider);
      if (!mounted) return;
      showFToast(context: context, title: Text(l.settingsCloudBackupSuccess));
    } catch (_) {
      if (!mounted) return;
      showFToast(context: context, title: Text(l.settingsCloudBackupFailed));
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AppPrimaryButton(
      label: l.settingsCloudBackupNow,
      prefixIcon: FIcons.cloudUpload,
      loading: _running,
      onPress: _running ? null : _run,
    );
  }
}

class _RestoreButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final countAsync = ref.watch(_backupCountProvider);
    final hasBackups = countAsync.value != null && countAsync.value! > 0;
    if (!hasBackups) return const SizedBox.shrink();
    return AppPrimaryButton(
      label: l.settingsCloudRestore,
      variant: FButtonVariant.outline,
      prefixIcon: FIcons.cloudDownload,
      onPress: () => context.push('/settings/backups'),
    );
  }
}

// ---------------------------------------------------------------------------
// Marker color row
// ---------------------------------------------------------------------------

class _MarkerColorRow extends StatelessWidget {
  final String label;
  final String currentHex;
  final String defaultHex;
  final ValueChanged<String> onPicked;

  const _MarkerColorRow({
    required this.label,
    required this.currentHex,
    required this.defaultHex,
    required this.onPicked,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return FTile(
      prefix: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: _hexToColor(currentHex),
          shape: BoxShape.circle,
          border: Border.all(color: theme.colors.border),
        ),
      ),
      title: Text(label),
      subtitle: Text(currentHex.toUpperCase()),
      suffix: const Icon(FIcons.chevronRight),
      onPress: () async {
        final picked = await showColorSwatchPicker(
          context: context,
          current: _hexToColor(currentHex),
          defaultColor: _hexToColor(defaultHex),
          title: 'Couleur — $label',
        );
        if (picked != null) onPicked(_colorToHex(picked));
      },
    );
  }
}
