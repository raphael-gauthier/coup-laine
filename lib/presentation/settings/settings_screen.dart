import 'package:flutter/material.dart';
import 'package:coupe_laine/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/settings.dart';
import '../../state/providers.dart';
import '../widgets/address_autocomplete_field.dart';

final _settingsAsyncProvider = FutureProvider<Settings?>((ref) {
  return ref.watch(settingsRepositoryProvider).read();
});

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final async = ref.watch(_settingsAsyncProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.tabSettings)),
      body: async.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (s) => s == null
            ? const SizedBox.shrink()
            : _SettingsForm(initial: s),
      ),
    );
  }
}

class _SettingsForm extends ConsumerStatefulWidget {
  final Settings initial;
  const _SettingsForm({required this.initial});

  @override
  ConsumerState<_SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends ConsumerState<_SettingsForm> {
  late Settings _draft;

  @override
  void initState() {
    super.initState();
    _draft = widget.initial;
  }

  Future<void> _save() async {
    await ref.read(settingsRepositoryProvider).save(_draft);
    ref.invalidate(_settingsAsyncProvider);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Enregistré')));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(l.settingsBaseAddressTitle,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(_draft.baseAddressLabel),
        const SizedBox(height: 8),
        AddressAutocompleteField(
          labelText: l.settingsBaseAddressEdit,
          onPicked: (r) => setState(() {
            _draft = Settings(
              baseAddressLabel: r.label,
              baseCoordinates: r.coordinates,
              defaultRadiusKm: _draft.defaultRadiusKm,
              defaultMinutesPerSheep: _draft.defaultMinutesPerSheep,
              travelFeeEurosPerBracket: _draft.travelFeeEurosPerBracket,
              bracketKm: _draft.bracketKm,
            );
          }),
        ),
        const Divider(height: 32),
        Text(l.settingsDefaultsTitle,
            style: Theme.of(context).textTheme.titleMedium),
        _IntField(
          label: l.settingsRadiusLabel,
          value: _draft.defaultRadiusKm,
          onChanged: (v) => setState(() => _draft = _copyWith(radiusKm: v)),
        ),
        _IntField(
          label: l.settingsMinPerSheepLabel,
          value: _draft.defaultMinutesPerSheep,
          onChanged: (v) =>
              setState(() => _draft = _copyWith(minPerSheep: v)),
        ),
        _IntField(
          label: l.settingsTariffLabel,
          value: _draft.travelFeeEurosPerBracket,
          onChanged: (v) => setState(() => _draft = _copyWith(tariff: v)),
        ),
        const SizedBox(height: 24),
        FilledButton(onPressed: _save, child: Text(l.settingsSave)),
        const Divider(height: 32),
        Text(l.settingsDataTitle,
            style: Theme.of(context).textTheme.titleMedium),
        ListTile(
          leading: const Icon(Icons.upload_file),
          title: Text(l.settingsExportData),
          enabled: false, // wired in Phase 10
        ),
        ListTile(
          leading: const Icon(Icons.download),
          title: Text(l.settingsImportData),
          enabled: false, // wired in Phase 10
        ),
      ],
    );
  }

  Settings _copyWith({int? radiusKm, int? minPerSheep, int? tariff}) =>
      Settings(
        baseAddressLabel: _draft.baseAddressLabel,
        baseCoordinates: _draft.baseCoordinates,
        defaultRadiusKm: radiusKm ?? _draft.defaultRadiusKm,
        defaultMinutesPerSheep: minPerSheep ?? _draft.defaultMinutesPerSheep,
        travelFeeEurosPerBracket: tariff ?? _draft.travelFeeEurosPerBracket,
        bracketKm: _draft.bracketKm,
      );
}

class _IntField extends StatefulWidget {
  final String label;
  final int value;
  final void Function(int) onChanged;
  const _IntField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  State<_IntField> createState() => _IntFieldState();
}

class _IntFieldState extends State<_IntField> {
  late final TextEditingController _c;
  @override
  void initState() {
    super.initState();
    _c = TextEditingController(text: widget.value.toString());
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: _c,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: widget.label),
        onChanged: (s) {
          final v = int.tryParse(s);
          if (v != null && v > 0) widget.onChanged(v);
        },
      ),
    );
  }
}
