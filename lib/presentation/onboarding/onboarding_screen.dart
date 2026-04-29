import 'package:flutter/widgets.dart';
import 'package:coup_laine/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_tokens.dart';
import '../../domain/models/settings.dart';
import '../../infra/services/ban_geocoding_service.dart';
import '../../state/providers.dart';
import '../widgets/address_autocomplete_field.dart';
import '../widgets/app_primary_button.dart';
import '../widgets/app_section_card.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  GeocodingResult? _picked;
  bool _saving = false;

  Future<void> _confirm() async {
    final picked = _picked;
    if (picked == null) return;
    setState(() => _saving = true);
    try {
      await ref.read(settingsRepositoryProvider).save(
            Settings(
              baseCoordinates: picked.coordinates,
              baseAddressLabel: picked.label,
              seasonStartedAt: DateTime.fromMillisecondsSinceEpoch(0),
            ),
          );
      if (!mounted) return;
      context.go('/clients');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = context.theme;

    return FScaffold(
      resizeToAvoidBottomInset: true,
      child: SingleChildScrollView(
        padding: AppSizes.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(
                child: Image.asset(
                  'assets/illustrations/sheep-mascot.png',
                  height: 220,
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
                fontFamily: 'Fraunces',
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
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
            const SizedBox(height: AppSpacing.xl),
            AppPrimaryButton(
              label: l.onboardingCta,
              prefixIcon: FIcons.arrowRight,
              onPress: _picked == null ? null : _confirm,
              loading: _saving,
            ),
          ],
        ),
      ),
    );
  }
}
