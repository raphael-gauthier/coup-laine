// lib/presentation/clients/client_form_screen.dart
import 'package:flutter/material.dart' show ScaffoldMessenger, SnackBar;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:coupe_laine/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
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
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _sheepCtrl = TextEditingController(text: '0');
  final _minOverrideCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String? _addressLabel;
  String? _postcode;
  String? _city;
  Coordinates? _coords;
  bool _saving = false;
  bool _loading = false;

  // Manual validation errors
  String? _nameError;
  String? _sheepError;
  String? _minOverrideError;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit) _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _sheepCtrl.dispose();
    _minOverrideCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final c = await ref.read(clientRepositoryProvider).findById(widget.clientId!);
    if (c == null) return;
    _nameCtrl.text = c.name;
    _phoneCtrl.text = c.phone ?? '';
    _sheepCtrl.text = c.sheepCount.toString();
    _minOverrideCtrl.text = c.minutesPerSheepOverride?.toString() ?? '';
    _notesCtrl.text = c.notes ?? '';
    _addressLabel = c.addressLabel;
    _postcode = c.postcode;
    _city = c.city;
    _coords = c.coordinates;
    if (mounted) setState(() => _loading = false);
  }

  bool _validate() {
    String? nameError;
    String? sheepError;
    String? minOverrideError;

    if (_nameCtrl.text.trim().isEmpty) {
      nameError = 'Requis';
    }
    final sheepN = int.tryParse(_sheepCtrl.text);
    if (sheepN == null || sheepN < 0) {
      sheepError = 'Nombre invalide';
    }
    final minText = _minOverrideCtrl.text.trim();
    if (minText.isNotEmpty) {
      final n = int.tryParse(minText);
      if (n == null || n <= 0) {
        minOverrideError = 'Nombre invalide';
      }
    }

    setState(() {
      _nameError = nameError;
      _sheepError = sheepError;
      _minOverrideError = minOverrideError;
    });

    return nameError == null && sheepError == null && minOverrideError == null;
  }

  Future<void> _submit() async {
    final l = AppLocalizations.of(context)!;
    if (!_validate()) return;
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
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        sheepCount: int.parse(_sheepCtrl.text),
        minutesPerSheepOverride: _minOverrideCtrl.text.trim().isEmpty
            ? null
            : int.parse(_minOverrideCtrl.text),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
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
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        addressLabel: _addressLabel!,
        postcode: _postcode!,
        city: _city!,
        coordinates: _coords!,
        sheepCount: int.parse(_sheepCtrl.text),
        minutesPerSheepOverride: _minOverrideCtrl.text.trim().isEmpty
            ? null
            : int.parse(_minOverrideCtrl.text),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
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
      return FScaffold(
        header: FHeader.nested(
          title: Text(widget.isEdit ? l.clientFormTitleEdit : l.clientFormTitleNew),
        ),
        child: const Center(child: FCircularProgress()),
      );
    }

    return FScaffold(
      resizeToAvoidBottomInset: true,
      header: FHeader.nested(
        title: Text(widget.isEdit ? l.clientFormTitleEdit : l.clientFormTitleNew),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Section: Identité
            FCard(
              title: Text(l.clientFormSectionIdentity),
              child: Column(
                children: [
                  FTextField(
                    control: FTextFieldControl.managed(
                      controller: _nameCtrl,
                      onChange: (_) {
                        if (_nameError != null) setState(() => _nameError = null);
                      },
                    ),
                    label: Text(l.clientFormName),
                    error: _nameError != null ? Text(_nameError!) : null,
                  ),
                  const SizedBox(height: 12),
                  FTextField(
                    control: FTextFieldControl.managed(controller: _phoneCtrl),
                    label: Text(l.clientFormPhone),
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Section: Adresse
            FCard(
              title: Text(l.clientFormSectionAddress),
              child: AddressAutocompleteField(
                initialLabel: _addressLabel,
                onPicked: (r) => setState(() {
                  _addressLabel = r.label;
                  _postcode = r.postcode;
                  _city = r.city;
                  _coords = r.coordinates;
                }),
              ),
            ),
            const SizedBox(height: 16),

            // Section: Tonte
            FCard(
              title: Text(l.clientFormSectionShearing),
              child: Column(
                children: [
                  FTextField(
                    control: FTextFieldControl.managed(
                      controller: _sheepCtrl,
                      onChange: (_) {
                        if (_sheepError != null) setState(() => _sheepError = null);
                      },
                    ),
                    label: Text(l.clientFormSheepCount),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    error: _sheepError != null ? Text(_sheepError!) : null,
                  ),
                  const SizedBox(height: 12),
                  FTextField(
                    control: FTextFieldControl.managed(
                      controller: _minOverrideCtrl,
                      onChange: (_) {
                        if (_minOverrideError != null) setState(() => _minOverrideError = null);
                      },
                    ),
                    label: Text(l.clientFormMinPerSheepHint),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    error: _minOverrideError != null ? Text(_minOverrideError!) : null,
                  ),
                  const SizedBox(height: 12),
                  FTextField(
                    control: FTextFieldControl.managed(controller: _notesCtrl),
                    label: Text(l.clientFormNotes),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Save button
            FButton(
              onPress: _saving ? null : _submit,
              child: _saving
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: FCircularProgress(size: FCircularProgressSizeVariant.sm),
                        ),
                        const SizedBox(width: 8),
                        Text(l.clientFormSave),
                      ],
                    )
                  : Text(l.clientFormSave),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
