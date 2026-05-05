import { Linking, Pressable, View, ScrollView } from 'react-native';
import { useLocalSearchParams, useRouter } from 'expo-router';
import { MessageSquare, Pencil, Phone, Trash2 } from 'lucide-react-native';
import { useTranslation } from 'react-i18next';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { Button } from '@/ui/primitives/button';
import { ErrorState } from '@/ui/components/error-state';
import { ScreenHeader } from '@/ui/components/screen-header';
import { confirm } from '@/ui/components/confirm-dialog';
import { ClientKpiRow } from '@/ui/components/client-kpi-row';
import { ClientStatusBadge } from '@/ui/components/client-status-badge';
import { PlannedTourCard } from '@/ui/components/planned-tour-card';
import { ClientAnimalsSection } from '@/ui/components/client-animals-section';
import { ClientStatusActionsCard } from '@/ui/components/client-status-actions-card';
import { LastInterventionsList } from '@/ui/components/last-interventions-list';
import { useClient, useDeleteClient } from '@/state/queries/clients';
import { formatPhone } from '@/lib/phone-formatter';
import { haptics } from '@/ui/motion/haptics';
import { mutationErrorToast } from '@/ui/components/error-toast';
import { useOnContrastColor, useForegroundColor } from '@/ui/theme/colors';

export default function ClientDetailScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const router = useRouter();
  const { t } = useTranslation();
  const onContrast = useOnContrastColor();
  const fg = useForegroundColor();
  const { data: client, isError, refetch } = useClient(id);
  const deleteMutation = useDeleteClient();

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
        mutationErrorToast(t('clients.delete_failed_title'), err);
      },
    });
  };

  return (
    <Surface className="flex-1">
      <ScreenHeader
        title={t('clients.detail_title')}
        rightSlot={
          <View className="flex-row gap-2">
            <Button
              size="sm"
              variant="ghost"
              onPress={() => router.push(`/(tabs)/clients/${client.id}/edit`)}
              accessibilityLabel={t('common.edit')}
            >
              <Pencil size={16} color={fg} />
            </Button>
            <Button size="sm" variant="danger" onPress={onDelete} accessibilityLabel={t('clients.delete')}>
              <Trash2 size={16} color={onContrast} />
            </Button>
          </View>
        }
      />
      <ScrollView contentContainerStyle={{ paddingHorizontal: 16, paddingTop: 8, paddingBottom: 32, gap: 16 }}>
        {/* Header */}
        <Text className="text-2xl font-bold">{client.displayName}</Text>

        {/* Status badge */}
        <ClientStatusBadge clientId={client.id} />

        {/* KPI row */}
        <ClientKpiRow clientId={client.id} />

        {/* Planned tour card */}
        <PlannedTourCard clientId={client.id} />

        {/* Animals section */}
        <ClientAnimalsSection client={client} />

        {/* Status actions */}
        <ClientStatusActionsCard client={client} />

        {/* Last interventions */}
        <LastInterventionsList clientId={client.id} />

        {/* Address + phones */}
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
              <View key={i} className="flex-row items-center justify-between py-1">
                <Text>{formatPhone(p)}</Text>
                <View className="flex-row gap-2">
                  <Pressable
                    onPress={() => void Linking.openURL(`tel:${p.replace(/\s/g, '')}`)}
                    accessibilityLabel={t('clients.call_phone')}
                    className="p-2"
                  >
                    <Phone size={18} color="#5C4E40" />
                  </Pressable>
                  <Pressable
                    onPress={() => void Linking.openURL(`sms:${p.replace(/\s/g, '')}`)}
                    accessibilityLabel={t('clients.send_sms')}
                    className="p-2"
                  >
                    <MessageSquare size={18} color="#5C4E40" />
                  </Pressable>
                </View>
              </View>
            ))}
          </View>
        ) : null}

        {/* Actions */}
        <Button
          variant="secondary"
          onPress={() => router.push(`/(tabs)/clients/${client.id}/edit`)}
        >
          {t('common.edit')}
        </Button>
      </ScrollView>
    </Surface>
  );
}
