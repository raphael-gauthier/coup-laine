import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { createBackup, listBackups, restoreBackup, deleteBackup } from '@/infra/cloud/backups';
import { mutationErrorToast } from '@/ui/components/error-toast';
import i18n from '@/i18n';

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
      mutationErrorToast(i18n.t('cloud.errors.backup_failed_title'), err);
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
      mutationErrorToast(i18n.t('cloud.errors.restore_failed_title'), err);
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
      mutationErrorToast(i18n.t('cloud.errors.delete_failed_title'), err);
    },
  });
}
