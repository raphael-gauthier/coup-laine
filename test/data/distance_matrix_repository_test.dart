import 'package:coupe_laine/data/repositories/distance_matrix_repository.dart';
import 'package:coupe_laine/domain/models/distance_matrix_entry.dart';
import 'package:coupe_laine/infra/db/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

DistanceMatrixEntry _entry(int from, int to, int dist) =>
    DistanceMatrixEntry(
      fromId: from,
      toId: to,
      distanceMeters: dist,
      durationSeconds: dist ~/ 14, // ~50 km/h
      computedAt: DateTime(2026, 4, 1),
    );

void main() {
  late AppDatabase db;
  late DistanceMatrixRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DistanceMatrixRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('bulk insert and read distance', () async {
    await repo.upsertMany([
      _entry(0, 1, 5000),
      _entry(1, 0, 5100),
      _entry(0, 2, 12000),
    ]);
    expect(await repo.distanceMeters(from: 0, to: 1), 5000);
    expect(await repo.distanceMeters(from: 1, to: 0), 5100);
    expect(await repo.distanceMeters(from: 0, to: 99), isNull);
  });

  test('upsert overwrites existing rows', () async {
    await repo.upsertMany([_entry(0, 1, 5000)]);
    await repo.upsertMany([_entry(0, 1, 6000)]);
    expect(await repo.distanceMeters(from: 0, to: 1), 6000);
  });

  test('deleteForClient removes both directions', () async {
    await repo.upsertMany([
      _entry(0, 1, 5000),
      _entry(1, 0, 5000),
      _entry(1, 2, 3000),
      _entry(2, 1, 3000),
      _entry(0, 2, 8000),
    ]);
    await repo.deleteForClient(1);
    expect(await repo.distanceMeters(from: 0, to: 1), isNull);
    expect(await repo.distanceMeters(from: 1, to: 2), isNull);
    expect(await repo.distanceMeters(from: 0, to: 2), 8000);
  });

  test('proximity query filters by waiting status (joined externally)',
      () async {
    // proximity is a SQL with JOIN; we test the helper that returns
    // the matrix rows below a radius for a given pivot.
    await repo.upsertMany([
      _entry(0, 1, 4000),
      _entry(1, 0, 4000),
      _entry(0, 2, 11000),
      _entry(2, 0, 11000),
      _entry(1, 2, 7000),
      _entry(2, 1, 7000),
    ]);
    final near = await repo.distancesFromPivot(
      pivotId: 1,
      maxDistanceMeters: 8000,
    );
    expect(near.length, 1);
    expect(near.first.toId, 2);
    expect(near.first.distanceMeters, 7000);
  });
}
