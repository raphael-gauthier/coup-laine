import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:coup_laine/domain/models/animal_count.dart';
import 'package:coup_laine/presentation/widgets/animal_counts_badges.dart';
import 'package:coup_laine/state/providers.dart';

void main() {
  Map<int, ({String speciesName, String categoryName, int minutes})>
      stubLookup() => {
            1: (speciesName: 'Mouton', categoryName: 'Petit', minutes: 8),
            2: (speciesName: 'Mouton', categoryName: 'Grand', minutes: 25),
            3: (speciesName: 'Cheval', categoryName: 'Adulte', minutes: 45),
          };

  testWidgets('compact mode sums per species', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          categoryLookupProvider.overrideWith((ref) async => stubLookup()),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: AnimalCountsBadges(
              counts: [
                AnimalCount(categoryId: 1, count: 5),
                AnimalCount(categoryId: 2, count: 12),
                AnimalCount(categoryId: 3, count: 4),
              ],
              mode: AnimalCountsBadgesMode.compact,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('17 Mouton, 4 Cheval'), findsOneWidget);
  });

  testWidgets('detailed mode shows per-category breakdown', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          categoryLookupProvider.overrideWith((ref) async => stubLookup()),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: AnimalCountsBadges(
              counts: [
                AnimalCount(categoryId: 1, count: 5),
                AnimalCount(categoryId: 2, count: 12),
              ],
              mode: AnimalCountsBadgesMode.detailed,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('5 Petit'), findsOneWidget);
    expect(find.textContaining('12 Grand'), findsOneWidget);
    expect(find.textContaining('Mouton'), findsOneWidget);
  });

  testWidgets('empty counts → SizedBox.shrink (no text)', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          categoryLookupProvider.overrideWith((ref) async => stubLookup()),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: AnimalCountsBadges(
              counts: [],
              mode: AnimalCountsBadgesMode.compact,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(Text), findsNothing);
  });

  testWidgets('counts with unknown categoryId are skipped silently',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          categoryLookupProvider.overrideWith((ref) async => stubLookup()),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: AnimalCountsBadges(
              counts: [
                AnimalCount(categoryId: 999, count: 99),
                AnimalCount(categoryId: 1, count: 5),
              ],
              mode: AnimalCountsBadgesMode.compact,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('5 Mouton'), findsOneWidget);
  });
}
