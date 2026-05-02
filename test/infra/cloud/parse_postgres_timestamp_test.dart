import 'package:coup_laine/infra/cloud/backups_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parsePostgresTimestamp', () {
    test('string with Z offset is preserved as UTC', () {
      final result = parsePostgresTimestamp('2026-05-02T07:08:00.000Z');
      expect(result.isUtc, isTrue);
      expect(result.hour, 7);
      expect(result.minute, 8);
    });

    test('string with explicit +00:00 offset is preserved as UTC', () {
      final result = parsePostgresTimestamp('2026-05-02T07:08:00+00:00');
      expect(result.isUtc, isTrue);
      expect(result.hour, 7);
      expect(result.minute, 8);
    });

    test('string with non-zero offset returns UTC equivalent', () {
      // 09:08+02:00 = 07:08 UTC
      final result = parsePostgresTimestamp('2026-05-02T09:08:00+02:00');
      expect(result.isUtc, isTrue);
      expect(result.hour, 7);
      expect(result.minute, 8);
    });

    test('string without timezone marker is reinterpreted as UTC', () {
      // This is the bug fix : DateTime.parse would treat this as local;
      // we force UTC because Postgres timestamptz is conceptually UTC.
      final result = parsePostgresTimestamp('2026-05-02T07:08:00.123456');
      expect(result.isUtc, isTrue);
      expect(result.year, 2026);
      expect(result.month, 5);
      expect(result.day, 2);
      expect(result.hour, 7);
      expect(result.minute, 8);
      expect(result.second, 0);
    });

    test('round-trips through toLocal then DateFormat HH:mm shows local hour',
        () {
      // If the user is at UTC+2, a 07:08 UTC backup should show as 09:08
      // local. We can't change the test runner's timezone reliably, but
      // we can verify the UTC instant is correctly identified.
      final result = parsePostgresTimestamp('2026-05-02T07:08:00');
      // Convert to UTC explicitly — the local Hour depends on the runner's
      // timezone, so we just assert the UTC instant matches.
      expect(result.toUtc().hour, 7);
      expect(result.toUtc().minute, 8);
    });
  });
}
