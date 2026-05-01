import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_tokens.dart';
import '../../core/ui/confirm_dialog.dart';
import '../../domain/models/animal_category.dart';
import '../../domain/models/prestation.dart';
import '../../l10n/app_localizations.dart';
import '../../state/providers.dart';
import '../widgets/app_action_bar.dart';
import '../widgets/app_header.dart';
import '../widgets/app_primary_button.dart';
import '../widgets/app_section_card.dart';

/// Create or edit a prestation. Route :
/// - `/settings/prestations/new`        → create mode (id == null)
/// - `/settings/prestations/:id`        → edit mode
class PrestationEditScreen extends ConsumerStatefulWidget {
  final int? id;
  const PrestationEditScreen({super.key, this.id});

  bool get isEdit => id != null;

  @override
  ConsumerState<PrestationEditScreen> createState() =>
      _PrestationEditScreenState();
}

class _PrestationEditScreenState extends ConsumerState<PrestationEditScreen> {
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _minutesCtrl = TextEditingController();

  bool _bindToCategory = false;
  int? _selectedSpeciesId;
  int? _selectedCategoryId;

  bool _loaded = false; // edit mode: have we populated controllers yet?
  bool _notFound = false;
  Prestation? _existing;
  bool _saving = false;

  String? _nameError;
  String? _categoryError;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _minutesCtrl.dispose();
    super.dispose();
  }

  void _hydrateFromPrestation(Prestation p, Map<int, AnimalCategory> allCats) {
    _existing = p;
    _nameCtrl.text = p.name;
    _priceCtrl.text =
        p.priceCents == null ? '' : (p.priceCents! / 100).toStringAsFixed(2);
    _minutesCtrl.text = p.minutes == null ? '' : p.minutes.toString();
    if (p.categoryId != null) {
      _bindToCategory = true;
      _selectedCategoryId = p.categoryId;
      final cat = allCats[p.categoryId];
      _selectedSpeciesId = cat?.speciesId;
    }
    _loaded = true;
  }

  /// Parse a price input like "12,50" / "12.50" / "" → cents (or null).
  /// Returns -1 to signal a parse error.
  int? _parsePrice(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;
    final normalized = trimmed.replaceAll(',', '.').replaceAll(' ', '');
    final value = double.tryParse(normalized);
    if (value == null) return -1;
    return (value * 100).round();
  }

  int? _parseMinutes(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;
    return int.tryParse(trimmed);
  }

  Future<void> _save() async {
    String? nameError;
    String? categoryError;

    if (_nameCtrl.text.trim().isEmpty) {
      nameError = 'Requis';
    }
    if (_bindToCategory && _selectedCategoryId == null) {
      categoryError = 'Requis';
    }
    setState(() {
      _nameError = nameError;
      _categoryError = categoryError;
    });
    if (nameError != null || categoryError != null) return;

    final priceCents = _parsePrice(_priceCtrl.text);
    if (priceCents == -1) {
      setState(() => _saving = false);
      return;
    }
    final minutes = _parseMinutes(_minutesCtrl.text);

    setState(() => _saving = true);

    final repo = ref.read(prestationRepositoryProvider);
    final boundCategoryId = _bindToCategory ? _selectedCategoryId : null;

    if (widget.id == null) {
      await repo.insert(
        name: _nameCtrl.text.trim(),
        priceCents: priceCents,
        minutes: minutes,
        categoryId: boundCategoryId,
      );
    } else {
      await repo.rename(id: widget.id!, name: _nameCtrl.text.trim());
      await repo.updateValues(
        id: widget.id!,
        priceCents: priceCents,
        minutes: minutes,
      );
      await repo.updateBinding(
        id: widget.id!,
        categoryId: boundCategoryId,
      );
    }

    ref.invalidate(activePrestationsProvider);
    ref.invalidate(archivedPrestationsProvider);
    ref.invalidate(prestationCountActiveProvider);

    if (!mounted) return;
    setState(() => _saving = false);
    context.pop();
  }

  Future<void> _toggleArchive() async {
    if (_existing == null) return;
    final repo = ref.read(prestationRepositoryProvider);
    if (_existing!.isArchived) {
      await repo.unarchive(_existing!.id);
    } else {
      await repo.archive(_existing!.id);
    }
    ref.invalidate(activePrestationsProvider);
    ref.invalidate(archivedPrestationsProvider);
    ref.invalidate(prestationCountActiveProvider);
    if (!mounted) return;
    context.pop();
  }

  Future<void> _confirmArchive() async {
    if (_existing == null) return;
    if (_existing!.isArchived) {
      // Unarchive: no confirmation needed
      await _toggleArchive();
      return;
    }
    final ok = await showDestructiveConfirm(
      context,
      title: 'Archiver la prestation ?',
      body: 'La prestation ne sera plus proposée dans les nouvelles tournées.',
      confirmLabel: 'Archiver',
    );
    if (ok) await _toggleArchive();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final headerTitle =
        widget.isEdit ? l.prestationFormEditTitle : l.prestationFormCreateTitle;

    return SafeArea(
      child: FScaffold(
        resizeToAvoidBottomInset: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppHeader(title: headerTitle),
            Expanded(child: _buildContent(context, l)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, AppLocalizations l) {
    if (widget.isEdit) {
      final activeAsync = ref.watch(activePrestationsProvider);
      final archivedAsync = ref.watch(archivedPrestationsProvider);
      final allCatsAsync = ref.watch(allCategoriesByIdProvider);

      if (activeAsync.isLoading ||
          archivedAsync.isLoading ||
          allCatsAsync.isLoading) {
        return const Center(child: FCircularProgress());
      }
      if (activeAsync.hasError) return Center(child: Text('${activeAsync.error}'));
      if (archivedAsync.hasError) {
        return Center(child: Text('${archivedAsync.error}'));
      }
      if (allCatsAsync.hasError) return Center(child: Text('${allCatsAsync.error}'));

      if (!_loaded) {
        final all = [...activeAsync.value!, ...archivedAsync.value!];
        final matches = all.where((p) => p.id == widget.id);
        if (matches.isEmpty) {
          _notFound = true;
        } else {
          _hydrateFromPrestation(matches.first, allCatsAsync.value!);
        }
      }
      if (_notFound) {
        return const Center(child: Text('—'));
      }
    }

    final archiveButton = widget.isEdit && _existing != null
        ? AppPrimaryButton(
            label: _existing!.isArchived
                ? l.prestationFormUnarchive
                : l.prestationFormArchive,
            variant: _existing!.isArchived
                ? FButtonVariant.outline
                : FButtonVariant.destructive,
            onPress: _confirmArchive,
          )
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: AppSizes.screenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- Identité ---
                AppSectionCard(
                  icon: FIcons.tag,
                  title: 'Identité',
                  child: FTextField(
                    control: FTextFieldControl.managed(
                      controller: _nameCtrl,
                      onChange: (_) {
                        if (_nameError != null) setState(() => _nameError = null);
                      },
                    ),
                    label: Text(l.prestationFormName),
                    error: _nameError != null ? Text(_nameError!) : null,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // --- Catégorie ---
                AppSectionCard(
                  icon: FIcons.folder,
                  title: 'Catégorie',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FTile(
                        title: Text(l.prestationFormBindToCategory),
                        suffix: FSwitch(
                          value: _bindToCategory,
                          onChange: (v) => setState(() {
                            _bindToCategory = v;
                            if (!v) {
                              _selectedSpeciesId = null;
                              _selectedCategoryId = null;
                              _categoryError = null;
                            }
                          }),
                        ),
                      ),
                      if (_bindToCategory) ...[
                        const SizedBox(height: AppSpacing.md),
                        _SpeciesAndCategoryPicker(
                          selectedSpeciesId: _selectedSpeciesId,
                          selectedCategoryId: _selectedCategoryId,
                          onSpeciesChanged: (id) => setState(() {
                            _selectedSpeciesId = id;
                            _selectedCategoryId = null;
                          }),
                          onCategoryChanged: (id) => setState(() {
                            _selectedCategoryId = id;
                            if (_categoryError != null) _categoryError = null;
                          }),
                          error: _categoryError,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // --- Tarif & durée ---
                AppSectionCard(
                  icon: FIcons.clock,
                  title: 'Tarif & durée',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FTextField(
                        control: FTextFieldControl.managed(controller: _priceCtrl),
                        label: Text(l.prestationFormPrice),
                        description: Text(l.prestationFormPriceHelper),
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      FTextField(
                        control: FTextFieldControl.managed(controller: _minutesCtrl),
                        label: Text(l.prestationFormMinutes),
                        description: Text(l.prestationFormMinutesHelper),
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),

        // --- Action bar ---
        AppActionBar(
          primary: AppPrimaryButton(
            label: l.prestationFormSave,
            onPress: _saving ? null : _save,
            loading: _saving,
          ),
          secondary: AppPrimaryButton(
            label: 'Annuler',
            variant: FButtonVariant.outline,
            onPress: () => context.pop(),
          ),
          tertiary: archiveButton,
        ),
      ],
    );
  }
}

class _SpeciesAndCategoryPicker extends ConsumerWidget {
  final int? selectedSpeciesId;
  final int? selectedCategoryId;
  final ValueChanged<int> onSpeciesChanged;
  final ValueChanged<int> onCategoryChanged;
  final String? error;

  const _SpeciesAndCategoryPicker({
    required this.selectedSpeciesId,
    required this.selectedCategoryId,
    required this.onSpeciesChanged,
    required this.onCategoryChanged,
    required this.error,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = context.theme;
    final speciesAsync = ref.watch(activeSpeciesProvider);
    final catsAsync = ref.watch(activeCategoriesBySpeciesProvider);

    if (speciesAsync.isLoading || catsAsync.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Center(child: FCircularProgress()),
      );
    }
    if (speciesAsync.hasError) return Text('${speciesAsync.error}');
    if (catsAsync.hasError) return Text('${catsAsync.error}');

    final species = speciesAsync.value!;
    final catsBySpecies = catsAsync.value!;
    final cats = selectedSpeciesId == null
        ? const <AnimalCategory>[]
        : (catsBySpecies[selectedSpeciesId] ?? const <AnimalCategory>[]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: Text(
            l.prestationFormSpecies,
            style: theme.typography.sm.copyWith(
              color: theme.colors.mutedForeground,
            ),
          ),
        ),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final s in species)
              _Chip(
                label: s.name,
                selected: s.id == selectedSpeciesId,
                onTap: () => onSpeciesChanged(s.id),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: Text(
            l.prestationFormCategory,
            style: theme.typography.sm.copyWith(
              color: theme.colors.mutedForeground,
            ),
          ),
        ),
        if (cats.isEmpty)
          Text(
            '—',
            style: theme.typography.sm.copyWith(
              color: theme.colors.mutedForeground,
            ),
          )
        else
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final c in cats)
                _Chip(
                  label: c.name,
                  selected: c.id == selectedCategoryId,
                  onTap: () => onCategoryChanged(c.id),
                ),
            ],
          ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Row(
              children: [
                Icon(FIcons.triangleAlert, size: 14, color: theme.colors.destructive),
                const SizedBox(width: AppSpacing.xxs),
                Text(
                  error!,
                  style: theme.typography.xs.copyWith(
                    color: theme.colors.destructive,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FButton(
      variant: selected ? FButtonVariant.primary : FButtonVariant.outline,
      onPress: onTap,
      child: Text(label),
    );
  }
}
