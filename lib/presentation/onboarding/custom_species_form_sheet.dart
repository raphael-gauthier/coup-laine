import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../../l10n/app_localizations.dart';

class CustomSpeciesFormSheetResult {
  final String name;
  final List<String> categoryNames;
  const CustomSpeciesFormSheetResult({
    required this.name,
    required this.categoryNames,
  });
}

class CustomSpeciesFormSheet extends StatefulWidget {
  const CustomSpeciesFormSheet({super.key});

  @override
  State<CustomSpeciesFormSheet> createState() => _CustomSpeciesFormSheetState();
}

class _CustomSpeciesFormSheetState extends State<CustomSpeciesFormSheet> {
  final _name = TextEditingController();
  final List<TextEditingController> _categoryControllers = [
    TextEditingController(),
  ];

  @override
  void dispose() {
    _name.dispose();
    for (final c in _categoryControllers) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _canSave {
    if (_name.text.trim().isEmpty) return false;
    return _categoryControllers.any((c) => c.text.trim().isNotEmpty);
  }

  void _addCategory() {
    setState(() {
      _categoryControllers.add(TextEditingController());
    });
  }

  void _removeCategory(int i) {
    if (_categoryControllers.length <= 1) return;
    setState(() {
      _categoryControllers.removeAt(i).dispose();
    });
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final categories = _categoryControllers
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (categories.isEmpty) return;
    Navigator.of(context).pop(CustomSpeciesFormSheetResult(
      name: name,
      categoryNames: categories,
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.onboardingCustomSpeciesSheetTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _name,
                decoration: InputDecoration(
                  labelText: l.onboardingCustomSpeciesNameLabel,
                ),
                autofocus: true,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              Text(l.onboardingCustomSpeciesCategoriesLabel),
              const SizedBox(height: 8),
              for (var i = 0; i < _categoryControllers.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _categoryControllers[i],
                          decoration: const InputDecoration(),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      if (_categoryControllers.length > 1)
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => _removeCategory(i),
                        ),
                    ],
                  ),
                ),
              TextButton(
                onPressed: _addCategory,
                child: Text(l.onboardingCustomSpeciesAddCategory),
              ),
              const SizedBox(height: 16),
              FButton(
                onPress: _canSave ? _save : null,
                child: Text(l.categoryFormSave),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
