import { useMemo, useState } from 'react';
import { ScrollView, View, Platform } from 'react-native';
import DateTimePicker from '@react-native-community/datetimepicker';
import { useTranslation } from 'react-i18next';
import { format, parseISO } from 'date-fns';
import { fr } from 'date-fns/locale';
import { Controller, useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { Button } from '@/ui/primitives/button';
import { PressScale } from '@/ui/motion/press-scale';
import { FormField } from '@/ui/components/form-field';
import { RHFTextField } from '@/ui/components/rhf-text-field';
import { ServicePickerSheet } from '@/ui/components/service-picker-sheet';
import { haptics } from '@/ui/motion/haptics';
import { useClient } from '@/state/queries/clients';
import { EMPTY_PAYMENT } from '@/domain/models/payment';
import type { ManualHistoryEntry } from '@/domain/models/manual-history-entry';
import type { TourStopService } from '@/domain/models/tour-stop-service';
import type { UpsertManualHistoryInput } from '@/state/queries/history';

interface Props {
  initial?: ManualHistoryEntry;
  clientId: string;
  saving?: boolean;
  onSubmit: (input: UpsertManualHistoryInput) => void;
  onCancel?: () => void;
}

interface FormValues {
  date: Date;
  notes: string;
}

const schema = z.object({
  date: z.date(),
  notes: z.string(),
});

export function ManualHistoryForm({ initial, clientId, saving, onSubmit, onCancel }: Props) {
  const { t } = useTranslation();
  const { control, handleSubmit } = useForm<FormValues>({
    defaultValues: {
      date: initial?.date ? parseISO(initial.date) : new Date(),
      notes: initial?.notes ?? '',
    },
    resolver: zodResolver(schema),
    mode: 'onTouched',
  });
  const [showDatePicker, setShowDatePicker] = useState(false);
  const [services, setServices] = useState<TourStopService[]>(initial?.services ?? []);
  const [pickerOpen, setPickerOpen] = useState(false);

  const { data: client } = useClient(clientId);

  const totalCents = useMemo(
    () => services.reduce((sum, s) => sum + s.qty * s.priceCentsSnapshot, 0),
    [services]
  );

  const onValid = (values: FormValues) => {
    onSubmit({
      id: initial?.id,
      clientId,
      date: format(values.date, 'yyyy-MM-dd'),
      notes: values.notes.trim() || null,
      services,
      payment: EMPTY_PAYMENT,  // Task 14 wires real PaymentEditor state
    });
  };

  const onInvalid = () => {
    void haptics.error();
  };

  return (
    <ScrollView contentContainerStyle={{ paddingHorizontal: 16, paddingTop: 16, paddingBottom: 32, gap: 16 }}>
      <Controller
        control={control}
        name="date"
        render={({ field, fieldState }) => (
          <FormField label={t('history.manual.date')} error={fieldState.error?.message}>
            <PressScale onPress={() => setShowDatePicker(true)} accessibilityLabel={t('history.manual.date')}>
              <Surface variant="muted" className="rounded-2xl px-4 py-3">
                <Text>{format(field.value, 'PPP', { locale: fr })}</Text>
              </Surface>
            </PressScale>
            {showDatePicker && (
              <DateTimePicker
                value={field.value}
                mode="date"
                onChange={(_, d) => {
                  setShowDatePicker(Platform.OS === 'ios');
                  if (d) field.onChange(d);
                }}
              />
            )}
          </FormField>
        )}
      />

      <RHFTextField
        control={control}
        name="notes"
        label={t('history.manual.notes')}
        multiline
        numberOfLines={4}
        className="min-h-[100px] py-2"
      />

      <FormField label={t('history.manual.services')}>
        <Surface variant="muted" className="rounded-2xl p-3 gap-2">
          {services.length === 0 ? (
            <Text variant="muted" className="text-sm">{t('history.manual.no_services')}</Text>
          ) : (
            services.map((s) => (
              <View key={s.serviceId} className="flex-row items-center justify-between">
                <Text className="text-sm flex-1">
                  {s.nameSnapshot} × {s.qty}
                </Text>
                <Text className="text-sm font-medium">
                  {((s.qty * s.priceCentsSnapshot) / 100).toFixed(2)} €
                </Text>
              </View>
            ))
          )}
          <View className="flex-row items-center justify-between pt-2 border-t border-border dark:border-border-dark">
            <Text className="text-sm font-semibold">{t('history.manual.total')}</Text>
            <Text className="text-base font-semibold">{(totalCents / 100).toFixed(2)} €</Text>
          </View>
          <Button variant="secondary" onPress={() => setPickerOpen(true)}>
            {services.length === 0 ? t('history.manual.add_services') : t('history.manual.edit_services')}
          </Button>
        </Surface>
      </FormField>

      <View className="flex-row gap-2 mt-4">
        {onCancel ? (
          <Button variant="secondary" className="flex-1" onPress={onCancel} disabled={saving}>
            {t('common.cancel')}
          </Button>
        ) : null}
        <Button className="flex-1" onPress={handleSubmit(onValid, onInvalid)} loading={saving}>
          {t('common.save')}
        </Button>
      </View>

      <ServicePickerSheet
        visible={pickerOpen}
        clientAnimalCounts={client?.animalCounts ?? []}
        initialSelection={services}
        priceEditable
        onConfirm={(next) => {
          setServices(next);
          setPickerOpen(false);
        }}
        onClose={() => setPickerOpen(false)}
      />
    </ScrollView>
  );
}
