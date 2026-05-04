import { View } from 'react-native';
import { useTranslation } from 'react-i18next';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { useTourKpis } from '@/state/queries/kpis';

function formatEur(cents: number): string {
  return `${(cents / 100).toFixed(0)} €`;
}

interface Props {
  tourId: string;
}

export function ServiceAggregationSummary({ tourId }: Props) {
  const { t } = useTranslation();
  const { data: kpis } = useTourKpis(tourId);

  if (!kpis || kpis.serviceAggregates.length === 0) return null;

  const total = kpis.serviceAggregates.reduce((s, a) => s + a.totalRevenueCents, 0);

  return (
    <Surface variant="muted" className="rounded-2xl px-4 py-3 gap-2">
      <Text className="font-semibold">{t('tours.services_label')}</Text>
      {kpis.serviceAggregates.map((agg) => (
        <View key={agg.serviceId} className="flex-row items-center justify-between">
          <Text className="text-sm flex-1">{agg.name} ×{agg.totalQty}</Text>
          <Text className="text-sm font-semibold">{formatEur(agg.totalRevenueCents)}</Text>
        </View>
      ))}
      <View className="flex-row items-center justify-between border-t border-border dark:border-border-dark pt-2">
        <Text className="font-semibold">{t('tours.kpi_total')}</Text>
        <Text className="font-bold">{formatEur(total)}</Text>
      </View>
    </Surface>
  );
}
