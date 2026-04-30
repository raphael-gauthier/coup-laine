import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/models/animal_count.dart';

class AnimalCountListConverter
    extends TypeConverter<List<AnimalCount>, String> {
  const AnimalCountListConverter();

  @override
  List<AnimalCount> fromSql(String fromDb) {
    final decoded = jsonDecode(fromDb) as List<dynamic>;
    return [
      for (final raw in decoded)
        AnimalCount(
          categoryId: (raw as Map<String, dynamic>)['categoryId'] as int,
          count: raw['count'] as int,
        ),
    ];
  }

  @override
  String toSql(List<AnimalCount> value) => jsonEncode([
        for (final a in value) {'categoryId': a.categoryId, 'count': a.count},
      ]);
}
