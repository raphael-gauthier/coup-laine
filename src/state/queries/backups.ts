import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { createBackup, listBackups, restoreBackup, deleteBackup } from '@/infra/cloud/backups';
import { errorToast } from '@/ui/components/error-toast';

export const backupsKeys = {
  list: ['backups', 'list'] as const,
};

export function useBackups() {
  return useQuery({
    queryKey: backupsKeys.list,
    queryFn: listBackups,
  });
}

export function useCreateBackup() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: createBackup,
    onSuccess: () => {
      void qc.invalidateQueries({ queryKey: backupsKeys.list });
    },
    onError: (err) => {
      errorToast('Sauvegarde impossible', err instanceof Error ? err.message : undefined);
    },
  });
}

export function useRestoreBackup() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (name: string) => restoreBackup(name),
    onSuccess: () => {
      void qc.invalidateQueries();
    },
    onError: (err) => {
      errorToast('Restauration impossible', err instanceof Error ? err.message : undefined);
    },
  });
}

export function useDeleteBackup() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (name: string) => deleteBackup(name),
    onSuccess: () => {
      void qc.invalidateQueries({ queryKey: backupsKeys.list });
    },
    onError: (err) => {
      errorToast('Suppression impossible', err instanceof Error ? err.message : undefined);
    },
  });
}
