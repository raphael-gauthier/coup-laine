class SpeciesSeed {
  final String name;
  final List<CategorySeed> categories;
  const SpeciesSeed({required this.name, required this.categories});
}

class CategorySeed {
  final String name;
  final String? defaultPrestationName;
  const CategorySeed({required this.name, this.defaultPrestationName});
}

const kSpeciesSeeds = <SpeciesSeed>[
  SpeciesSeed(name: 'Mouton', categories: [
    CategorySeed(name: 'Petit', defaultPrestationName: 'Tonte'),
    CategorySeed(name: 'Grand', defaultPrestationName: 'Tonte'),
  ]),
  SpeciesSeed(name: 'Cheval', categories: [
    CategorySeed(name: 'Poulain', defaultPrestationName: 'Parage'),
    CategorySeed(name: 'Adulte', defaultPrestationName: 'Parage'),
  ]),
  SpeciesSeed(name: 'Bovin', categories: [
    CategorySeed(name: 'Veau', defaultPrestationName: 'Parage'),
    CategorySeed(name: 'Adulte', defaultPrestationName: 'Parage'),
  ]),
  SpeciesSeed(name: 'Caprin', categories: [
    CategorySeed(name: 'Chèvre', defaultPrestationName: 'Onglons'),
  ]),
];
