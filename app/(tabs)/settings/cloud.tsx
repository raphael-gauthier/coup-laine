import { View, ScrollView } from 'react-native';
import { Stack, useRouter } from 'expo-router';
import { useTranslation } from 'react-i18next';
import { format, parseISO } from 'date-fns';
import { fr } from 'date-fns/locale';
import { CloudUpload, RefreshCw, Trash2 } from 'lucide-react-native';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { Button } from '@/ui/primitives/button';
import { ErrorState } from '@/ui/components/error-state';
import { EmptyState } from '@/ui/components/empty-state';
import { confirm } from '@/ui/components/confirm-dialog';
import { useSession, useSignOut } from '@/state/queries/auth';
import { useBackups, useCreateBackup, useRestoreBackup, useDeleteBackup } from '@/state/queries/backups';
import { haptics } from '@/ui/motion/haptics';

export default function CloudScreen() {
  const { t } = useTranslation();
  const router = useRouter();
  const { data: session } = useSession();
  const signOut = useSignOut();
  const create = useCreateBackup();
  const restore = useRestoreBackup();
  const del = useDeleteBackup();
  const { data: backups = [], isError, isLoading, refetch } = useBackups();

  if (!session) {
    return (
      <Surface className="flex-1">
        <Stack.Screen options={{ title: t('cloud.screen_title') }} />
        <View className="flex-1 px-6 items-center justify-center gap-6">
          <Text className="text-center" variant="muted">{t('cloud.row_hint_logged_out')}</Text>
          <Button onPress={() => router.push('/auth/login' as never)}>
            {t('cloud.sign_in_cta')}
          </Button>
        </View>
      </Surface>
    );
  }

  const onRestore = async (name: string) => {
    const ok = await confirm({
      title: t('cloud.restore_confirm_title'),
      message: t('cloud.restore_confirm_message'),
      confirmLabel: t('cloud.restore_cta'),
      cancelLabel: t('common.cancel'),
      destructive: true,
    });
    if (!ok) return;
    restore.mutate(name, {
      onSuccess: () => { void haptics.success(); },
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
      onSuccess: () => { void haptics.success(); },
    });
  };

  return (
    <Surface className="flex-1">
      <Stack.Screen options={{ title: t('cloud.screen_title') }} />
      <ScrollView contentContainerStyle={{ paddingHorizontal: 16, paddingTop: 12, paddingBottom: 24, gap: 12 }}>
        <Surface variant="muted" className="rounded-2xl px-4 py-3">
          <Text variant="muted" className="text-xs">
            {t('cloud.logged_in_as', { email: session.user.email ?? '' })}
          </Text>
        </Surface>

        <Button onPress={() => create.mutate()} loading={create.isPending}>
          <CloudUpload size={18} color="white" />
          <Text variant="onPrimary" className="font-semibold">
            {create.isPending ? t('cloud.creating_backup') : t('cloud.create_backup_cta')}
          </Text>
        </Button>

        {isError ? (
          <ErrorState onRetry={() => refetch()} />
        ) : isLoading ? null : backups.length === 0 ? (
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
                >
                  <RefreshCw size={14} />
                  <Text className="font-semibold">{t('cloud.restore_cta')}</Text>
                </Button>
                <Button
                  size="sm"
                  variant="danger"
                  onPress={() => onDelete(b.name)}
                  loading={del.isPending}
                >
                  <Trash2 size={14} color="white" />
                </Button>
              </View>
            </Surface>
          ))
        )}

        <Button variant="secondary" onPress={() => signOut.mutate()} loading={signOut.isPending} className="mt-4">
          {t('cloud.sign_out_cta')}
        </Button>
      </ScrollView>
    </Surface>
  );
}
