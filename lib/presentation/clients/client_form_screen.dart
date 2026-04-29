// lib/presentation/clients/client_form_screen.dart
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:coup_laine/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_tokens.dart';
import '../../domain/models/client.dart';
import '../../domain/models/coordinates.dart';
import '../../infra/services/ors_routing_service.dart';
import '../../state/providers.dart';
import '../widgets/address_autocomplete_field.dart';
import '../widgets/app_primary_button.dart';
import '../widgets/app_section_card.dart';
import '../widgets/color_swatch_picker.dart';
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
  final _sheepSmallCtrl = TextEditingController(text: '0');
  final _sheepLargeCtrl = TextEditingController(text: '0');

  String? _addressLabel;
  String? _postcode;
  String? _city;
  Coordinates? _coords;
  String? _markerColorHex; // null = automatic
  bool _saving = false;
  bool _loading = false;

  // Manual validation errors
  String? _nameError;
  String? _sheepSmallError;
  String? _sheepLargeError;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit) _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _sheepSmallCtrl.dispose();
    _sheepLargeCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final c = await ref.read(clientRepositoryProvider).findById(widget.clientId!);
    if (c == null) return;
    _nameCtrl.text = c.name;
    _phoneCtrl.text = c.phone ?? '';
    _sheepSmallCtrl.text = c.sheepCountSmall.toString();
    _sheepLargeCtrl.text = c.sheepCountLarge.toString();
    _addressLabel = c.addressLabel;
    _postcode = c.postcode;
    _city = c.city;
    _coords = c.coordinates;
    _markerColorHex = c.markerColorHex;
    if (mounted) setState(() => _loading = false);
  }

  bool _validate() {
    String? nameError;
    String? sheepSmallError;
    String? sheepLargeError;

    if (_nameCtrl.text.trim().isEmpty) {
      nameError = 'Requis';
    }
    final small = int.tryParse(_sheepSmallCtrl.text);
    if (small == null || small < 0) {
      sheepSmallError = 'Nombre invalide';
    }
    final large = int.tryParse(_sheepLargeCtrl.text);
    if (large == null || large < 0) {
      sheepLargeError = 'Nombre invalide';
    }

    setState(() {
      _nameError = nameError;
      _sheepSmallError = sheepSmallError;
      _sheepLargeError = sheepLargeError;
    });

    return nameError == null &&
        sheepSmallError == null &&
        sheepLargeError == null;
  }

  Future<void> _submit() async {
    final l = AppLocalizations.of(context)!;
    if (!_validate()) return;
    if (_coords == null) {
      showFToast(context: context, title: Text(l.clientFormErrorNoCoords));
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
        sheepCountSmall: int.parse(_sheepSmallCtrl.text),
        sheepCountLarge: int.parse(_sheepLargeCtrl.text),
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
        sheepCountSmall: int.parse(_sheepSmallCtrl.text),
        sheepCountLarge: int.parse(_sheepLargeCtrl.text),
      ));
    }

    await repo.setMarkerColor(id, _markerColorHex);

    try {
      await sync.recomputeForClient(id);
    } on OrsException {
      if (mounted) {
        showFToast(context: context, title: Text(l.clientFormErrorRecompute));
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
    final headerTitle = widget.isEdit ? l.clientFormTitleEdit : l.clientFormTitleNew;

    if (_loading) {
      return FScaffold(
        header: FHeader.nested(title: Text(headerTitle)),
        child: const Center(child: FCircularProgress()),
      );
    }

    return FScaffold(
      resizeToAvoidBottomInset: true,
      header: FHeader.nested(title: Text(headerTitle)),
      child: SafeArea(
        top: true,
        bottom: false,
        child: SingleChildScrollView(
          padding: AppSizes.screenPadding,
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Section: Identité
            AppSectionCard(
              icon: FIcons.user,
              title: l.clientFormSectionIdentity,
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
                  const SizedBox(height: AppSpacing.md),
                  FTextField(
                    control: FTextFieldControl.managed(controller: _phoneCtrl),
                    label: Text(l.clientFormPhone),
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Section: Adresse
            AppSectionCard(
              icon: FIcons.mapPin,
              title: l.clientFormSectionAddress,
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
            const SizedBox(height: AppSpacing.md),

            // Section: Tonte
            AppSectionCard(
              icon: FIcons.scissors,
              title: l.clientFormSectionShearing,
              child: Column(
                children: [
                  FTextField(
                    control: FTextFieldControl.managed(
                      controller: _sheepSmallCtrl,
                      onChange: (_) {
                        if (_sheepSmallError != null) {
                          setState(() => _sheepSmallError = null);
                        }
                      },
                    ),
                    label: Text(l.clientFormSheepCountSmall),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    error: _sheepSmallError != null
                        ? Text(_sheepSmallError!)
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FTextField(
                    control: FTextFieldControl.managed(
                      controller: _sheepLargeCtrl,
                      onChange: (_) {
                        if (_sheepLargeError != null) {
                          setState(() => _sheepLargeError = null);
                        }
                      },
                    ),
                    label: Text(l.clientFormSheepCountLarge),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    error: _sheepLargeError != null
                        ? Text(_sheepLargeError!)
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Section: Couleur sur la carte
            AppSectionCard(
              icon: FIcons.palette,
              title: 'Couleur sur la carte',
              child: _MarkerColorEditor(
                currentHex: _markerColorHex,
                onChanged: (hex) => setState(() => _markerColorHex = hex),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Save button
            AppPrimaryButton(
              label: l.clientFormSave,
              onPress: _saving ? null : _submit,
              loading: _saving,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          ),
        ),
      ),
    );
  }
}

class _MarkerColorEditor extends StatelessWidget {
  final String? currentHex;
  final ValueChanged<String?> onChanged;
  const _MarkerColorEditor({required this.currentHex, required this.onChanged});

  Color _hex(String h) {
    final cleaned = h.replaceAll('#', '');
    return Color(int.parse(cleaned, radix: 16) | 0xFF000000);
  }

  String _toHex(Color c) {
    final hex =
        (c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase();
    return '#$hex';
  }

  @override
  Widget build(BuildContext context) {
    final isAuto = currentHex == null;
    return Column(
      children: [
        FTile(
          title: const Text('Couleur automatique'),
          subtitle: const Text(
              'Suit la couleur de la palette selon le statut du client.'),
          suffix: FSwitch(
            value: isAuto,
            onChange: (v) => onChanged(
              v ? null : _toHex(kColorSwatchPalette.first),
            ),
          ),
        ),
        if (!isAuto) ...[
          const SizedBox(height: AppSpacing.md),
          ColorSwatchGrid(
            current: _hex(currentHex!),
            onPicked: (c) => onChanged(_toHex(c)),
          ),
        ],
      ],
    );
  }
}
