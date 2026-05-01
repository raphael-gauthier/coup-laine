import 'package:coup_laine/infra/db/app_database.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('v14 schema includes lastBackupAt nullable column', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());

    // Insérer des settings sans lastBackupAt — doit fonctionner.
    await db.into(db.settingsTable).insert(
          SettingsTableCompanion.insert(
            id: const Value(1),
            baseAddressLabel: 'Test',
            baseLat: 0.0,
            baseLon: 0.0,
          ),
        );
    final row = await db.select(db.settingsTable).getSingle();
    expect(row.lastBackupAt, isNull);

    // Mise à jour avec une valeur.
    await db.update(db.settingsTable).write(
          const SettingsTableCompanion(lastBackupAt: Value(1234567890)),
        );
    final updated = await db.select(db.settingsTable).getSingle();
    expect(updated.lastBackupAt, 1234567890);

    await db.close();
  });
}
