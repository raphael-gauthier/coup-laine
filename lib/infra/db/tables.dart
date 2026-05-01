import 'package:drift/drift.dart';
import 'animal_count_list_converter.dart';
import 'phone_list_converter.dart';
import 'tour_stop_animal_list_converter.dart';
import 'tour_stop_prestation_list_converter.dart';

@DataClassName('SettingsRow')
class SettingsTable extends Table {
  @override
  String get tableName => 'settings';

  // ignore: recursive_getters
  IntColumn get id => integer().check(id.equals(1))();
  TextColumn get baseAddressLabel => text()();
  RealColumn get baseLat => real()();
  RealColumn get baseLon => real()();
  IntColumn get defaultRadiusKm => integer().withDefault(const Constant(15))();
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
  TextColumn get markerNoAnimalsColor =>
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
  TextColumn get phones => text()
      .map(const PhoneListConverter())
      .withDefault(const Constant('[]'))();
  TextColumn get addressLabel => text()();
  TextColumn get postcode => text()();
  TextColumn get city => text()();
  RealColumn get lat => real()();
  RealColumn get lon => real()();
  TextColumn get animals => text()
      .map(const AnimalCountListConverter())
      .withDefault(const Constant('[]'))();
  TextColumn get markerColorHex => text().nullable()();
  BoolColumn get isWaiting => boolean().withDefault(const Constant(false))();
  IntColumn get lastInterventionDate => integer().nullable()();
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

  IntColumn get fromId => integer()();
  IntColumn get toId => integer()();
  IntColumn get distanceMeters => integer()();
  IntColumn get durationSeconds => integer()();
  IntColumn get computedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {fromId, toId};
}

@DataClassName('SpeciesRow')
class SpeciesTable extends Table {
  @override
  String get tableName => 'species';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get iconKey => text().nullable()();
  IntColumn get archivedAt => integer().nullable()();
  IntColumn get createdAt => integer()();
}

@DataClassName('AnimalCategoryRow')
class AnimalCategoriesTable extends Table {
  @override
  String get tableName => 'animal_categories';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get speciesId => integer()
      .references(SpeciesTable, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  IntColumn get archivedAt => integer().nullable()();
  IntColumn get createdAt => integer()();
}

@DataClassName('TourRow')
class ToursTable extends Table {
  @override
  String get tableName => 'tours';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get plannedDate => integer()();
  IntColumn get startTimeMinutes => integer()();
  TextColumn get status => text()();
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
  TextColumn get plannedAnimals => text()
      .map(const TourStopAnimalListConverter())
      .withDefault(const Constant('[]'))();
  TextColumn get actualAnimals => text()
      .map(const TourStopAnimalListConverter())
      .nullable()();
  TextColumn get plannedPrestations => text()
      .map(const TourStopPrestationListConverter())
      .withDefault(const Constant('[]'))();
  TextColumn get actualPrestations => text()
      .map(const TourStopPrestationListConverter())
      .nullable()();
  TextColumn get interventionNote => text().nullable()();
  IntColumn get feeShareCents => integer()();
}

@DataClassName('ManualHistoryEntryRow')
class ManualHistoryEntriesTable extends Table {
  @override
  String get tableName => 'manual_history_entries';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get clientId => integer()
      .references(ClientsTable, #id, onDelete: KeyAction.cascade)();
  IntColumn get date => integer()();
  TextColumn get animals => text()
      .map(const TourStopAnimalListConverter())
      .withDefault(const Constant('[]'))();
  TextColumn get prestations => text()
      .map(const TourStopPrestationListConverter())
      .withDefault(const Constant('[]'))();
  TextColumn get note => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
}

@DataClassName('PrestationRow')
class PrestationsTable extends Table {
  @override
  String get tableName => 'prestations';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get priceCents => integer().nullable()();
  IntColumn get minutes => integer().nullable()();
  IntColumn get categoryId => integer().nullable()
      .references(AnimalCategoriesTable, #id, onDelete: KeyAction.setNull)();
  IntColumn get archivedAt => integer().nullable()();
  IntColumn get createdAt => integer()();
}
