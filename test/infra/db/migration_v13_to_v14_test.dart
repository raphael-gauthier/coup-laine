import 'package:coup_laine/infra/db/app_database.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../generated_migrations/schema.dart';

void main() {
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  test('migration v13 → v14 preserves settings data and adds lastBackupAt',
      () async {
    // 1. Ouvre une DB initialisée à la v13.
    final schema = await verifier.schemaAt(13);

    // 2. Insère une row settings v13 via SQL brut (pas de lastBackupAt en v13).
    schema.rawDatabase.execute(
      "INSERT INTO settings (id, base_address_label, base_lat, base_lon) "
      "VALUES (1, 'Plouescat', 48.65, -4.18)",
    );

    // 3. Exécute la migration v13 → v14 et valide le schéma cible.
    final db = AppDatabase.forTesting(schema.newConnection());
    await verifier.migrateAndValidate(db, 14);

    // 4. La row v13 doit avoir survécu, et lastBackupAt doit être null.
    final row = await db.select(db.settingsTable).getSingle();
    expect(row.id, 1);
    expect(row.baseAddressLabel, 'Plouescat');
    expect(row.baseLat, 48.65);
    expect(row.baseLon, -4.18);
    expect(row.lastBackupAt, isNull);

    // 5. La nouvelle colonne accepte une valeur après migration.
    await db.update(db.settingsTable).write(
          const SettingsTableCompanion(lastBackupAt: Value(1234567890)),
        );
    final updated = await db.select(db.settingsTable).getSingle();
    expect(updated.lastBackupAt, 1234567890);

    await db.close();
  });
}
