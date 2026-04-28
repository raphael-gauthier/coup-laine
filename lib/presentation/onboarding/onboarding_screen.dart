import 'package:flutter/material.dart';
import 'package:coupe_laine/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/settings.dart';
import '../../infra/services/ban_geocoding_service.dart';
import '../../state/providers.dart';
import '../widgets/address_autocomplete_field.dart';

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
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero block
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colors.primary,
                  ),
                  child: Icon(
                    FIcons.scissors,
                    size: 56,
                    color: theme.colors.primaryForeground,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Coupe-Laine',
                  textAlign: TextAlign.center,
                  style: theme.typography.xl4.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colors.foreground,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l.onboardingHeroSubtitle,
                  textAlign: TextAlign.center,
                  style: theme.typography.lg.copyWith(
                    color: theme.colors.mutedForeground,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Welcome card
            FCard(
              title: Text(l.onboardingWelcomeTitle),
              child: Text(
                l.onboardingWelcomeBody,
                style: theme.typography.sm.copyWith(
                  color: theme.colors.mutedForeground,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Address card
            FCard(
              title: Text(l.onboardingAddressTitle),
              child: AddressAutocompleteField(
                onPicked: (r) => setState(() => _picked = r),
              ),
            ),

            const SizedBox(height: 32),

            // CTA
            FButton(
              onPress: _picked == null || _saving ? null : _confirm,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: FCircularProgress(
                        size: FCircularProgressSizeVariant.sm,
                      ),
                    )
                  : Text(l.onboardingCta),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
