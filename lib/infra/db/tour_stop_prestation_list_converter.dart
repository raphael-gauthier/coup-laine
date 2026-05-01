import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/models/tour_stop_prestation.dart';

class TourStopPrestationListConverter
    extends TypeConverter<List<TourStopPrestation>, String> {
  const TourStopPrestationListConverter();

  @override
  List<TourStopPrestation> fromSql(String fromDb) {
    final decoded = jsonDecode(fromDb) as List<dynamic>;
    return [
      for (final raw in decoded)
        TourStopPrestation(
          prestationId: (raw as Map<String, dynamic>)['prestationId'] as int,
          qty: raw['qty'] as int,
          nameSnapshot: raw['nameSnapshot'] as String,
          priceCentsSnapshot: raw['priceCentsSnapshot'] as int,
          minutesSnapshot: raw['minutesSnapshot'] as int,
          categoryIdSnapshot: raw['categoryIdSnapshot'] as int?,
          categoryNameSnapshot: raw['categoryNameSnapshot'] as String?,
          speciesNameSnapshot: raw['speciesNameSnapshot'] as String?,
        ),
    ];
  }

  @override
  String toSql(List<TourStopPrestation> value) => jsonEncode([
        for (final p in value)
          {
            'prestationId': p.prestationId,
            'qty': p.qty,
            'nameSnapshot': p.nameSnapshot,
            'priceCentsSnapshot': p.priceCentsSnapshot,
            'minutesSnapshot': p.minutesSnapshot,
            'categoryIdSnapshot': p.categoryIdSnapshot,
            'categoryNameSnapshot': p.categoryNameSnapshot,
            'speciesNameSnapshot': p.speciesNameSnapshot,
          },
      ]);
}
