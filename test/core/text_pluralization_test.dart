import 'package:coup_laine/core/text_pluralization.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('pluralizeFr', () {
    test('count <= 1 returns the word unchanged', () {
      expect(pluralizeFr('Mouton', 0), 'Mouton');
      expect(pluralizeFr('Mouton', 1), 'Mouton');
    });

    test('regular nouns get +s', () {
      expect(pluralizeFr('Mouton', 5), 'Moutons');
      expect(pluralizeFr('Bovin', 3), 'Bovins');
      expect(pluralizeFr('Caprin', 2), 'Caprins');
      expect(pluralizeFr('Petit', 5), 'Petits');
      expect(pluralizeFr('Grand', 12), 'Grands');
      expect(pluralizeFr('Poulain', 2), 'Poulains');
      expect(pluralizeFr('Adulte', 5), 'Adultes');
      expect(pluralizeFr('Chèvre', 3), 'Chèvres');
    });

    test('-al → -aux', () {
      expect(pluralizeFr('Cheval', 2), 'Chevaux');
      expect(pluralizeFr('cheval', 2), 'chevaux');
    });

    test('-au, -eau, -eu → +x', () {
      expect(pluralizeFr('Veau', 3), 'Veaux');
      expect(pluralizeFr('Cheveu', 4), 'Cheveux');
      expect(pluralizeFr('Tuyau', 5), 'Tuyaux');
    });

    test('words ending in s/x/z are invariable', () {
      expect(pluralizeFr('Brebis', 5), 'Brebis');
      expect(pluralizeFr('Lynx', 2), 'Lynx');
      expect(pluralizeFr('Nez', 3), 'Nez');
    });

    test('compound nouns: each token is pluralized', () {
      expect(pluralizeFr('Lapin nain', 2), 'Lapins nains');
      expect(pluralizeFr('Cheval blanc', 3), 'Chevaux blancs');
      expect(pluralizeFr('Petite chèvre', 4), 'Petites chèvres');
    });

    test('empty input', () {
      expect(pluralizeFr('', 5), '');
    });
  });
}
