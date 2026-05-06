import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { File, Paths } from 'expo-file-system';
import * as Sharing from 'expo-sharing';
import { createBackup, listBackups, restoreBackup, deleteBackup } from '@/infra/cloud/backups';
import { supabase } from '@/infra/services/supabase';
import { mutationErrorToast } from '@/ui/components/error-toast';
import i18n from '@/i18n';

const BUCKET = 'backups';

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

export function useExportData() {
  return useMutation({
    mutationFn: async () => {
      const { data: { session } } = await supabase.auth.getSession();
      if (!session?.user.id || session.user.is_anonymous) {
        throw new Error('Not signed in');
      }

      // 1. Create a fresh backup snapshot.
      const path = await createBackup();

      // 2. Download the JSON snapshot from Storage.
      const { data, error } = await supabase.storage.from(BUCKET).download(path);
      if (error) throw error;
      const jsonText = await data.text();

      // 3. Write to a temp file.
      const filename = `coup-laine-export-${new Date().toISOString().replace(/[:.]/g, '-')}.json`;
      const file = new File(Paths.cache, filename);
      file.write(jsonText);

      // 4. Open the native share-sheet.
      const available = await Sharing.isAvailableAsync();
      if (!available) {
        throw new Error('Sharing not available on this platform');
      }
      await Sharing.shareAsync(file.uri, {
        mimeType: 'application/json',
        dialogTitle: i18n.t('cloud.export_data.dialog_title'),
        UTI: 'public.json',
      });
    },
    onError: (err) => {
      mutationErrorToast(i18n.t('cloud.export_data.error_toast'), err);
    },
  });
}
