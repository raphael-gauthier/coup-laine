import 'package:coup_laine/data/repositories/animal_category_repository.dart';
import 'package:coup_laine/data/repositories/species_repository.dart';
import 'package:coup_laine/infra/db/app_database.dart';

class AnimalFixtures {
  final int moutonId;
  final int chevalId;
  final int catPetit;
  final int catGrand;
  final int catPoulain;
  final int catAdulte;

  const AnimalFixtures({
    required this.moutonId,
    required this.chevalId,
    required this.catPetit,
    required this.catGrand,
    required this.catPoulain,
    required this.catAdulte,
  });
}

Future<AnimalFixtures> seedTestSpeciesAndCategories(AppDatabase db) async {
  final species = SpeciesRepository(db);
  final cats = AnimalCategoryRepository(db);
  final mouton = await species.insert(name: 'Mouton');
  final cheval = await species.insert(name: 'Cheval');
  final petit = await cats.insert(speciesId: mouton, name: 'Petit');
  final grand = await cats.insert(speciesId: mouton, name: 'Grand');
  final poulain = await cats.insert(speciesId: cheval, name: 'Poulain');
  final adulte = await cats.insert(speciesId: cheval, name: 'Adulte');
  return AnimalFixtures(
    moutonId: mouton,
    chevalId: cheval,
    catPetit: petit,
    catGrand: grand,
    catPoulain: poulain,
    catAdulte: adulte,
  );
}
