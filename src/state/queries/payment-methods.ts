import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { db } from '@/infra/db/client';
import { PaymentMethodRepository } from '@/data/repositories/payment-method-repository';
import { newId } from '@/lib/id';
import { mutationErrorToast } from '@/ui/components/error-toast';
import i18n from '@/i18n';
import type { PaymentMethod } from '@/domain/models/payment-method';

const repo = new PaymentMethodRepository(db);

export const paymentMethodsKeys = {
  all: ['paymentMethods'] as const,
  list: (scope: 'active' | 'all') => [...paymentMethodsKeys.all, 'list', scope] as const,
};

export function usePaymentMethods(scope: 'active' | 'all' = 'active') {
  return useQuery({
    queryKey: paymentMethodsKeys.list(scope),
    queryFn: () => (scope === 'active' ? repo.listActive() : repo.listAll()),
    staleTime: Infinity,
  });
}

export interface UpsertPaymentMethodInput {
  id?: string;
  label: string;
  isActive: boolean;
  ordering: number;
}

export function useUpsertPaymentMethod() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (input: UpsertPaymentMethodInput) => {
      const existing = input.id ? await repo.byId(input.id) : null;
      const m: PaymentMethod = {
        id: input.id ?? newId(),
        label: input.label,
        isActive: input.isActive,
        archivedAt: existing?.archivedAt ?? null,
        ordering: input.ordering,
      };
      await repo.upsert(m);
      return m;
    },
    onSuccess: () => { void qc.invalidateQueries({ queryKey: paymentMethodsKeys.all }); },
    onError: (err) => { mutationErrorToast(i18n.t('catalogs.errors.save_failed_title'), err); },
  });
}

export function useArchivePaymentMethod() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async ({ id, archivedAt }: { id: string; archivedAt: string | null }) => {
      await repo.setArchived(id, archivedAt);
    },
    onSuccess: () => { void qc.invalidateQueries({ queryKey: paymentMethodsKeys.all }); },
    onError: (err) => { mutationErrorToast(i18n.t('catalogs.errors.save_failed_title'), err); },
  });
}

export function useDeletePaymentMethod() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => repo.delete(id),
    onSuccess: () => { void qc.invalidateQueries({ queryKey: paymentMethodsKeys.all }); },
    onError: (err) => { mutationErrorToast(i18n.t('catalogs.errors.delete_failed_title'), err); },
  });
}
