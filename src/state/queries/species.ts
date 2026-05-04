import { useQuery } from '@tanstack/react-query';
import { db } from '@/infra/db/client';
import { SpeciesRepository } from '@/data/repositories/species-repository';
import { AnimalCategoryRepository } from '@/data/repositories/animal-category-repository';
import { ServiceRepository } from '@/data/repositories/service-repository';

const speciesRepo = new SpeciesRepository(db);
const categoryRepo = new AnimalCategoryRepository(db);
const serviceRepo = new ServiceRepository(db);

export const speciesKeys = {
  all: ['species'] as const,
};

export function useSpecies() {
  return useQuery({
    queryKey: [...speciesKeys.all, 'list'],
    queryFn: () => speciesRepo.listAll(),
    staleTime: Infinity,
  });
}

export function useAnimalCategories() {
  return useQuery({
    queryKey: ['animalCategories', 'list'],
    queryFn: () => categoryRepo.listAll(),
    staleTime: Infinity,
  });
}

export function useServices() {
  return useQuery({
    queryKey: ['services', 'list'],
    queryFn: () => serviceRepo.listAll(),
    staleTime: Infinity,
  });
}
