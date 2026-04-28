import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:coupe_laine/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart' show ShareParams, SharePlus;

import '../../core/design_tokens.dart';
import '../../domain/models/settings.dart';
import '../../state/providers.dart';
import '../clients/clients_list_screen.dart' show clientsAsyncProvider, clientsPendingProvider;
import '../tours/tours_list_screen.dart' show toursAsyncProvider;
import '../widgets/address_autocomplete_field.dart';
import '../widgets/app_list_tile.dart';
import '../widgets/app_primary_button.dart';
import '../widgets/app_section_card.dart';

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
      child: async.when(
        loading: () => const Center(child: FCircularProgress()),
        error: (e, _) => Center(child: Text('$e')),
        data: (s) => s == null
            ? const SizedBox.shrink()
            : _SettingsForm(initial: s),
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

  // Controllers for the three numeric fields — kept alive for the widget lifetime.
  late final TextEditingController _radiusCtrl;
  late final TextEditingController _minPerSheepCtrl;
  late final TextEditingController _tariffCtrl;

  @override
  void initState() {
    super.initState();
    _draft = widget.initial;
    _radiusCtrl = TextEditingController(text: _draft.defaultRadiusKm.toString());
    _minPerSheepCtrl = TextEditingController(text: _draft.defaultMinutesPerSheep.toString());
    _tariffCtrl = TextEditingController(text: _draft.travelFeeEurosPerBracket.toString());
  }

  @override
  void dispose() {
    _radiusCtrl.dispose();
    _minPerSheepCtrl.dispose();
    _tariffCtrl.dispose();
    super.dispose();
  }

  bool get _isDirty =>
      _draft.baseAddressLabel != widget.initial.baseAddressLabel ||
      _draft.baseCoordinates != widget.initial.baseCoordinates ||
      _draft.defaultRadiusKm != widget.initial.defaultRadiusKm ||
      _draft.defaultMinutesPerSheep != widget.initial.defaultMinutesPerSheep ||
      _draft.travelFeeEurosPerBracket != widget.initial.travelFeeEurosPerBracket;

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
            "L'adresse de base a changé. Recalculer toutes les distances "
            'depuis la nouvelle base ?',
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
                const SizedBox(height: 12),
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
                const SizedBox(height: 12),
                FTextField(
                  control: FTextFieldControl.managed(
                    controller: _minPerSheepCtrl,
                    onChange: (v) {
                      final n = int.tryParse(v.text);
                      if (n != null && n > 0) {
                        setState(() => _draft = _draft.copyWith(defaultMinutesPerSheep: n));
                      }
                    },
                  ),
                  label: Text(l.settingsMinPerSheepLabel),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 12),
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

          // --- Données ---
          AppSectionCard(
            icon: FIcons.database,
            title: l.settingsDataTitle,
            child: Column(
              children: [
                AppListTile(
                  prefix: const Icon(FIcons.upload),
                  title: l.settingsExportData,
                  suffix: const Icon(FIcons.chevronRight),
                  onPress: () async {
                    final svc = ref.read(jsonExportServiceProvider);
                    final body = await svc.exportToJsonString();
                    final dir = await getTemporaryDirectory();
                    final file = File(p.join(dir.path,
                        'coupe-laine-${DateTime.now().millisecondsSinceEpoch}.json'));
                    await file.writeAsString(body);
                    await SharePlus.instance.share(
                      ShareParams(files: [XFile(file.path)]),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                AppListTile(
                  prefix: const Icon(FIcons.download),
                  title: l.settingsImportData,
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
    final theme = context.theme;

    return AppListTile(
      prefix: Icon(icon),
      title: label,
      suffix: isActive
          ? Icon(FIcons.check, color: theme.colors.primary)
          : null,
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
