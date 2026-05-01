// test/core/animal_icons_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:coup_laine/core/animal_icons.dart';

void main() {
  group('iconAssetForSpeciesKey', () {
    test('mouton, cheval, bovin, caprin → asset SVG', () {
      expect(iconAssetForSpeciesKey('mouton'), 'assets/icons/cl_sheep.svg');
      expect(iconAssetForSpeciesKey('cheval'), 'assets/icons/cl_horse.svg');
      expect(iconAssetForSpeciesKey('bovin'), 'assets/icons/cl_cow.svg');
      expect(iconAssetForSpeciesKey('caprin'), 'assets/icons/cl_goat.svg');
    });

    test('case-insensitive', () {
      expect(iconAssetForSpeciesKey('Mouton'), 'assets/icons/cl_sheep.svg');
      expect(iconAssetForSpeciesKey('CHEVAL'), 'assets/icons/cl_horse.svg');
    });

    test('clé inconnue → null (fallback à FIcons côté caller)', () {
      expect(iconAssetForSpeciesKey('lama'), isNull);
      expect(iconAssetForSpeciesKey(''), isNull);
    });
  });
}
