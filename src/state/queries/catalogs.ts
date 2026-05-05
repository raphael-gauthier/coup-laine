import { useMutation, useQueryClient } from '@tanstack/react-query';
import { db } from '@/infra/db/client';
import { SpeciesRepository } from '@/data/repositories/species-repository';
import { AnimalCategoryRepository } from '@/data/repositories/animal-category-repository';
import { ServiceRepository } from '@/data/repositories/service-repository';
import { newId } from '@/lib/id';
import { mutationErrorToast } from '@/ui/components/error-toast';
import i18n from '@/i18n';
import type { Species } from '@/domain/models/species';
import type { AnimalCategory } from '@/domain/models/animal-category';
import type { Service } from '@/domain/models/service';

const speciesRepo = new SpeciesRepository(db);
const categoryRepo = new AnimalCategoryRepository(db);
const serviceRepo = new ServiceRepository(db);

export interface UpsertSpeciesInput {
  id?: string;
  label: string;
  iconKey: string | null;
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
        iconKey: input.iconKey,
        ordering: input.ordering,
        isCustom: existing?.isCustom ?? true,
        archivedAt: existing?.archivedAt ?? null,
      };
      await speciesRepo.upsert(species);
      return species;
    },
    onSuccess: () => {
      void qc.invalidateQueries({ queryKey: ['species'] });
    },
    onError: (err) => {
      mutationErrorToast(i18n.t('catalogs.errors.save_failed_title'), err);
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
      mutationErrorToast(i18n.t('catalogs.errors.delete_failed_title'), err);
    },
  });
}

export interface UpsertCategoryInput {
  id?: string;
  speciesId: string;
  label: string;
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
        ordering: input.ordering,
        isCustom: existing?.isCustom ?? true,
        archivedAt: existing?.archivedAt ?? null,
      };
      await categoryRepo.upsert(cat);
      return cat;
    },
    onSuccess: () => {
      void qc.invalidateQueries({ queryKey: ['animalCategories'] });
    },
    onError: (err) => {
      mutationErrorToast(i18n.t('catalogs.errors.save_failed_title'), err);
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
      mutationErrorToast(i18n.t('catalogs.errors.delete_failed_title'), err);
    },
  });
}

export interface UpsertServiceInput {
  id?: string;
  label: string;
  priceCents: number | null;
  minutes: number;
  categoryId: string | null;
  isActive: boolean;
  ordering: number;
}

export function useUpsertService() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (input: UpsertServiceInput) => {
      const existing = input.id ? await serviceRepo.byId(input.id) : null;
      const p: Service = {
        id: input.id ?? newId(),
        label: input.label,
        priceCents: input.priceCents,
        minutes: input.minutes,
        categoryId: input.categoryId,
        isActive: input.isActive,
        archivedAt: existing?.archivedAt ?? null,
        ordering: input.ordering,
      };
      await serviceRepo.upsert(p);
      return p;
    },
    onSuccess: () => {
      void qc.invalidateQueries({ queryKey: ['services'] });
    },
    onError: (err) => {
      mutationErrorToast(i18n.t('catalogs.errors.save_failed_title'), err);
    },
  });
}

export function useDeleteService() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => serviceRepo.delete(id),
    onSuccess: () => {
      void qc.invalidateQueries({ queryKey: ['services'] });
    },
    onError: (err) => {
      mutationErrorToast(i18n.t('catalogs.errors.delete_failed_title'), err);
    },
  });
}
