import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:coupe_laine/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:cross_file/cross_file.dart' show XFile;
import 'package:share_plus/share_plus.dart' show Share;

import '../../domain/models/settings.dart';
import '../../state/providers.dart';
import '../clients/clients_list_screen.dart' show clientsAsyncProvider, clientsPendingProvider;
import '../tours/tours_list_screen.dart' show toursAsyncProvider;
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
    final didBaseChange =
        _draft.baseAddressLabel != widget.initial.baseAddressLabel ||
            _draft.baseCoordinates != widget.initial.baseCoordinates;
    await ref.read(settingsRepositoryProvider).save(_draft);
    ref.invalidate(_settingsAsyncProvider);
    if (!mounted) return;
    if (didBaseChange) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          content: const Text(
            "L'adresse de base a changé. Recalculer toutes les distances "
            'depuis la nouvelle base ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Plus tard'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
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
          onTap: () async {
            final svc = ref.read(jsonExportServiceProvider);
            final body = await svc.exportToJsonString();
            final dir = await getTemporaryDirectory();
            final file = File(p.join(dir.path,
                'coupe-laine-${DateTime.now().millisecondsSinceEpoch}.json'));
            await file.writeAsString(body);
            await Share.shareXFiles([XFile(file.path)]);
          },
        ),
        ListTile(
          leading: const Icon(Icons.download),
          title: Text(l.settingsImportData),
          onTap: () async {
            final pick = await FilePicker.pickFiles(type: FileType.any);
            if (pick == null) return;
            final body = await File(pick.files.single.path!).readAsString();
            if (!mounted) return;
            final ok = await showDialog<bool>(
              context: context, // ignore: use_build_context_synchronously
              builder: (_) => AlertDialog(
                content: const Text(
                    'Cette action remplace toutes les données actuelles. Continuer ?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Annuler'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Importer'),
                  ),
                ],
              ),
            );
            if (ok == true) {
              await ref.read(jsonExportServiceProvider).importFromJsonString(body);
              ref.invalidate(_settingsAsyncProvider);
              ref.invalidate(clientsAsyncProvider);
              ref.invalidate(clientsPendingProvider);
              ref.invalidate(toursAsyncProvider);
            }
          },
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
