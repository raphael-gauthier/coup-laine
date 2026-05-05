import { View } from 'react-native';
import { Trash2, Plus } from 'lucide-react-native';
import { useTranslation } from 'react-i18next';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { Button } from '@/ui/primitives/button';
import { Input } from '@/ui/primitives/input';
import { PressScale } from '@/ui/motion/press-scale';
import type { TourStop } from '@/domain/models/tour-stop';
import type { TourStopService } from '@/domain/models/tour-stop-service';
import type { Client } from '@/domain/models/client';
import type { Payment } from '@/domain/models/payment';
import { PaymentEditor } from '@/ui/components/payment-editor';

interface Props {
  stop: TourStop;
  client: Client | undefined;
  actuals: TourStopService[];
  note: string;
  onChangeActuals: (next: TourStopService[]) => void;
  onChangeNote: (next: string) => void;
  onAddOffPlan: () => void;
  payment: Payment;
  paymentError?: string | null;
  onChangePayment: (next: Payment) => void;
}

export function StopCompletionEditor({
  stop,
  client,
  actuals,
  note,
  onChangeActuals,
  onChangeNote,
  onAddOffPlan,
  payment,
  paymentError,
  onChangePayment,
}: Props) {
  const { t } = useTranslation();
  const displayName = stop.clientNameSnapshot ?? client?.displayName ?? stop.clientId;

  const setQty = (idx: number, raw: string) => {
    const q = parseInt(raw, 10);
    if (isNaN(q) || q < 0) return;
    const next = actuals.map((p, i) => i === idx ? { ...p, qty: q } : p);
    onChangeActuals(next);
  };

  const remove = (idx: number) => {
    onChangeActuals(actuals.filter((_, i) => i !== idx));
  };

  const matchPlanned = () => {
    onChangeActuals([...stop.plannedServices]);
  };

  const different = JSON.stringify(actuals) !== JSON.stringify(stop.plannedServices);

  return (
    <Surface variant="muted" className="rounded-2xl px-4 py-3 gap-3">
      <View className="flex-row items-center justify-between">
        <Text className="font-semibold">{displayName}</Text>
        {different ? (
          <Text variant="muted" className="text-xs text-danger dark:text-danger-dark">
            {t('tours.bilan_differs')}
          </Text>
        ) : null}
      </View>

      {/* Planned preview */}
      <View className="gap-1">
        <Text variant="muted" className="text-xs">{t('tours.bilan_planned')}</Text>
        {stop.plannedServices.length > 0 ? (
          stop.plannedServices.map((p, i) => (
            <Text key={i} variant="muted" className="text-xs">
              {p.nameSnapshot} ×{p.qty}
            </Text>
          ))
        ) : (
          <Text variant="muted" className="text-xs">{t('tours.bilan_no_planned')}</Text>
        )}
      </View>

      {/* Actual editable */}
      <View className="gap-2">
        <View className="flex-row items-center justify-between">
          <Text variant="muted" className="text-xs">{t('tours.bilan_actual')}</Text>
          <Button size="sm" variant="secondary" onPress={matchPlanned}>
            {t('tours.bilan_match_planned')}
          </Button>
        </View>
        {actuals.map((p, i) => (
          <View key={i} className="flex-row items-center gap-2">
            <Text className="flex-1 text-sm">{p.nameSnapshot}</Text>
            <Input
              value={String(p.qty)}
              onChangeText={(v) => setQty(i, v)}
              keyboardType="number-pad"
              style={{ width: 56, textAlign: 'center' }}
              accessibilityLabel={t('tours.picker_qty')}
            />
            <PressScale onPress={() => remove(i)} accessibilityLabel={t('common.remove')}>
              <Trash2 size={16} color="#B23832" />
            </PressScale>
          </View>
        ))}
        {actuals.length === 0 ? (
          <Text variant="muted" className="text-xs">{t('tours.bilan_no_show')}</Text>
        ) : null}

        <Button
          size="sm"
          variant="secondary"
          onPress={onAddOffPlan}
          accessibilityLabel={t('tours.bilan_add_off_plan')}
        >
          <Plus size={14} color="#5C4E40" />
          <Text className="text-sm font-medium">{t('tours.bilan_add_off_plan')}</Text>
        </Button>
      </View>

      <View className="gap-1">
        <Text variant="muted" className="text-xs">{t('tours.bilan_note_hint')}</Text>
        <Input
          value={note}
          onChangeText={onChangeNote}
          multiline
          numberOfLines={3}
          style={{ minHeight: 72, textAlignVertical: 'top' }}
          accessibilityLabel={t('tours.bilan_note_hint')}
        />
      </View>

      <PaymentEditor value={payment} onChange={onChangePayment} methodError={paymentError ?? null} />
    </Surface>
  );
}
