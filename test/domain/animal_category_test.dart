import 'package:flutter_test/flutter_test.dart';
import 'package:coup_laine/domain/models/animal_category.dart';

void main() {
  test('defaults: archivedAt is null', () {
    const c = AnimalCategory(id: 1, speciesId: 1, name: 'Petit');
    expect(c.archivedAt, isNull);
    expect(c.isArchived, isFalse);
  });

  test('isArchived true when archivedAt set', () {
    final c = AnimalCategory(
      id: 1,
      speciesId: 1,
      name: 'Petit',
      archivedAt: DateTime(2026),
    );
    expect(c.isArchived, isTrue);
  });
}
