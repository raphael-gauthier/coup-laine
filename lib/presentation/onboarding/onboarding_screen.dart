import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    return Scaffold(
      appBar: AppBar(title: const Text('Bienvenue')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Pour commencer, indiquez l'adresse d'où vous partez chaque matin. "
              'Toutes les distances seront calculées depuis ce point.',
            ),
            const SizedBox(height: 16),
            AddressAutocompleteField(
              onPicked: (r) => setState(() => _picked = r),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _picked == null || _saving ? null : _confirm,
              child: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text("Enregistrer l'adresse"),
            ),
          ],
        ),
      ),
    );
  }
}
