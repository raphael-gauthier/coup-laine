import { useState } from 'react';
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
import { haptics } from '@/ui/motion/haptics';
import type { ManualHistoryEntry } from '@/domain/models/manual-history-entry';
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

  const onValid = (values: FormValues) => {
    onSubmit({
      id: initial?.id,
      clientId,
      date: format(values.date, 'yyyy-MM-dd'),
      notes: values.notes.trim() || null,
      services: initial?.services ?? [],
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
    </ScrollView>
  );
}
