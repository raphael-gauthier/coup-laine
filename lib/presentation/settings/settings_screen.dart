import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:coup_laine/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart' show ShareParams, SharePlus;

import '../../core/design_tokens.dart';
import '../../domain/models/settings.dart';
import '../../domain/use_cases/client_status.dart';
import '../../state/providers.dart';
import '../clients/clients_list_screen.dart' show clientsAsyncProvider, clientsPendingProvider;
import '../tours/tours_list_screen.dart' show toursAsyncProvider;
import '../widgets/address_autocomplete_field.dart';
import '../widgets/app_primary_button.dart';
import '../widgets/app_section_card.dart';
import '../widgets/avatar_picker.dart';
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
          body: const Text(
            "L'adresse de départ a changé. Recalculer toutes les distances "
            'depuis le nouveau point de départ ?',
          ),
          actions: [
            FButton(
              variant: FButtonVariant.outline,
              onPress: () => Navigator.of(context).pop(false),
              child: const Text('Plus tard'),
            ),
            FButton(
              onPress: () => Navigator.of(context).pop(true),
              child: const Text('Recalculer'),
            ),
          ],
        ),
      );
      if (ok == true) {
        await ref.read(distanceMatrixSyncProvider).recomputeAllForBase();
      }
    }
    if (!mounted) return;
    showFToast(context: context, title: const Text('Enregistré'));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = context.theme;

    return SingleChildScrollView(
      padding: AppSizes.rootScreenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Page heading
          Text(
            l.tabSettings,
            style: theme.typography.xl3.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colors.foreground,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

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
                const SizedBox(height: AppSpacing.md),
                Text(
                  l.settingsAppAvatarTitle,
                  style: theme.typography.sm.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colors.foreground,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l.settingsAppAvatarSubtitle,
                  style: theme.typography.sm.copyWith(
                    color: theme.colors.mutedForeground,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                AvatarPicker(
                  selectedKey: _draft.appAvatarKey,
                  onSelect: (key) async {
                    final next = _draft.copyWith(appAvatarKey: key);
                    setState(() => _draft = next);
                    await ref.read(settingsRepositoryProvider).save(next);
                    ref.invalidate(themeModeProvider);
                    ref.invalidate(_settingsAsyncProvider);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // --- Espèces & catégories ---
          AppSectionCard(
            icon: FIcons.tag,
            title: l.speciesManagementTitle,
            child: Consumer(
              builder: (context, ref, _) {
                final activeAsync = ref.watch(activeSpeciesProvider);
                final catsAsync = ref.watch(activeCategoriesBySpeciesProvider);
                final speciesCount =
                    activeAsync.hasValue ? activeAsync.value!.length : 0;
                final catCount = catsAsync.hasValue
                    ? catsAsync.value!.values
                        .fold<int>(0, (a, b) => a + b.length)
                    : 0;
                return FTile(
                  title: Text(
                    l.speciesManagementCountFmt(speciesCount, catCount),
                  ),
                  suffix: const Icon(FIcons.chevronRight),
                  onPress: () => context.push('/settings/species'),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),

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

          // --- Valeurs par défaut ---
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

          // --- Couleurs des marqueurs ---
          AppSectionCard(
            icon: FIcons.droplet,
            title: 'Couleurs des marqueurs',
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

          // --- Saison ---
          AppSectionCard(
            icon: FIcons.calendar,
            title: l.settingsSeasonTitle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l.settingsSeasonStartedFmt(
                    DateFormat('dd/MM/yyyy').format(_draft.seasonStartedAt),
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
                    final ok = await showFDialog<bool>(
                      context: context,
                      builder: (ctx, style, animation) => FDialog(
                        style: style,
                        animation: animation,
                        title: Text(l.settingsSeasonResetConfirmTitle),
                        body: Text(l.settingsSeasonResetConfirmBody),
                        actions: [
                          FButton(
                            variant: FButtonVariant.outline,
                            onPress: () => Navigator.of(ctx).pop(false),
                            child: const Text('Annuler'),
                          ),
                          FButton(
                            variant: FButtonVariant.destructive,
                            onPress: () => Navigator.of(ctx).pop(true),
                            child: Text(l.settingsSeasonResetButton),
                          ),
                        ],
                      ),
                    );
                    if (ok != true) return;
                    final now = DateTime.now();
                    await ref.read(settingsRepositoryProvider).bumpSeasonStartedAt(now);
                    await ref.read(clientRepositoryProvider).resetAllWaiting();
                    ref.invalidate(_settingsAsyncProvider);
                    ref.invalidate(clientsAsyncProvider);
                    if (!mounted) return;
                    setState(() {
                      _draft = _draft.copyWith(seasonStartedAt: now);
                    });
                    showFToast(
                      context: context, // ignore: use_build_context_synchronously
                      title: Text(l.settingsSeasonResetButton),
                    );
                  },
                  child: Text(l.settingsSeasonResetButton),
                ),
              ],
            ),
          ),
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
                    final dir = await getTemporaryDirectory();
                    final file = File(p.join(dir.path,
                        'coup-laine-${DateTime.now().millisecondsSinceEpoch}.json'));
                    await file.writeAsString(body);
                    await SharePlus.instance.share(
                      ShareParams(files: [XFile(file.path)]),
                    );
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
                    final ok = await showFDialog<bool>(
                      context: context, // ignore: use_build_context_synchronously
                      builder: (context, style, animation) => FDialog(
                        style: style,
                        animation: animation,
                        body: const Text(
                            'Cette action remplace toutes les données actuelles. Continuer ?'),
                        actions: [
                          FButton(
                            variant: FButtonVariant.outline,
                            onPress: () => Navigator.of(context).pop(false),
                            child: const Text('Annuler'),
                          ),
                          FButton(
                            onPress: () => Navigator.of(context).pop(true),
                            child: const Text('Importer'),
                          ),
                        ],
                      ),
                    );
                    if (ok == true) {
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
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // --- Save bar ---
          AppPrimaryButton(
            label: l.settingsSave,
            onPress: _isDirty ? _save : null,
          ),
        ],
      ),
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
    final settingsAsync = ref.watch(_settingsAsyncProvider);
    final currentMode = settingsAsync.value?.themeMode ?? ThemeModePreference.system;
    final isActive = currentMode == mode;

    return FTile(
      prefix: Icon(icon),
      title: Text(label),
      selected: isActive,
      onPress: isActive
          ? null
          : () async {
              await ref.read(settingsRepositoryProvider).setThemeMode(mode);
              ref.invalidate(themeModeProvider);
              ref.invalidate(_settingsAsyncProvider);
            },
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
