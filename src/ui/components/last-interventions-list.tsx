import { View } from 'react-native';
import { useRouter } from 'expo-router';
import { useTranslation } from 'react-i18next';
import { format, parseISO } from 'date-fns';
import { fr } from 'date-fns/locale';
import { ChevronRight, Plus } from 'lucide-react-native';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { PressScale } from '@/ui/motion/press-scale';
import { useClientHistory } from '@/state/queries/history';
import { haptics } from '@/ui/motion/haptics';
import type { Intervention } from '@/domain/models/intervention';

interface Props {
  clientId: string;
}

function formatEur(cents: number): string {
  return `${(cents / 100).toFixed(0)} €`;
}

export function LastInterventionsList({ clientId }: Props) {
  const { t } = useTranslation();
  const router = useRouter();
  const { data: history = [] } = useClientHistory(clientId);

  const last3 = history.slice(0, 3);

  const goToItem = (item: Intervention) => {
    void haptics.selection();
    if (item.source === 'tour' && item.tourId) {
      router.push(`/(tabs)/tours/${item.tourId}` as never);
    } else if (item.source === 'manual' && item.manualEntryId) {
      router.push(`/(tabs)/clients/${clientId}/history/${item.manualEntryId}` as never);
    }
  };

  const onAddIntervention = () => {
    void haptics.selection();
    router.push(`/(tabs)/clients/${clientId}/history/new` as never);
  };

  return (
    <Surface variant="muted" className="rounded-2xl px-4 py-3 gap-2">
      <Text className="font-semibold">{t('clients.last_interventions_title')}</Text>

      {last3.map((item) => {
        const key = item.tourStopId ?? item.manualEntryId ?? item.date;
        const date = format(parseISO(item.date), 'dd/MM/yyyy', { locale: fr });
        const revenueCents = item.services.reduce((s, p) => s + p.qty * p.priceCentsSnapshot, 0);
        const prestSummary =
          item.services.length > 0
            ? item.services.map((p) => `${p.nameSnapshot} ×${p.qty}`).join(', ') +
              ` → ${formatEur(revenueCents)}`
            : t('clients.no_services');
        return (
          <PressScale key={key} onPress={() => goToItem(item)} accessibilityLabel={date}>
            <View className="flex-row items-center gap-2 py-1">
              <View className="flex-1 gap-0.5">
                <Text className="text-sm font-medium">{date}</Text>
                <Text variant="muted" className="text-xs">
                  {prestSummary}
                </Text>
                <Text variant="muted" className="text-xs">
                  {t('common.travel_fee_inline', { amount: formatEur(item.travelFeeCents ?? 0) })}
                </Text>
              </View>
              <ChevronRight size={14} color="#5C4E40" />
            </View>
          </PressScale>
        );
      })}

      {history.length > 3 ? (
        <PressScale
          onPress={() => {
            void haptics.selection();
            router.push(`/(tabs)/clients/${clientId}/history` as never);
          }}
          accessibilityLabel={t('clients.view_full_history')}
        >
          <View className="flex-row items-center gap-1 pt-1">
            <Text variant="primary" className="text-sm">
              {t('clients.view_full_history')}
            </Text>
            <ChevronRight size={14} color="#A1602F" />
          </View>
        </PressScale>
      ) : null}

      <PressScale onPress={onAddIntervention} accessibilityLabel={t('clients.add_intervention_cta')}>
        <View className="flex-row items-center gap-2 pt-1">
          <Plus size={16} color="#A1602F" />
          <Text variant="primary" className="text-sm font-medium">
            {t('clients.add_intervention_cta')}
          </Text>
        </View>
      </PressScale>
    </Surface>
  );
}
