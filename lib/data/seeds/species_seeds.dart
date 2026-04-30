class SpeciesSeed {
  final String name;
  final List<CategorySeed> categories;
  const SpeciesSeed({required this.name, required this.categories});
}

class CategorySeed {
  final String name;
  const CategorySeed({required this.name});
}

const kSpeciesSeeds = <SpeciesSeed>[
  SpeciesSeed(name: 'Mouton', categories: [
    CategorySeed(name: 'Petit'),
    CategorySeed(name: 'Grand'),
  ]),
  SpeciesSeed(name: 'Cheval', categories: [
    CategorySeed(name: 'Poulain'),
    CategorySeed(name: 'Adulte'),
  ]),
  SpeciesSeed(name: 'Bovin', categories: [
    CategorySeed(name: 'Veau'),
    CategorySeed(name: 'Adulte'),
  ]),
  SpeciesSeed(name: 'Caprin', categories: [
    CategorySeed(name: 'Chèvre'),
  ]),
];
