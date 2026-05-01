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
import '../cloud/first_signin_resolver_dialog.dart';
import '../widgets/address_autocomplete_field.dart';
import '../widgets/app_action_bar.dart';
import '../widgets/app_primary_button.dart';
import '../widgets/app_section_card.dart';
import '../widgets/app_stepper.dart';
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
  // 0 = welcome (zero vs restore), 1 = address, 2 = species, 3 = recap.
  int _step = 0;
  GeocodingResult? _picked;
  final Set<int> _seedSpeciesActive = {};
  final List<_CustomSpeciesDraft> _customSpecies = [];
  bool _saving = false;

  bool get _addressReady => _picked != null;
  bool get _speciesReady =>
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

  Future<void> _onRestore() async {
    await context.push('/onboarding/cloud-login');
  }

  /// Local listener: handles `false → true` of `isCloudOptedInProvider` while
  /// in onboarding. The global host listener in `app.dart` skips this case
  /// (guard on `/onboarding`), so the resolver runs here instead — the user
  /// either gets pushed an empty initial backup (continue onboarding), keeps
  /// local (continue onboarding), or restores from cloud (route to picker).
  Future<void> _handleFirstSignin() async {
    final service = ref.read(backupServiceProvider);
    final pushed = await service.resolveInitialStateAfterOptIn();
    if (!mounted) return;
    if (pushed) {
      // Cloud was empty. The local DB is essentially empty too at this point
      // (we're mid-onboarding), so the "initial backup" is fine — just
      // continue to the address step.
      setState(() => _step = 1);
      return;
    }
    final choice = await showFirstSigninResolverDialog(context);
    if (!mounted) return;
    if (choice == FirstSigninChoice.keepLocal) {
      // Same as the empty-cloud case — continue onboarding.
      setState(() => _step = 1);
    } else if (choice == FirstSigninChoice.restoreCloud) {
      context.push('/onboarding/restore-pick');
    }
    // null choice (system back) → stay on welcome step.
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    ref.listen<bool>(isCloudOptedInProvider, (prev, curr) {
      if (prev == false && curr == true) {
        _handleFirstSignin();
      }
    });

    final showStepper = _step > 0;
    final showActionBar = _step > 0;

    return SafeArea(
      child: FScaffold(
        resizeToAvoidBottomInset: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showStepper)
              AppStepper(
                currentIndex: _step - 1,
                labels: [
                  l.onboardingStep1Label,
                  l.onboardingStep2Label,
                  l.onboardingStep3Label,
                ],
              ),
            Expanded(
              child: IndexedStack(
                index: _step,
                children: [
                  _buildWelcomeStep(context),
                  _buildAddressStep(context),
                  _buildSpeciesStep(context),
                  _buildRecapStep(context),
                ],
              ),
            ),
            if (showActionBar) _buildActionBar(context, l),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBar(BuildContext context, AppLocalizations l) {
    if (_step == 3) {
      return AppActionBar(
        primary: AppPrimaryButton(
          label: l.onboardingStep3CtaStart,
          prefixIcon: FIcons.check,
          onPress: _saving ? null : _confirm,
          loading: _saving,
        ),
      );
    }
    return AppActionBar(
      secondary: AppPrimaryButton(
        label: l.onboardingPrevious,
        onPress: _step <= 1 ? null : () => setState(() => _step -= 1),
        variant: FButtonVariant.outline,
      ),
      primary: AppPrimaryButton(
        label: l.onboardingStep1Cta,
        prefixIcon: FIcons.arrowRight,
        onPress: _stepForwardReady ? () => setState(() => _step += 1) : null,
      ),
    );
  }

  bool get _stepForwardReady {
    if (_step == 1) return _addressReady;
    if (_step == 2) return _speciesReady;
    return false;
  }

  Widget _buildWelcomeStep(BuildContext context) {
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
            l.onboardingWelcomeTitle,
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
          const SizedBox(height: AppSpacing.xl),
          AppPrimaryButton(
            label: l.onboardingWelcomeStartFresh,
            prefixIcon: FIcons.arrowRight,
            onPress: () => setState(() => _step = 1),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppPrimaryButton(
            label: l.onboardingWelcomeRestore,
            prefixIcon: FIcons.cloudDownload,
            variant: FButtonVariant.outline,
            onPress: _onRestore,
          ),
        ],
      ),
    );
  }

  Widget _buildAddressStep(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = context.theme;
    return SingleChildScrollView(
      padding: AppSizes.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.onboardingAddressTitle,
            textAlign: TextAlign.center,
            style: theme.typography.xl3.copyWith(
              color: theme.colors.foreground,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l.onboardingWelcomeBody,
            textAlign: TextAlign.center,
            style: theme.typography.md.copyWith(
              color: theme.colors.mutedForeground,
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
        ],
      ),
    );
  }

  Widget _buildSpeciesStep(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = context.theme;
    return SingleChildScrollView(
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
          if (!_speciesReady) ...[
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
    );
  }

  Widget _buildRecapStep(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = context.theme;
    final city = _picked?.label ?? '';
    final speciesCount =
        _seedSpeciesActive.length + _customSpecies.length;
    return SingleChildScrollView(
      child: Padding(
        padding: AppSizes.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.onboardingStep3Title,
              style: theme.typography.xl3
                  .copyWith(color: theme.colors.foreground),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l.onboardingStep3RecapFmt(speciesCount, city),
              style: theme.typography.md
                  .copyWith(color: theme.colors.mutedForeground),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppSectionCard(
              icon: FIcons.userPlus,
              title: l.onboardingStep3SectionTitle,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l.onboardingStep3Tip1),
                  const SizedBox(height: AppSpacing.xs),
                  Text(l.onboardingStep3Tip2),
                  const SizedBox(height: AppSpacing.xs),
                  Text(l.onboardingStep3Tip3),
                ],
              ),
            ),
          ],
        ),
      ),
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
