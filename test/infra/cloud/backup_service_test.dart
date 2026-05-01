import 'package:coup_laine/infra/cloud/backup_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('shouldRunAutoBackup', () {
    final now = DateTime.utc(2026, 5, 1, 12);

    test('false si pas opt-in', () {
      expect(
        shouldRunAutoBackup(
          now: now,
          cloudOptIn: false,
          lastBackupAt: null,
          hasNetwork: true,
        ),
        isFalse,
      );
    });

    test('false si pas de réseau', () {
      expect(
        shouldRunAutoBackup(
          now: now,
          cloudOptIn: true,
          lastBackupAt: null,
          hasNetwork: false,
        ),
        isFalse,
      );
    });

    test('true si jamais sauvegardé', () {
      expect(
        shouldRunAutoBackup(
          now: now,
          cloudOptIn: true,
          lastBackupAt: null,
          hasNetwork: true,
        ),
        isTrue,
      );
    });

    test('false si dernier backup < 24h', () {
      expect(
        shouldRunAutoBackup(
          now: now,
          cloudOptIn: true,
          lastBackupAt: now.subtract(const Duration(hours: 23)),
          hasNetwork: true,
        ),
        isFalse,
      );
    });

    test('true si dernier backup >= 24h', () {
      expect(
        shouldRunAutoBackup(
          now: now,
          cloudOptIn: true,
          lastBackupAt: now.subtract(const Duration(hours: 24, minutes: 1)),
          hasNetwork: true,
        ),
        isTrue,
      );
    });
  });
}
