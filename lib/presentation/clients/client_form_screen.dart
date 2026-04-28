// lib/presentation/clients/client_form_screen.dart
import 'package:flutter/material.dart';
import 'package:coupe_laine/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/client.dart';
import '../../domain/models/coordinates.dart';
import '../../infra/services/ors_routing_service.dart';
import '../../state/providers.dart';
import '../widgets/address_autocomplete_field.dart';
import 'clients_list_screen.dart' show clientsAsyncProvider, clientsPendingProvider;

class ClientFormScreen extends ConsumerStatefulWidget {
  final int? clientId;
  const ClientFormScreen({super.key, this.clientId});

  bool get isEdit => clientId != null;

  @override
  ConsumerState<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends ConsumerState<ClientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _sheep = TextEditingController(text: '0');
  final _minOverride = TextEditingController();
  final _notes = TextEditingController();

  String? _addressLabel;
  String? _postcode;
  String? _city;
  Coordinates? _coords;
  bool _saving = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit) _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _sheep.dispose();
    _minOverride.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final c = await ref
        .read(clientRepositoryProvider)
        .findById(widget.clientId!);
    if (c == null) return;
    _name.text = c.name;
    _phone.text = c.phone ?? '';
    _sheep.text = c.sheepCount.toString();
    _minOverride.text = c.minutesPerSheepOverride?.toString() ?? '';
    _notes.text = c.notes ?? '';
    _addressLabel = c.addressLabel;
    _postcode = c.postcode;
    _city = c.city;
    _coords = c.coordinates;
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _submit() async {
    final l = AppLocalizations.of(context)!;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_coords == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.clientFormErrorNoCoords)),
      );
      return;
    }
    setState(() => _saving = true);
    final repo = ref.read(clientRepositoryProvider);
    final sync = ref.read(distanceMatrixSyncProvider);

    int id;
    if (widget.isEdit) {
      id = widget.clientId!;
      await repo.updateBasics(
        id: id,
        name: _name.text.trim(),
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        sheepCount: int.parse(_sheep.text),
        minutesPerSheepOverride: _minOverride.text.trim().isEmpty
            ? null
            : int.parse(_minOverride.text),
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      );
      await repo.updateAddress(
        id: id,
        addressLabel: _addressLabel!,
        postcode: _postcode!,
        city: _city!,
        coordinates: _coords!,
      );
    } else {
      id = await repo.insert(Client(
        id: 0,
        name: _name.text.trim(),
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        addressLabel: _addressLabel!,
        postcode: _postcode!,
        city: _city!,
        coordinates: _coords!,
        sheepCount: int.parse(_sheep.text),
        minutesPerSheepOverride: _minOverride.text.trim().isEmpty
            ? null
            : int.parse(_minOverride.text),
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      ));
    }

    try {
      await sync.recomputeForClient(id);
    } on OrsException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.clientFormErrorRecompute)),
        );
      }
    }

    if (!mounted) return;
    ref.invalidate(clientsAsyncProvider);
    ref.invalidate(clientsPendingProvider);
    setState(() => _saving = false);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? l.clientFormTitleEdit : l.clientFormTitleNew),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              decoration: InputDecoration(labelText: l.clientFormName),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Requis' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              decoration: InputDecoration(labelText: l.clientFormPhone),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            AddressAutocompleteField(
              initialLabel: _addressLabel,
              onPicked: (r) => setState(() {
                _addressLabel = r.label;
                _postcode = r.postcode;
                _city = r.city;
                _coords = r.coordinates;
              }),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _sheep,
              decoration: InputDecoration(labelText: l.clientFormSheepCount),
              keyboardType: TextInputType.number,
              validator: (v) {
                final n = int.tryParse(v ?? '');
                return (n == null || n < 0) ? 'Nombre invalide' : null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _minOverride,
              decoration: InputDecoration(
                  labelText: l.clientFormMinPerSheepHint),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final n = int.tryParse(v);
                return (n == null || n <= 0) ? 'Nombre invalide' : null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notes,
              decoration: InputDecoration(labelText: l.clientFormNotes),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l.clientFormSave),
            ),
          ],
        ),
      ),
    );
  }
}
