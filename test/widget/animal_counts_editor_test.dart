import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:coup_laine/domain/models/animal_category.dart';
import 'package:coup_laine/domain/models/animal_count.dart';
import 'package:coup_laine/domain/models/species.dart';
import 'package:coup_laine/l10n/app_localizations.dart';
import 'package:coup_laine/presentation/widgets/animal_counts_editor.dart';
import 'package:coup_laine/state/providers.dart';

void _noop(List<AnimalCount> _) {}

void main() {
  testWidgets('typing a count emits a new AnimalCount via onChanged',
      (tester) async {
    List<AnimalCount>? captured;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeSpeciesProvider.overrideWith(
            (ref) async => [const Species(id: 1, name: 'Mouton')],
          ),
          activeCategoriesBySpeciesProvider.overrideWith(
            (ref) async => {
              1: [
                const AnimalCategory(id: 10, speciesId: 1, name: 'Petit'),
              ],
            },
          ),
          allCategoriesByIdProvider.overrideWith(
            (ref) async => {
              10: const AnimalCategory(id: 10, speciesId: 1, name: 'Petit'),
            },
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: AnimalCountsEditor(
              value: const [],
              onChanged: (next) => captured = next,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '5');
    await tester.pumpAndSettle();
    expect(captured, [const AnimalCount(categoryId: 10, count: 5)]);
  });

  testWidgets('empty species list shows empty-state text', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeSpeciesProvider.overrideWith((ref) async => []),
          activeCategoriesBySpeciesProvider.overrideWith((ref) async => {}),
          allCategoriesByIdProvider.overrideWith((ref) async => {}),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: AnimalCountsEditor(
              value: [],
              onChanged: _noop,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(Text), findsWidgets);
  });

  testWidgets('archived entry renders Effacer and clears on press',
      (tester) async {
    List<AnimalCount>? captured;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeSpeciesProvider.overrideWith(
            (ref) async => [const Species(id: 1, name: 'Mouton')],
          ),
          activeCategoriesBySpeciesProvider.overrideWith(
            (ref) async => {
              1: [
                const AnimalCategory(id: 10, speciesId: 1, name: 'Petit'),
              ],
            },
          ),
          allCategoriesByIdProvider.overrideWith(
            (ref) async => {
              10: const AnimalCategory(id: 10, speciesId: 1, name: 'Petit'),
              99: AnimalCategory(
                id: 99,
                speciesId: 1,
                name: 'Vieux',
                archivedAt: DateTime(2024, 1, 1),
              ),
            },
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: AnimalCountsEditor(
              value: const [AnimalCount(categoryId: 99, count: 3)],
              onChanged: (next) => captured = next,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final clearButton = find.text('Effacer');
    expect(clearButton, findsOneWidget);
    await tester.tap(clearButton);
    await tester.pumpAndSettle();
    expect(captured, isEmpty);
  });
}
