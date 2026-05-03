import { View } from 'react-native';
import { useTranslation } from 'react-i18next';
import { format, parseISO } from 'date-fns';
import { fr } from 'date-fns/locale';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { useClientKpis } from '@/state/queries/kpis';

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
  clientId: string;
}

export function ClientKpiRow({ clientId }: Props) {
  const { t } = useTranslation();
  const { data: kpis } = useClientKpis(clientId);

  if (!kpis) return null;

  const lastVisit = kpis.lastInterventionDate
    ? format(parseISO(kpis.lastInterventionDate), 'dd/MM/yyyy', { locale: fr })
    : '—';

  return (
    <View className="flex-row gap-2">
      <KpiTile label={t('clients.kpi_interventions')} value={String(kpis.interventionsCount)} />
      <KpiTile label={t('clients.kpi_revenue')} value={formatEur(kpis.totalRevenueCents)} />
      <KpiTile label={t('clients.kpi_last_visit')} value={lastVisit} />
      <KpiTile label={t('clients.kpi_seasons')} value={String(kpis.yearsSinceFirst)} />
    </View>
  );
}
