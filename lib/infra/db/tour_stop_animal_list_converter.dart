import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/models/tour_stop_animal.dart';

class TourStopAnimalListConverter
    extends TypeConverter<List<TourStopAnimal>, String> {
  const TourStopAnimalListConverter();

  @override
  List<TourStopAnimal> fromSql(String fromDb) {
    final decoded = jsonDecode(fromDb) as List<dynamic>;
    return [
      for (final raw in decoded)
        TourStopAnimal(
          categoryId: (raw as Map<String, dynamic>)['categoryId'] as int,
          count: raw['count'] as int,
          categoryNameSnapshot: raw['categoryNameSnapshot'] as String,
          speciesNameSnapshot: raw['speciesNameSnapshot'] as String,
          minutesSnapshot: raw['minutesSnapshot'] as int,
        ),
    ];
  }

  @override
  String toSql(List<TourStopAnimal> value) => jsonEncode([
        for (final a in value)
          {
            'categoryId': a.categoryId,
            'count': a.count,
            'categoryNameSnapshot': a.categoryNameSnapshot,
            'speciesNameSnapshot': a.speciesNameSnapshot,
            'minutesSnapshot': a.minutesSnapshot,
          },
      ]);
}
