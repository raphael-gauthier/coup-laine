import type { AnimalCount } from '@/domain/models/animal-count';
import { pluralizeFr } from '@/lib/text-pluralization';

interface SpeciesLite { id: string; label: string }
interface CategoryLite { id: string; speciesId: string }

/**
 * Aggregates animal counts by species, returning a French label like
 * "12 Moutons, 4 Chevaux". Empty input or all-zero counts yield "".
 * Counts whose categoryId no longer resolves are skipped silently.
 */
export function formatAnimalCountsBySpecies(
  counts: AnimalCount[],
  species: SpeciesLite[],
  categories: CategoryLite[]
): string {
  const speciesById = new Map(species.map((s) => [s.id, s]));
  const categoriesById = new Map(categories.map((c) => [c.id, c]));
  const totals = new Map<string, number>();
  for (const ac of counts) {
    if (ac.count <= 0) continue;
    const cat = categoriesById.get(ac.categoryId);
    if (!cat) continue;
    const sp = speciesById.get(cat.speciesId);
    if (!sp) continue;
    totals.set(sp.label, (totals.get(sp.label) ?? 0) + ac.count);
  }
  return Array.from(totals.entries())
    .map(([name, total]) => `${total} ${pluralizeFr(name, total)}`)
    .join(', ');
}
