import { View, ScrollView } from 'react-native';
import { Stack, useLocalSearchParams, useRouter } from 'expo-router';
import { History, Pencil, Trash2 } from 'lucide-react-native';
import { useTranslation } from 'react-i18next';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { Button } from '@/ui/primitives/button';
import { ErrorState } from '@/ui/components/error-state';
import { confirm } from '@/ui/components/confirm-dialog';
import { useClient, useDeleteClient, useToggleWaiting } from '@/state/queries/clients';
import { formatPhone } from '@/lib/phone-formatter';
import { haptics } from '@/ui/motion/haptics';
import { errorToast } from '@/ui/components/error-toast';

export default function ClientDetailScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const router = useRouter();
  const { t } = useTranslation();
  const { data: client, isError, refetch } = useClient(id);
  const deleteMutation = useDeleteClient();
  const toggleWaiting = useToggleWaiting();

  if (isError) return <ErrorState onRetry={() => refetch()} />;
  if (!client) return <Surface className="flex-1" />;

  const onDelete = async () => {
    const ok = await confirm({
      title: t('clients.delete_confirm_title'),
      message: t('clients.delete_confirm_message'),
      confirmLabel: t('clients.delete'),
      cancelLabel: t('common.cancel'),
      destructive: true,
    });
    if (!ok) return;
    deleteMutation.mutate(client.id, {
      onSuccess: () => {
        void haptics.success();
        router.back();
      },
      onError: (err) => {
        errorToast(t('clients.delete_failed_title'), err instanceof Error ? err.message : undefined);
      },
    });
  };

  return (
    <Surface className="flex-1">
      <Stack.Screen
        options={{
          title: t('clients.detail_title'),
          headerRight: () => (
            <View className="flex-row gap-2">
              <Button
                size="sm"
                variant="ghost"
                onPress={() => router.push(`/(tabs)/clients/${client.id}/edit`)}
                accessibilityLabel={t('common.edit')}
              >
                <Pencil size={16} />
              </Button>
              <Button size="sm" variant="danger" onPress={onDelete} accessibilityLabel={t('clients.delete')}>
                <Trash2 size={16} color="white" />
              </Button>
            </View>
          ),
        }}
      />
      <ScrollView contentContainerStyle={{ paddingHorizontal: 16, paddingTop: 16, paddingBottom: 32, gap: 16 }}>
        <Text className="text-2xl font-bold">{client.displayName}</Text>

        <Button
          variant={client.isWaiting ? 'primary' : 'secondary'}
          onPress={() => toggleWaiting.mutate({ id: client.id, isWaiting: !client.isWaiting })}
        >
          {client.isWaiting ? t('clients.unmark_waiting') : t('clients.mark_waiting')}
        </Button>

        <Button
          variant="secondary"
          onPress={() => router.push(`/(tabs)/clients/${client.id}/history` as never)}
        >
          <History size={16} />
          <Text className="font-semibold">{t('history.view_history')}</Text>
        </Button>

        {client.addressLabel ? (
          <View className="gap-1">
            <Text variant="muted" className="text-sm">{t('clients.address')}</Text>
            <Text>{client.addressLabel}</Text>
          </View>
        ) : null}

        {client.phones.length > 0 ? (
          <View className="gap-1">
            <Text variant="muted" className="text-sm">{t('clients.phones')}</Text>
            {client.phones.map((p, i) => (
              <Text key={i}>{formatPhone(p)}</Text>
            ))}
          </View>
        ) : null}

      </ScrollView>
    </Surface>
  );
}
