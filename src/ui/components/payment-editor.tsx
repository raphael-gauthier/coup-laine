import { useState } from 'react';
import { View } from 'react-native';
import { useTranslation } from 'react-i18next';
import { parseISO } from 'date-fns';
import { ChevronDown } from 'lucide-react-native';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { PressScale } from '@/ui/motion/press-scale';
import { ThemedSwitch } from '@/ui/primitives/themed-switch';
import { PaymentMethodPicker } from '@/ui/components/payment-method-picker';
import { DateField } from '@/ui/components/date-field';
import type { Payment } from '@/domain/models/payment';
import type { PaymentMethod } from '@/domain/models/payment-method';

interface Props {
  value: Payment;
  onChange: (next: Payment) => void;
  methodError?: string | null;
  // When true, the form requires a methodId regardless of isPaid (manual history).
  requireMethodAlways?: boolean;
  /** Bubbles paid-at field validity so a host can disable its Save button. */
  onPaidAtValidityChange?: (valid: boolean) => void;
}

export function PaymentEditor({ value, onChange, methodError, requireMethodAlways, onPaidAtValidityChange }: Props) {
  const { t } = useTranslation();
  const [pickerOpen, setPickerOpen] = useState(false);

  const onPickMethod = (m: PaymentMethod) => {
    onChange({
      ...value,
      methodId: m.id,
      methodLabelSnapshot: value.isPaid ? m.label : value.methodLabelSnapshot,
    });
    setPickerOpen(false);
  };

  const onTogglePaid = (next: boolean) => {
    if (next) {
      onChange({
        ...value,
        isPaid: true,
        paidAt: value.paidAt ?? new Date().toISOString(),
        methodLabelSnapshot: value.methodLabelSnapshot,
      });
    } else {
      onChange({
        ...value,
        isPaid: false,
        paidAt: null,
        methodLabelSnapshot: null,
      });
    }
  };

  const showMethodRequired = methodError && (requireMethodAlways || value.isPaid) && !value.methodId;

  return (
    <Surface variant="muted" className="rounded-2xl p-3 gap-3">
      <Text className="text-sm font-semibold">{t('payments.title')}</Text>

      <View className="flex-row items-center justify-between">
        <Text className="text-sm">{t('payments.is_paid')}</Text>
        <ThemedSwitch value={value.isPaid} onValueChange={onTogglePaid} />
      </View>

      <View className="gap-2">
        <Text className="text-sm">{t('payments.method')}</Text>
        <PressScale onPress={() => setPickerOpen(true)} accessibilityLabel={t('payments.method')}>
          <Surface className="flex-row items-center justify-between rounded-2xl px-4 py-3">
            <Text className={value.methodId ? '' : 'opacity-50'}>
              {value.methodId
                ? value.methodLabelSnapshot ?? t('payments.method')
                : t('payments.method_picker_title')}
            </Text>
            <ChevronDown size={16} color="#5C4E40" />
          </Surface>
        </PressScale>
        {showMethodRequired ? (
          <Text className="text-sm text-danger dark:text-danger-dark">{methodError}</Text>
        ) : null}
      </View>

      {value.isPaid ? (
        <DateField
          label={t('payments.paid_at')}
          value={value.paidAt ? parseISO(value.paidAt) : null}
          onChange={(d) => onChange({ ...value, paidAt: d ? d.toISOString() : null })}
          onValidityChange={onPaidAtValidityChange}
        />
      ) : null}

      <PaymentMethodPicker
        visible={pickerOpen}
        selectedId={value.methodId}
        onPick={onPickMethod}
        onClose={() => setPickerOpen(false)}
      />
    </Surface>
  );
}
