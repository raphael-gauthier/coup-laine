// lib/presentation/clients/client_form_screen.dart
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:coupe_laine/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_tokens.dart';
import '../../domain/models/client.dart';
import '../../domain/models/coordinates.dart';
import '../../infra/services/ors_routing_service.dart';
import '../../state/providers.dart';
import '../widgets/address_autocomplete_field.dart';
import '../widgets/app_list_tile.dart';
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
  final _sheepCtrl = TextEditingController(text: '0');
  final _minOverrideCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String? _addressLabel;
  String? _postcode;
  String? _city;
  Coordinates? _coords;
  String? _markerColorHex; // null = automatic
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
    _markerColorHex = c.markerColorHex;
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
                  const SizedBox(height: AppSpacing.md),
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
                  const SizedBox(height: AppSpacing.md),
                  FTextField(
                    control: FTextFieldControl.managed(controller: _notesCtrl),
                    label: Text(l.clientFormNotes),
                    maxLines: 3,
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
    final theme = context.theme;
    final isAuto = currentHex == null;
    return Column(
      children: [
        AppListTile(
          prefix: Icon(
            isAuto ? FIcons.circleCheck : FIcons.circle,
            color: isAuto
                ? theme.colors.primary
                : theme.colors.mutedForeground,
          ),
          title: 'Automatique (selon statut)',
          subtitle:
              'Suit la couleur de la palette selon le statut du client.',
          onPress: () => onChanged(null),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppListTile(
          prefix: Icon(
            !isAuto ? FIcons.circleCheck : FIcons.circle,
            color: !isAuto
                ? theme.colors.primary
                : theme.colors.mutedForeground,
          ),
          title: 'Personnalisée',
          subtitle: !isAuto ? currentHex! : null,
          onPress: () {
            if (isAuto) onChanged(_toHex(kColorSwatchPalette.first));
          },
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
