import 'package:flutter_test/flutter_test.dart';
import 'package:coup_laine/domain/models/animal_count.dart';
import 'package:coup_laine/infra/db/animal_count_list_converter.dart';

void main() {
  const c = AnimalCountListConverter();

  test('empty list round-trips through "[]"', () {
    expect(c.toSql(const []), '[]');
    expect(c.fromSql('[]'), const <AnimalCount>[]);
  });

  test('round-trips a populated list', () {
    final list = const [
      AnimalCount(categoryId: 1, count: 5),
      AnimalCount(categoryId: 4, count: 12),
    ];
    final sql = c.toSql(list);
    expect(c.fromSql(sql), list);
  });
}
