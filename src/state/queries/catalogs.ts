import { useMutation, useQueryClient } from '@tanstack/react-query';
import { db } from '@/infra/db/client';
import { SpeciesRepository } from '@/data/repositories/species-repository';
import { AnimalCategoryRepository } from '@/data/repositories/animal-category-repository';
import { PrestationRepository } from '@/data/repositories/prestation-repository';
import { newId } from '@/lib/id';
import { errorToast } from '@/ui/components/error-toast';
import type { Species } from '@/domain/models/species';
import type { AnimalCategory } from '@/domain/models/animal-category';
import type { Prestation } from '@/domain/models/prestation';

const speciesRepo = new SpeciesRepository(db);
const categoryRepo = new AnimalCategoryRepository(db);
const prestationRepo = new PrestationRepository(db);

export interface UpsertSpeciesInput {
  id?: string;
  label: string;
  color: string | null;
  ordering: number;
}

export function useUpsertSpecies() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (input: UpsertSpeciesInput) => {
      const existing = input.id ? await speciesRepo.byId(input.id) : null;
      const species: Species = {
        id: input.id ?? newId(),
        label: input.label,
        color: input.color,
        ordering: input.ordering,
        isCustom: existing?.isCustom ?? true,
      };
      await speciesRepo.upsert(species);
      return species;
    },
    onSuccess: () => {
      void qc.invalidateQueries({ queryKey: ['species'] });
    },
    onError: (err) => {
      errorToast('Enregistrement impossible', err instanceof Error ? err.message : undefined);
    },
  });
}

export function useDeleteSpecies() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (id: string) => {
      const existing = await speciesRepo.byId(id);
      if (existing && !existing.isCustom) {
        throw new Error('Espèce standard non-supprimable');
      }
      await speciesRepo.delete(id);
    },
    onSuccess: () => {
      void qc.invalidateQueries({ queryKey: ['species'] });
    },
    onError: (err) => {
      errorToast('Suppression impossible', err instanceof Error ? err.message : undefined);
    },
  });
}

export interface UpsertCategoryInput {
  id?: string;
  speciesId: string;
  label: string;
  averageMinutesPerUnit: number;
  ordering: number;
}

export function useUpsertAnimalCategory() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (input: UpsertCategoryInput) => {
      const existing = input.id ? await categoryRepo.byId(input.id) : null;
      const cat: AnimalCategory = {
        id: input.id ?? newId(),
        speciesId: input.speciesId,
        label: input.label,
        averageMinutesPerUnit: input.averageMinutesPerUnit,
        ordering: input.ordering,
        isCustom: existing?.isCustom ?? true,
      };
      await categoryRepo.upsert(cat);
      return cat;
    },
    onSuccess: () => {
      void qc.invalidateQueries({ queryKey: ['animalCategories'] });
    },
    onError: (err) => {
      errorToast('Enregistrement impossible', err instanceof Error ? err.message : undefined);
    },
  });
}

export function useDeleteAnimalCategory() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => categoryRepo.delete(id),
    onSuccess: () => {
      void qc.invalidateQueries({ queryKey: ['animalCategories'] });
    },
    onError: (err) => {
      errorToast('Suppression impossible', err instanceof Error ? err.message : undefined);
    },
  });
}

export interface UpsertPrestationInput {
  id?: string;
  label: string;
  price: number | null;
  isActive: boolean;
  ordering: number;
}

export function useUpsertPrestation() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (input: UpsertPrestationInput) => {
      const p: Prestation = {
        id: input.id ?? newId(),
        label: input.label,
        price: input.price,
        isActive: input.isActive,
        ordering: input.ordering,
      };
      await prestationRepo.upsert(p);
      return p;
    },
    onSuccess: () => {
      void qc.invalidateQueries({ queryKey: ['prestations'] });
    },
    onError: (err) => {
      errorToast('Enregistrement impossible', err instanceof Error ? err.message : undefined);
    },
  });
}

export function useDeletePrestation() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => prestationRepo.delete(id),
    onSuccess: () => {
      void qc.invalidateQueries({ queryKey: ['prestations'] });
    },
    onError: (err) => {
      errorToast('Suppression impossible', err instanceof Error ? err.message : undefined);
    },
  });
}
