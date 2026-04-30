import 'package:flutter_test/flutter_test.dart';
import 'package:coup_laine/data/seeds/species_seeds.dart';

void main() {
  test('kSpeciesSeeds contains the 4 expected species', () {
    expect(
      kSpeciesSeeds.map((s) => s.name).toList(),
      ['Mouton', 'Cheval', 'Bovin', 'Caprin'],
    );
  });

  test('Mouton has Petit and Grand categories', () {
    final mouton = kSpeciesSeeds.firstWhere((s) => s.name == 'Mouton');
    expect(mouton.categories.map((c) => c.name).toList(), ['Petit', 'Grand']);
  });

  test('Caprin has a single Chèvre category', () {
    final caprin = kSpeciesSeeds.firstWhere((s) => s.name == 'Caprin');
    expect(caprin.categories.map((c) => c.name).toList(), ['Chèvre']);
  });

  test('seeds carry no minutes nor price (filled later by user)', () {
    for (final s in kSpeciesSeeds) {
      for (final c in s.categories) {
        expect(c.name, isNotEmpty);
      }
    }
  });
}
