import 'package:coup_laine/domain/models/backup_meta.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('BackupMeta supports equality', () {
    final a = BackupMeta(
      id: '1',
      userId: 'u',
      storagePath: 'p',
      createdAt: DateTime.utc(2026, 5, 1),
      schemaVersion: 2,
      sizeBytes: 100,
    );
    final b = BackupMeta(
      id: '1',
      userId: 'u',
      storagePath: 'p',
      createdAt: DateTime.utc(2026, 5, 1),
      schemaVersion: 2,
      sizeBytes: 100,
    );
    expect(a, equals(b));
  });
}
