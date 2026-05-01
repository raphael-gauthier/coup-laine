import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../../l10n/app_localizations.dart';

class AnimalCategoryFormSheetResult {
  final String name;
  const AnimalCategoryFormSheetResult({
    required this.name,
  });
}

class AnimalCategoryFormSheet extends StatefulWidget {
  final String? initialName;

  const AnimalCategoryFormSheet({
    super.key,
    this.initialName,
  });

  @override
  State<AnimalCategoryFormSheet> createState() =>
      _AnimalCategoryFormSheetState();
}

class _AnimalCategoryFormSheetState extends State<AnimalCategoryFormSheet> {
  late final TextEditingController _name;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initialName ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop(AnimalCategoryFormSheetResult(
      name: name,
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
