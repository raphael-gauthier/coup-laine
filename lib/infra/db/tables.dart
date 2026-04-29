import 'package:drift/drift.dart';

@DataClassName('SettingsRow')
class SettingsTable extends Table {
  @override
  String get tableName => 'settings';

  IntColumn get id => integer().check(id.equals(1))();
  TextColumn get baseAddressLabel => text()();
  RealColumn get baseLat => real()();
  RealColumn get baseLon => real()();
  IntColumn get defaultRadiusKm => integer().withDefault(const Constant(15))();
  IntColumn get defaultMinutesPerSheep =>
      integer().withDefault(const Constant(20))();
  IntColumn get travelFeeEurosPerBracket =>
      integer().withDefault(const Constant(8))();
  IntColumn get bracketKm => integer().withDefault(const Constant(10))();
  TextColumn get themeMode => text().withDefault(const Constant('system'))();
  TextColumn get markerDefaultColor =>
      text().withDefault(const Constant('#9CA3AF'))();
  TextColumn get markerWaitingColor =>
      text().withDefault(const Constant('#EAB308'))();
  TextColumn get markerScheduledColor =>
      text().withDefault(const Constant('#65A30D'))();
  TextColumn get markerDoneColor =>
      text().withDefault(const Constant('#166534'))();
  TextColumn get markerNoSheepColor =>
      text().withDefault(const Constant('#1F2937'))();
  TextColumn get markerBannedColor =>
      text().withDefault(const Constant('#B91C1C'))();
  IntColumn get seasonStartedAt => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ClientRow')
class ClientsTable extends Table {
  @override
  String get tableName => 'clients';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get addressLabel => text()();
  TextColumn get postcode => text()();
  TextColumn get city => text()();
  RealColumn get lat => real()();
  RealColumn get lon => real()();
  IntColumn get sheepCount => integer().withDefault(const Constant(0))();
  IntColumn get minutesPerSheepOverride => integer().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get markerColorHex => text().nullable()();
  BoolColumn get isWaiting => boolean().withDefault(const Constant(false))();
  IntColumn get lastShearingDate => integer().nullable()();
  BoolColumn get needsDistanceRecompute =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get isBanned => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
}

@DataClassName('DistanceMatrixRow')
class DistanceMatrixTable extends Table {
  @override
  String get tableName => 'distance_matrix';

  /// 0 = base, otherwise client.id
  IntColumn get fromId => integer()();
  IntColumn get toId => integer()();
  IntColumn get distanceMeters => integer()();
  IntColumn get durationSeconds => integer()();
  IntColumn get computedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {fromId, toId};
}

@DataClassName('TourRow')
class ToursTable extends Table {
  @override
  String get tableName => 'tours';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get plannedDate => integer()();
  IntColumn get startTimeMinutes => integer()();
  TextColumn get status => text()(); // 'planned' | 'completed'
  IntColumn get totalDistanceMeters => integer()();
  IntColumn get totalDriveSeconds => integer()();
  IntColumn get totalTravelFeeCents => integer()();
  TextColumn get notes => text().nullable()();
  IntColumn get completedAt => integer().nullable()();
  IntColumn get createdAt => integer()();
}

@DataClassName('TourStopRow')
class TourStopsTable extends Table {
  @override
  String get tableName => 'tour_stops';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get tourId =>
      integer().references(ToursTable, #id, onDelete: KeyAction.cascade)();
  IntColumn get clientId => integer()
      .nullable()
      .references(ClientsTable, #id, onDelete: KeyAction.setNull)();
  TextColumn get clientNameSnapshot => text()();
  IntColumn get orderIndex => integer()();
  IntColumn get estimatedArrivalMinutes => integer()();
  IntColumn get estimatedDepartureMinutes => integer()();
  IntColumn get sheepCountSnapshot => integer()();
  IntColumn get minutesPerSheepSnapshot => integer()();
  IntColumn get feeShareCents => integer()();
}
