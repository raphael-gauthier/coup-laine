import 'package:flutter/widgets.dart';
import 'package:coup_laine/l10n/app_localizations.dart';
import 'package:flutter/material.dart'
    show showModalBottomSheet, Icon, IconButton, Icons, Material, ListTile;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_tokens.dart';
import '../../data/seeds/species_seeds.dart';
import '../../domain/models/settings.dart';
import '../../infra/services/ban_geocoding_service.dart';
import '../../state/providers.dart';
import '../widgets/address_autocomplete_field.dart';
import '../widgets/app_primary_button.dart';
import '../widgets/app_section_card.dart';
import 'custom_species_form_sheet.dart';

class _CustomSpeciesDraft {
  final String name;
  final List<String> categoryNames;
  const _CustomSpeciesDraft({
    required this.name,
    required this.categoryNames,
  });
}

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _step = 0;
  GeocodingResult? _picked;
  final Set<int> _seedSpeciesActive = {};
  final List<_CustomSpeciesDraft> _customSpecies = [];
  bool _saving = false;

  bool get _step1Ready => _picked != null;
  bool get _step2Ready =>
      _seedSpeciesActive.isNotEmpty || _customSpecies.isNotEmpty;

  Future<void> _confirm() async {
    final picked = _picked;
    if (picked == null) return;
    setState(() => _saving = true);
    try {
      final db = ref.read(appDatabaseProvider);
      final speciesRepo = ref.read(speciesRepositoryProvider);
      final catsRepo = ref.read(animalCategoryRepositoryProvider);
      final prestationRepo = ref.read(prestationRepositoryProvider);
      final settingsRepo = ref.read(settingsRepositoryProvider);

      await db.transaction(() async {
        for (final i in _seedSpeciesActive) {
          final seed = kSpeciesSeeds[i];
          final speciesId = await speciesRepo.insert(name: seed.name);
          for (final cat in seed.categories) {
            final catId =
                await catsRepo.insert(speciesId: speciesId, name: cat.name);
            if (cat.defaultPrestationName != null) {
              await prestationRepo.insert(
                name: cat.defaultPrestationName!,
                priceCents: null,
                minutes: null,
                categoryId: catId,
              );
            }
          }
        }
        for (final cs in _customSpecies) {
          final speciesId = await speciesRepo.insert(name: cs.name);
          for (final catName in cs.categoryNames) {
            await catsRepo.insert(speciesId: speciesId, name: catName);
          }
        }
        await settingsRepo.save(Settings(
          baseCoordinates: picked.coordinates,
          baseAddressLabel: picked.label,
          seasonStartedAt: DateTime.now(),
        ));
      });
      ref.invalidate(activePrestationsProvider);
      ref.invalidate(prestationCountActiveProvider);
      if (!mounted) return;
      context.go('/clients');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _openCustomSpeciesSheet() async {
    final result = await showModalBottomSheet<CustomSpeciesFormSheetResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const CustomSpeciesFormSheet(),
    );
    if (result == null) return;
    setState(() {
      _customSpecies.add(_CustomSpeciesDraft(
        name: result.name,
        categoryNames: result.categoryNames,
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FScaffold(
        resizeToAvoidBottomInset: true,
        child: IndexedStack(
          index: _step,
          children: [_buildStep1(context), _buildStep2(context)],
        ),
      ),
    );
  }

  Widget _buildStep1(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = context.theme;
    return SingleChildScrollView(
      padding: AppSizes.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Center(
              child: Image.asset(
                'assets/illustrations/sheep-mascot.png',
                height: 160,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Text(
            l.appTitle,
            textAlign: TextAlign.center,
            style: theme.typography.xl4.copyWith(
              color: theme.colors.foreground,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l.onboardingHeroSubtitle,
            textAlign: TextAlign.center,
            style: theme.typography.lg.copyWith(
              color: theme.colors.mutedForeground,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppSectionCard(
            icon: FIcons.sparkles,
            title: l.onboardingWelcomeTitle,
            child: Text(
              l.onboardingWelcomeBody,
              style: theme.typography.md.copyWith(
                color: theme.colors.foreground,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppSectionCard(
            icon: FIcons.mapPin,
            title: l.onboardingAddressTitle,
            child: AddressAutocompleteField(
              onPicked: (r) => setState(() => _picked = r),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppPrimaryButton(
            label: l.onboardingStep1Cta,
            prefixIcon: FIcons.arrowRight,
            onPress: _step1Ready ? () => setState(() => _step = 1) : null,
          ),
        ],
      ),
    );
  }

  Widget _buildStep2(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = context.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: l.onboardingPrevious,
              onPressed: () => setState(() => _step = 0),
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: AppSizes.screenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l.onboardingStep2Title,
                  textAlign: TextAlign.center,
                  style: theme.typography.xl3.copyWith(
                    color: theme.colors.foreground,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l.onboardingStep2Subtitle,
                  textAlign: TextAlign.center,
                  style: theme.typography.md.copyWith(
                    color: theme.colors.mutedForeground,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Species selection card.
                AppSectionCard(
                  icon: FIcons.tag,
                  title: l.onboardingStep2Title,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < kSpeciesSeeds.length; i++)
                        _SeedSpeciesTile(
                          seed: kSpeciesSeeds[i],
                          checked: _seedSpeciesActive.contains(i),
                          onToggle: () => setState(() {
                            if (_seedSpeciesActive.contains(i)) {
                              _seedSpeciesActive.remove(i);
                            } else {
                              _seedSpeciesActive.add(i);
                            }
                          }),
                        ),
                      for (var i = 0; i < _customSpecies.length; i++)
                        _CustomSpeciesTile(
                          draft: _customSpecies[i],
                          onRemove: () => setState(() {
                            _customSpecies.removeAt(i);
                          }),
                        ),
                      const SizedBox(height: AppSpacing.sm),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FButton(
                          variant: FButtonVariant.outline,
                          onPress: _openCustomSpeciesSheet,
                          child: Text(l.onboardingAddCustomSpecies),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                AppPrimaryButton(
                  label: l.onboardingCtaFinish,
                  prefixIcon: FIcons.check,
                  onPress: _step2Ready ? _confirm : null,
                  loading: _saving,
                ),
                if (!_step2Ready) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l.onboardingErrorNoSpecies,
                    textAlign: TextAlign.center,
                    style: theme.typography.sm.copyWith(
                      color: theme.colors.destructive,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SeedSpeciesTile extends StatelessWidget {
  final SpeciesSeed seed;
  final bool checked;
  final VoidCallback onToggle;
  const _SeedSpeciesTile({
    required this.seed,
    required this.checked,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Material(
      color: const Color(0x00000000),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(
          checked ? Icons.check_box : Icons.check_box_outline_blank,
          color: checked ? theme.colors.primary : theme.colors.mutedForeground,
        ),
        title: Text(seed.name),
        subtitle: Text(seed.categories.map((c) => c.name).join(', ')),
        onTap: onToggle,
      ),
    );
  }
}

class _CustomSpeciesTile extends StatelessWidget {
  final _CustomSpeciesDraft draft;
  final VoidCallback onRemove;
  const _CustomSpeciesTile({
    required this.draft,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0x00000000),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.check_box),
        title: Text(draft.name),
        subtitle: Text(draft.categoryNames.join(', ')),
        trailing: IconButton(
          icon: const Icon(Icons.close),
          onPressed: onRemove,
        ),
      ),
    );
  }
}
