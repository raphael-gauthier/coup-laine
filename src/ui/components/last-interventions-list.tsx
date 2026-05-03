import { View } from 'react-native';
import { useRouter } from 'expo-router';
import { useTranslation } from 'react-i18next';
import { format, parseISO } from 'date-fns';
import { fr } from 'date-fns/locale';
import { ChevronRight } from 'lucide-react-native';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { Button } from '@/ui/primitives/button';
import { PressScale } from '@/ui/motion/press-scale';
import { useClientHistory } from '@/state/queries/history';
import { haptics } from '@/ui/motion/haptics';

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

  if (last3.length === 0) return null;

  return (
    <Surface variant="muted" className="rounded-2xl px-4 py-3 gap-2">
      <Text className="font-semibold">{t('clients.last_interventions_title')}</Text>

      {last3.map((item) => {
        const key = item.tourStopId ?? item.manualEntryId ?? item.date;
        const date = format(parseISO(item.date), 'dd/MM/yyyy', { locale: fr });
        const revenueCents = item.prestations.reduce((s, p) => s + p.qty * p.priceCentsSnapshot, 0);
        const prestSummary = item.prestations.length > 0
          ? item.prestations.map((p) => `${p.nameSnapshot} ×${p.qty}`).join(', ') + ` → ${formatEur(revenueCents)}`
          : t('clients.no_prestations');
        return (
          <View key={key} className="gap-0.5">
            <Text className="text-sm font-medium">{date}</Text>
            <Text variant="muted" className="text-xs">{prestSummary}</Text>
          </View>
        );
      })}

      {history.length > 3 ? (
        <PressScale
          onPress={() => {
            void haptics.selection();
            router.push(`/(tabs)/clients/${clientId}/history` as never);
          }}
        >
          <View className="flex-row items-center gap-1 pt-1">
            <Text variant="primary" className="text-sm">{t('clients.view_full_history')}</Text>
            <ChevronRight size={14} color="#A1602F" />
          </View>
        </PressScale>
      ) : null}
    </Surface>
  );
}
