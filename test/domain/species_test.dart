import 'package:flutter_test/flutter_test.dart';
import 'package:coup_laine/domain/models/species.dart';

void main() {
  test('Species defaults: archivedAt and iconKey are null', () {
    const s = Species(id: 1, name: 'Mouton');
    expect(s.archivedAt, isNull);
    expect(s.iconKey, isNull);
    expect(s.isArchived, isFalse);
  });

  test('Species.isArchived is true when archivedAt is set', () {
    final s = Species(id: 1, name: 'Mouton', archivedAt: DateTime(2026));
    expect(s.isArchived, isTrue);
  });
}
