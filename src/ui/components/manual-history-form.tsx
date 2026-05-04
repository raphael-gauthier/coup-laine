import { useState, useMemo } from 'react';
import { ScrollView, View, Platform } from 'react-native';
import DateTimePicker from '@react-native-community/datetimepicker';
import { useTranslation } from 'react-i18next';
import { format, parseISO } from 'date-fns';
import { fr } from 'date-fns/locale';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { Input } from '@/ui/primitives/input';
import { Button } from '@/ui/primitives/button';
import { PressScale } from '@/ui/motion/press-scale';
import type { ManualHistoryEntry } from '@/domain/models/manual-history-entry';
import type { UpsertManualHistoryInput } from '@/state/queries/history';

interface Props {
  initial?: ManualHistoryEntry;
  clientId: string;
  saving?: boolean;
  onSubmit: (input: UpsertManualHistoryInput) => void;
  onCancel?: () => void;
}

export function ManualHistoryForm({ initial, clientId, saving, onSubmit, onCancel }: Props) {
  const { t } = useTranslation();
  const [date, setDate] = useState<Date>(initial?.date ? parseISO(initial.date) : new Date());
  const [notes, setNotes] = useState(initial?.notes ?? '');
  const [showDatePicker, setShowDatePicker] = useState(false);

  const errors = useMemo(() => {
    const out: { date?: string } = {};
    if (!date) out.date = t('history.errors.date_required');
    return out;
  }, [date, t]);

  const canSubmit = !errors.date && !saving;

  const handleSubmit = () => {
    if (!canSubmit) return;
    onSubmit({
      id: initial?.id,
      clientId,
      date: format(date, 'yyyy-MM-dd'),
      notes: notes.trim() || null,
      services: initial?.services ?? [],
    });
  };

  return (
    <ScrollView contentContainerStyle={{ paddingHorizontal: 16, paddingTop: 16, paddingBottom: 32, gap: 16 }}>
      <View className="gap-2">
        <Text className="text-sm font-medium">{t('history.manual.date')}</Text>
        <PressScale onPress={() => setShowDatePicker(true)}>
          <Surface variant="muted" className="rounded-2xl px-4 py-3">
            <Text>{format(date, 'PPP', { locale: fr })}</Text>
          </Surface>
        </PressScale>
        {showDatePicker && (
          <DateTimePicker
            value={date}
            mode="date"
            onChange={(_, d) => {
              setShowDatePicker(Platform.OS === 'ios');
              if (d) setDate(d);
            }}
          />
        )}
      </View>

      <View className="gap-2">
        <Text className="text-sm font-medium">{t('history.manual.notes')}</Text>
        <Input
          value={notes}
          onChangeText={setNotes}
          multiline
          numberOfLines={4}
          className="min-h-[100px] py-2"
        />
      </View>

      <View className="flex-row gap-2 mt-4">
        {onCancel ? (
          <Button variant="secondary" className="flex-1" onPress={onCancel} disabled={saving}>
            {t('common.cancel')}
          </Button>
        ) : null}
        <Button className="flex-1" onPress={handleSubmit} disabled={!canSubmit} loading={saving}>
          {t('common.save')}
        </Button>
      </View>
    </ScrollView>
  );
}
