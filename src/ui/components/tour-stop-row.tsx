import { View } from 'react-native';
import { useTranslation } from 'react-i18next';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import type { TourStop } from '@/domain/models/tour-stop';
import type { Client } from '@/domain/models/client';

function formatEur(cents: number): string {
  return `${(cents / 100).toFixed(0)} €`;
}

function minutesToTime(minutes: number | null, base: string): string {
  if (minutes == null) return '—';
  const [bh, bm] = base.split(':').map(Number);
  const total = (bh ?? 0) * 60 + (bm ?? 0) + minutes;
  const h = Math.floor(total / 60) % 24;
  const m = total % 60;
  return `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}`;
}

interface Props {
  stop: TourStop;
  client: Client | undefined;
  departureTime: string;
}

export function TourStopRow({ stop, client, departureTime }: Props) {
  const { t } = useTranslation();
  const prestations = stop.actualPrestations ?? stop.plannedPrestations;
  const revenueCents = prestations.reduce((s, p) => s + p.qty * p.priceCentsSnapshot, 0);
  const prestSummary = prestations.length > 0
    ? prestations.map((p) => `${p.nameSnapshot} ×${p.qty}`).join(', ') + ` → ${formatEur(revenueCents)}`
    : null;

  const arrivalStr = minutesToTime(stop.arrivalMinutes, departureTime);
  const departureStr = minutesToTime(stop.departureMinutes, departureTime);

  const displayName = stop.clientNameSnapshot ?? client?.displayName ?? stop.clientId;

  return (
    <Surface variant="muted" className="rounded-2xl px-4 py-3 gap-1">
      <View className="flex-row items-center justify-between">
        <Text className="font-semibold flex-1">{displayName}</Text>
        <Text variant="muted" className="text-xs font-mono">
          {arrivalStr !== '—' ? `${arrivalStr} → ${departureStr}` : '—'}
        </Text>
      </View>
      {prestSummary ? (
        <Text variant="muted" className="text-xs">{prestSummary}</Text>
      ) : null}
      {stop.notes ? (
        <Text variant="muted" className="text-xs">🗒 {stop.notes}</Text>
      ) : null}
    </Surface>
  );
}
