import { View } from 'react-native';
import { useTranslation } from 'react-i18next';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { PressScale } from '@/ui/motion/press-scale';
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
  onPress?: () => void;
  showPaymentBadge?: boolean;
  /** Used when the stop hasn't persisted arrival/departure yet (planned tours). */
  fallbackArrivalTime?: string;
  fallbackDepartureTime?: string;
}

export function TourStopRow({ stop, client, departureTime, onPress, showPaymentBadge, fallbackArrivalTime, fallbackDepartureTime }: Props) {
  const { t } = useTranslation();
  const services = stop.actualServices ?? stop.plannedServices;
  const revenueCents = services.reduce((s, p) => s + p.qty * p.priceCentsSnapshot, 0);
  const prestSummary = services.length > 0
    ? services.map((p) => `${p.nameSnapshot} ×${p.qty}`).join(', ') + ` → ${formatEur(revenueCents)}`
    : null;

  const arrivalStr = stop.arrivalMinutes != null
    ? minutesToTime(stop.arrivalMinutes, departureTime)
    : fallbackArrivalTime ?? '—';
  const departureStr = stop.departureMinutes != null
    ? minutesToTime(stop.departureMinutes, departureTime)
    : fallbackDepartureTime ?? '—';

  const displayName = stop.clientNameSnapshot ?? client?.displayName ?? stop.clientId;

  const content = (
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
      {stop.travelFeeCents !== null ? (
        <Text variant="muted" className="text-xs">
          {t('common.travel_fee_inline', { amount: formatEur(stop.travelFeeCents) })}
        </Text>
      ) : null}
      {showPaymentBadge ? (
        <Text variant="muted" className="text-xs">
          {stop.payment.isPaid
            ? stop.payment.methodLabelSnapshot
              ? t('payments.paid_badge', { method: stop.payment.methodLabelSnapshot })
              : t('payments.paid_badge_unknown')
            : t('payments.unpaid_badge')}
        </Text>
      ) : null}
      {stop.notes ? (
        <Text variant="muted" className="text-xs">🗒 {stop.notes}</Text>
      ) : null}
    </Surface>
  );

  if (onPress) {
    return (
      <PressScale onPress={onPress} accessibilityLabel={displayName}>
        {content}
      </PressScale>
    );
  }

  return content;
}
