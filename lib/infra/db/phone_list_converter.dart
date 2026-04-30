import 'dart:convert';

import 'package:drift/drift.dart';

/// Drift [TypeConverter] that stores `List<String>` as a JSON array in a
/// `TEXT` column. Empty list ↔ `'[]'`. Used by [ClientsTable.phones].
class PhoneListConverter extends TypeConverter<List<String>, String> {
  const PhoneListConverter();

  @override
  List<String> fromSql(String fromDb) {
    final decoded = jsonDecode(fromDb) as List<dynamic>;
    return decoded.cast<String>();
  }

  @override
  String toSql(List<String> value) => jsonEncode(value);
}
