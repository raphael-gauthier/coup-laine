import { useState } from 'react';
import { View, ScrollView } from 'react-native';
import { useRouter } from 'expo-router';
import { useTranslation } from 'react-i18next';
import { format, formatDistanceToNow, parseISO } from 'date-fns';
import { fr } from 'date-fns/locale';
import { CloudUpload, RefreshCw, Trash2, Download, AlertTriangle } from 'lucide-react-native';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { Button } from '@/ui/primitives/button';
import { ListSkeleton } from '@/ui/primitives/skeleton';
import { ErrorState } from '@/ui/components/error-state';
import { EmptyState } from '@/ui/components/empty-state';
import { ScreenHeader } from '@/ui/components/screen-header';
import { SectionHeader } from '@/ui/primitives/section-header';
import { confirm, ConfirmTypedDialog } from '@/ui/components/confirm-dialog';
import { useSession, useSignOut, useDeleteAccount } from '@/state/queries/auth';
import { useBackups, useCreateBackup, useRestoreBackup, useDeleteBackup, useExportData } from '@/state/queries/backups';
import { successToast } from '@/ui/components/error-toast';
import { useOnContrastColor, useForegroundColor } from '@/ui/theme/colors';

export default function CloudScreen() {
  const { t } = useTranslation();
  const router = useRouter();
  const onContrast = useOnContrastColor();
  const fg = useForegroundColor();
  const { data: session } = useSession();
  const signOut = useSignOut();
  const create = useCreateBackup();
  const restore = useRestoreBackup();
  const del = useDeleteBackup();
  const exportData = useExportData();
  const deleteAccount = useDeleteAccount();
  const { data: backups = [], isError, isLoading, refetch } = useBackups();
  const [restoreDialogName, setRestoreDialogName] = useState<string | null>(null);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);

  if (!session || session.user.is_anonymous) {
    return (
      <Surface className="flex-1">
        <ScreenHeader title={t('cloud.screen_title')} />
        <View className="flex-1 px-6 items-center justify-center gap-6">
          <Text className="text-center" variant="muted">{t('cloud.row_hint_logged_out')}</Text>
          <Button onPress={() => router.push('/auth/login' as never)}>
            {t('cloud.sign_in_cta')}
          </Button>
        </View>
      </Surface>
    );
  }

  const onRestore = (name: string) => {
    setRestoreDialogName(name);
  };

  const handleRestoreConfirmed = () => {
    if (!restoreDialogName) return;
    const name = restoreDialogName;
    setRestoreDialogName(null);
    restore.mutate(name, {
      onSuccess: () => {
        successToast(t('cloud.restore_success_title'), t('cloud.restore_success_message'));
      },
    });
  };

  const onDelete = async (name: string) => {
    const ok = await confirm({
      title: t('cloud.delete_confirm_title'),
      message: t('cloud.delete_confirm_message'),
      confirmLabel: t('common.delete'),
      cancelLabel: t('common.cancel'),
      destructive: true,
    });
    if (!ok) return;
    del.mutate(name, {
      onSuccess: () => { successToast(t('cloud.delete_success_title')); },
    });
  };

  const onCreate = () => {
    create.mutate(undefined, {
      onSuccess: () => {
        successToast(t('cloud.backup_success_title'), t('cloud.backup_success_message'));
      },
    });
  };

  const onExport = () => {
    exportData.mutate(undefined, {
      onSuccess: () => {
        successToast(t('cloud.export_data.cta'));
      },
    });
  };

  const handleDeleteConfirmed = () => {
    setDeleteDialogOpen(false);
    deleteAccount.mutate(undefined, {
      onSuccess: () => {
        successToast(t('cloud.delete_account.success_toast'));
        router.replace('/onboarding/welcome' as never);
      },
    });
  };

  const lastBackupIso = backups[0]?.createdAt;
  const lastBackupRelative = lastBackupIso
    ? formatDistanceToNow(parseISO(lastBackupIso), { locale: fr, addSuffix: true })
    : null;

  return (
    <Surface className="flex-1">
      <ScreenHeader title={t('cloud.screen_title')} />
      <ConfirmTypedDialog
        visible={restoreDialogName != null}
        title={t('cloud.restore_confirm_title')}
        message={t('cloud.restore_confirm_message')}
        typedConfirmation={t('cloud.restore_typed_word')}
        confirmLabel={t('cloud.restore_cta')}
        cancelLabel={t('common.cancel')}
        onConfirm={handleRestoreConfirmed}
        onCancel={() => setRestoreDialogName(null)}
      />
      <ConfirmTypedDialog
        visible={deleteDialogOpen}
        title={t('cloud.delete_account.confirm_title')}
        message={t('cloud.delete_account.confirm_message')}
        typedConfirmation={t('cloud.delete_account.typed_word')}
        confirmLabel={t('cloud.delete_account.cta_confirm')}
        cancelLabel={t('common.cancel')}
        onConfirm={handleDeleteConfirmed}
        onCancel={() => setDeleteDialogOpen(false)}
      />
      <ScrollView contentContainerStyle={{ paddingHorizontal: 16, paddingTop: 12, paddingBottom: 32, gap: 12 }}>
        <Surface variant="muted" className="rounded-2xl px-4 py-3 gap-1">
          <Text variant="muted" className="text-xs">
            {t('cloud.logged_in_as', { email: session.user.email ?? '' })}
          </Text>
          <Text className="text-sm">
            {lastBackupRelative
              ? t('cloud.last_backup_label', { when: lastBackupRelative })
              : t('cloud.last_backup_never')}
          </Text>
          <Text variant="muted" className="text-xs mt-1">
            {t('cloud.auto_backup_intro')}
          </Text>
        </Surface>

        <Button
          onPress={onCreate}
          loading={create.isPending}
          accessibilityLabel={t('cloud.create_backup_cta')}
        >
          <CloudUpload size={18} color={onContrast} />
          <Text variant="onPrimary" className="font-semibold">
            {create.isPending ? t('cloud.creating_backup') : t('cloud.create_backup_cta')}
          </Text>
        </Button>

        {isError ? (
          <ErrorState onRetry={() => refetch()} />
        ) : isLoading ? (
          <ListSkeleton rows={3} />
        ) : backups.length === 0 ? (
          <View className="py-8">
            <EmptyState title={t('cloud.no_backups_title')} message={t('cloud.no_backups_message')} />
          </View>
        ) : (
          backups.map((b) => (
            <Surface key={b.name} variant="muted" className="rounded-2xl px-4 py-3 gap-2">
              <Text className="font-semibold">
                {b.createdAt ? format(parseISO(b.createdAt), 'PPPp', { locale: fr }) : b.name}
              </Text>
              <View className="flex-row gap-2">
                <Button
                  size="sm"
                  variant="secondary"
                  className="flex-1"
                  onPress={() => onRestore(b.name)}
                  loading={restore.isPending}
                  accessibilityLabel={t('cloud.restore_cta')}
                >
                  <RefreshCw size={14} color={fg} />
                  <Text className="font-semibold">{t('cloud.restore_cta')}</Text>
                </Button>
                <Button
                  size="sm"
                  variant="danger"
                  onPress={() => onDelete(b.name)}
                  loading={del.isPending}
                  accessibilityLabel={t('common.delete')}
                >
                  <Trash2 size={14} color={onContrast} />
                </Button>
              </View>
            </Surface>
          ))
        )}

        <Button
          variant="secondary"
          onPress={onExport}
          loading={exportData.isPending}
          accessibilityLabel={t('cloud.export_data.cta')}
          className="mt-4"
        >
          <Download size={16} color={fg} />
          <Text className="font-semibold">{t('cloud.export_data.cta')}</Text>
        </Button>

        <Button
          variant="secondary"
          onPress={async () => {
            const ok = await confirm({
              title: t('cloud.sign_out_confirm_title'),
              message: t('cloud.sign_out_confirm_message'),
              confirmLabel: t('cloud.sign_out_confirm_cta'),
              cancelLabel: t('common.cancel'),
              destructive: true,
            });
            if (ok) signOut.mutate();
          }}
          loading={signOut.isPending}
          className="mt-2"
        >
          {t('cloud.sign_out_cta')}
        </Button>

        <View className="mt-8">
          <SectionHeader title={t('cloud.danger_section_title')} />
          <Button
            variant="danger"
            onPress={() => setDeleteDialogOpen(true)}
            loading={deleteAccount.isPending}
            accessibilityLabel={t('cloud.delete_account.cta')}
          >
            <AlertTriangle size={16} color={onContrast} />
            <Text variant="onPrimary" className="font-semibold">
              {t('cloud.delete_account.cta')}
            </Text>
          </Button>
        </View>
      </ScrollView>
    </Surface>
  );
}
