import 'package:flutter_test/flutter_test.dart';
import 'package:coup_laine/domain/models/prestation.dart';

void main() {
  test('isArchived returns false when archivedAt is null', () {
    const p = Prestation(id: 1, name: 'Tonte');
    expect(p.isArchived, isFalse);
  });

  test('isArchived returns true when archivedAt is set', () {
    final p = Prestation(
      id: 1,
      name: 'Tonte',
      archivedAt: DateTime(2026, 1, 1),
    );
    expect(p.isArchived, isTrue);
  });

  test('all fields are accessible', () {
    final p = Prestation(
      id: 7,
      name: 'Parage',
      priceCents: 5000,
      minutes: 25,
      categoryId: 3,
      archivedAt: DateTime(2026, 5, 1),
    );
    expect(p.id, 7);
    expect(p.name, 'Parage');
    expect(p.priceCents, 5000);
    expect(p.minutes, 25);
    expect(p.categoryId, 3);
    expect(p.archivedAt, DateTime(2026, 5, 1));
  });
}
