import { View } from 'react-native';
import { useTranslation } from 'react-i18next';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { useTourKpis } from '@/state/queries/kpis';
import { formatMinutes } from '@/lib/format-minutes';

function formatEur(cents: number): string {
  return `${(cents / 100).toFixed(0)} €`;
}

interface Tile {
  label: string;
  value: string;
}

function KpiTile({ label, value }: Tile) {
  return (
    <Surface variant="muted" className="flex-1 rounded-2xl p-3 gap-1">
      <Text variant="muted" className="text-xs">{label}</Text>
      <Text className="text-xl font-bold">{value}</Text>
    </Surface>
  );
}

interface Props {
  tourId: string;
}

export function TourKpiRow({ tourId }: Props) {
  const { t } = useTranslation();
  const { data: kpis } = useTourKpis(tourId);

  if (!kpis) return null;

  return (
    <View className="gap-2">
      <View className="flex-row gap-2">
        <KpiTile label={t('tours.kpi_stops')} value={String(kpis.stopCount)} />
        <KpiTile label={t('tours.kpi_animals_title')} value={String(kpis.animalsTotal)} />
        <KpiTile label={t('tours.kpi_duration')} value={formatMinutes(kpis.durationMinutes)} />
      </View>
      <View className="flex-row gap-2">
        <KpiTile label={t('tours.kpi_revenue')} value={formatEur(kpis.revenueCents)} />
        <KpiTile label={t('tours.kpi_travel_fees')} value={formatEur(kpis.travelFeeCents)} />
      </View>
    </View>
  );
}
