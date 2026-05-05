export type SpeciesKey =
  | 'mouton'
  | 'chevre'
  | 'lama'
  | 'bovin'
  | 'cheval'
  | 'chien'
  | 'chat'
  | 'volaille'
  | 'nac';

export interface CatalogSpecies {
  key: SpeciesKey;
  id: string;
  label: string;
  iconKey: string;
  ordering: number;
  defaultCategoryId: string;
}

export const SPECIES_CATALOG: CatalogSpecies[] = [
  { key: 'mouton',   id: 'species-mouton',   label: 'Moutons',   iconKey: 'sheep',  ordering: 1, defaultCategoryId: 'cat-mouton' },
  { key: 'chevre',   id: 'species-chevre',   label: 'Chèvres',   iconKey: 'goat',   ordering: 2, defaultCategoryId: 'cat-chevre' },
  { key: 'lama',     id: 'species-lama',     label: 'Lamas',     iconKey: 'llama',  ordering: 3, defaultCategoryId: 'cat-lama' },
  { key: 'bovin',    id: 'species-bovin',    label: 'Bovins',    iconKey: 'cow',    ordering: 4, defaultCategoryId: 'cat-bovin' },
  { key: 'cheval',   id: 'species-cheval',   label: 'Chevaux',   iconKey: 'horse',  ordering: 5, defaultCategoryId: 'cat-cheval' },
  { key: 'chien',    id: 'species-chien',    label: 'Chiens',    iconKey: 'dog',    ordering: 6, defaultCategoryId: 'cat-chien' },
  { key: 'chat',     id: 'species-chat',     label: 'Chats',     iconKey: 'cat',    ordering: 7, defaultCategoryId: 'cat-chat' },
  { key: 'volaille', id: 'species-volaille', label: 'Volailles', iconKey: 'bird',   ordering: 8, defaultCategoryId: 'cat-volaille' },
  { key: 'nac',      id: 'species-nac',      label: 'NAC',       iconKey: 'rabbit', ordering: 9, defaultCategoryId: 'cat-nac' },
];

export interface ProfessionPreset {
  id: string;
  label: string;
  speciesKeys: SpeciesKey[];
  services: Array<{ speciesKey: SpeciesKey; label: string }>;
}

export const PROFESSION_PRESETS: ProfessionPreset[] = [
  {
    id: 'tondeur_ovin',
    label: 'Tondeur ovin/caprin/camélidés',
    speciesKeys: ['mouton', 'chevre', 'lama'],
    services: [
      { speciesKey: 'mouton', label: 'Tonte' },
      { speciesKey: 'mouton', label: 'Pédicure' },
      { speciesKey: 'chevre', label: 'Tonte' },
      { speciesKey: 'chevre', label: 'Pédicure' },
      { speciesKey: 'lama',   label: 'Tonte' },
      { speciesKey: 'lama',   label: 'Pédicure' },
    ],
  },
  {
    id: 'marechal_ferrant',
    label: 'Maréchal-ferrant',
    speciesKeys: ['cheval'],
    services: [
      { speciesKey: 'cheval', label: 'Parage' },
      { speciesKey: 'cheval', label: 'Ferrure' },
      { speciesKey: 'cheval', label: 'Déferrage' },
    ],
  },
  {
    id: 'pareur_equin',
    label: 'Pareur équin',
    speciesKeys: ['cheval'],
    services: [
      { speciesKey: 'cheval', label: 'Parage' },
    ],
  },
  {
    id: 'pedicure_bovin',
    label: 'Pédicure bovin (pareur)',
    speciesKeys: ['bovin'],
    services: [
      { speciesKey: 'bovin', label: 'Parage préventif' },
      { speciesKey: 'bovin', label: 'Parage curatif' },
    ],
  },
  {
    id: 'dentiste_equin',
    label: 'Dentiste équin',
    speciesKeys: ['cheval'],
    services: [
      { speciesKey: 'cheval', label: 'Nivellement dentaire' },
      { speciesKey: 'cheval', label: 'Extraction dent de loup' },
    ],
  },
  {
    id: 'osteopathe',
    label: 'Ostéopathe animalier',
    speciesKeys: ['cheval', 'chien', 'chat', 'bovin'],
    services: [
      { speciesKey: 'cheval', label: 'Séance ostéopathie' },
      { speciesKey: 'chien',  label: 'Séance ostéopathie' },
      { speciesKey: 'chat',   label: 'Séance ostéopathie' },
      { speciesKey: 'bovin',  label: 'Séance ostéopathie' },
      { speciesKey: 'cheval', label: 'Bilan postural' },
    ],
  },
  {
    id: 'veto_rural',
    label: 'Vétérinaire rural',
    speciesKeys: ['bovin', 'mouton', 'chevre', 'cheval'],
    services: [
      { speciesKey: 'bovin',  label: 'Prophylaxie' },
      { speciesKey: 'bovin',  label: 'Vaccination' },
      { speciesKey: 'bovin',  label: 'Visite sanitaire' },
      { speciesKey: 'mouton', label: 'Prophylaxie' },
      { speciesKey: 'chevre', label: 'Prophylaxie' },
    ],
  },
  {
    id: 'toiletteur',
    label: 'Toiletteur',
    speciesKeys: ['chien', 'chat'],
    services: [
      { speciesKey: 'chien', label: 'Toilettage complet' },
      { speciesKey: 'chien', label: 'Bain' },
      { speciesKey: 'chien', label: 'Coupe' },
      { speciesKey: 'chat',  label: 'Toilettage complet' },
    ],
  },
  {
    id: 'educateur_canin',
    label: 'Éducateur canin',
    speciesKeys: ['chien'],
    services: [
      { speciesKey: 'chien', label: 'Cours individuel' },
      { speciesKey: 'chien', label: 'Cours collectif' },
      { speciesKey: 'chien', label: 'Bilan comportemental' },
    ],
  },
  {
    id: 'inseminateur',
    label: 'Inséminateur',
    speciesKeys: ['bovin'],
    services: [
      { speciesKey: 'bovin', label: 'Insémination artificielle' },
      { speciesKey: 'bovin', label: 'Constat de gestation' },
    ],
  },
];

export function speciesByKey(key: SpeciesKey): CatalogSpecies {
  const found = SPECIES_CATALOG.find((s) => s.key === key);
  if (!found) throw new Error(`Unknown species key: ${key}`);
  return found;
}

export function professionById(id: string): ProfessionPreset | null {
  return PROFESSION_PRESETS.find((m) => m.id === id) ?? null;
}

export function unionSpeciesFromProfessions(professionIds: string[]): SpeciesKey[] {
  const set = new Set<SpeciesKey>();
  for (const id of professionIds) {
    const m = professionById(id);
    if (!m) continue;
    for (const k of m.speciesKeys) set.add(k);
  }
  return SPECIES_CATALOG.filter((s) => set.has(s.key)).map((s) => s.key);
}

export function unionServicesFromProfessions(
  professionIds: string[],
  enabledSpecies: SpeciesKey[]
): Array<{ speciesKey: SpeciesKey; label: string }> {
  const enabled = new Set(enabledSpecies);
  const seen = new Set<string>();
  const out: Array<{ speciesKey: SpeciesKey; label: string }> = [];
  for (const id of professionIds) {
    const m = professionById(id);
    if (!m) continue;
    for (const p of m.services) {
      if (!enabled.has(p.speciesKey)) continue;
      const k = `${p.speciesKey}|${p.label}`;
      if (seen.has(k)) continue;
      seen.add(k);
      out.push(p);
    }
  }
  return out;
}
