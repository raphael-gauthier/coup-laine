import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';

import '../../l10n/app_localizations.dart';

class AnimalCategoryFormSheetResult {
  final String name;
  final int? defaultMinutes;
  final int? defaultPriceCents;
  const AnimalCategoryFormSheetResult({
    required this.name,
    this.defaultMinutes,
    this.defaultPriceCents,
  });
}

class AnimalCategoryFormSheet extends StatefulWidget {
  final String? initialName;
  final int? initialDefaultMinutes;
  final int? initialDefaultPriceCents;

  const AnimalCategoryFormSheet({
    super.key,
    this.initialName,
    this.initialDefaultMinutes,
    this.initialDefaultPriceCents,
  });

  @override
  State<AnimalCategoryFormSheet> createState() =>
      _AnimalCategoryFormSheetState();
}

class _AnimalCategoryFormSheetState extends State<AnimalCategoryFormSheet> {
  late final TextEditingController _name;
  late final TextEditingController _minutes;
  late final TextEditingController _priceEur;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initialName ?? '');
    _minutes = TextEditingController(
      text: widget.initialDefaultMinutes?.toString() ?? '',
    );
    _priceEur = TextEditingController(
      text: widget.initialDefaultPriceCents == null
          ? ''
          : (widget.initialDefaultPriceCents! / 100).toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _minutes.dispose();
    _priceEur.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final minutes = int.tryParse(_minutes.text.trim());
    final priceEurDouble =
        double.tryParse(_priceEur.text.trim().replaceAll(',', '.'));
    final priceCents =
        priceEurDouble == null ? null : (priceEurDouble * 100).round();
    Navigator.of(context).pop(AnimalCategoryFormSheetResult(
      name: name,
      defaultMinutes: minutes,
      defaultPriceCents: priceCents,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _name,
              decoration: InputDecoration(labelText: l.categoryFormName),
              autofocus: widget.initialName == null,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _minutes,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: l.categoryFormDefaultMinutes,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _priceEur,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: l.categoryFormDefaultPrice,
                helperText: l.categoryFormPriceHelper,
              ),
            ),
            const SizedBox(height: 16),
            FButton(
              onPress: _save,
              child: Text(l.categoryFormSave),
            ),
          ],
        ),
      ),
    );
  }
}
