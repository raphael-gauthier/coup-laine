import { View } from 'react-native';
import { useTranslation } from 'react-i18next';
import { format, parseISO } from 'date-fns';
import { fr } from 'date-fns/locale';
import { ChevronRight } from 'lucide-react-native';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { PressScale } from '@/ui/motion/press-scale';
import type { TourStop } from '@/domain/models/tour-stop';
import type { ManualHistoryEntry } from '@/domain/models/manual-history-entry';
import { useMutedForegroundColor } from '@/ui/theme/colors';

interface UnpaidStop {
  stop: TourStop;
  tourId: string;
  scheduledDate: string;
}

interface Props {
  unpaidStops: UnpaidStop[];
  unpaidEntries: ManualHistoryEntry[];
  totalCents: number;
  count: number;
  onTapStop: (s: UnpaidStop) => void;
  onTapEntry: (e: ManualHistoryEntry) => void;
}

function formatEur(cents: number): string { return `${(cents / 100).toFixed(0)} €`; }
function sumServices(s: { qty: number; priceCentsSnapshot: number }[]): number {
  return s.reduce((acc, x) => acc + (x.qty > 0 ? x.qty * x.priceCentsSnapshot : 0), 0);
}

export function ClientOutstandingCard({
  unpaidStops, unpaidEntries, totalCents, count, onTapStop, onTapEntry,
}: Props) {
  const { t } = useTranslation();
  const mutedFg = useMutedForegroundColor();
  const summary = t('payments.outstanding_summary', { count });

  return (
    <Surface variant="muted" className="rounded-2xl p-3 gap-2">
      <View className="flex-row items-end justify-between">
        <Text className="font-semibold">{t('payments.outstanding_title')}</Text>
        <Text className="text-xl font-bold">{formatEur(totalCents)}</Text>
      </View>
      <Text variant="muted" className="text-xs">{summary}</Text>

      <View className="gap-1 mt-2">
        {unpaidStops.map((s) => {
          const services = s.stop.actualServices ?? s.stop.plannedServices;
          const cents = sumServices(services);
          return (
            <PressScale key={s.stop.id} onPress={() => onTapStop(s)} accessibilityLabel={t('payments.editor_title')}>
              <View className="flex-row items-center justify-between py-2 border-t border-border dark:border-border-dark">
                <Text className="flex-1 text-sm">{format(parseISO(s.scheduledDate), 'PPP', { locale: fr })}</Text>
                <Text className="text-sm font-medium mr-2">{formatEur(cents)}</Text>
                <ChevronRight size={16} color={mutedFg} />
              </View>
            </PressScale>
          );
        })}
        {unpaidEntries.map((e) => {
          const cents = sumServices(e.services);
          return (
            <PressScale key={e.id} onPress={() => onTapEntry(e)} accessibilityLabel={t('payments.editor_title')}>
              <View className="flex-row items-center justify-between py-2 border-t border-border dark:border-border-dark">
                <Text className="flex-1 text-sm">{format(parseISO(e.date), 'PPP', { locale: fr })}</Text>
                <Text className="text-sm font-medium mr-2">{formatEur(cents)}</Text>
                <ChevronRight size={16} color={mutedFg} />
              </View>
            </PressScale>
          );
        })}
      </View>
    </Surface>
  );
}
