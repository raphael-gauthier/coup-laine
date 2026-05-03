import { useState, useMemo } from 'react';
import { ScrollView, View } from 'react-native';
import { useTranslation } from 'react-i18next';

import { Text } from '@/ui/primitives/text';
import { Input } from '@/ui/primitives/input';
import { Button } from '@/ui/primitives/button';
import type { AnimalCategory } from '@/domain/models/animal-category';
import type { UpsertCategoryInput } from '@/state/queries/catalogs';

interface Props {
  initial?: AnimalCategory;
  speciesId: string;
  saving?: boolean;
  onSubmit: (input: UpsertCategoryInput) => void;
  onCancel?: () => void;
}

export function AnimalCategoryForm({ initial, speciesId, saving, onSubmit, onCancel }: Props) {
  const { t } = useTranslation();
  const [label, setLabel] = useState(initial?.label ?? '');
  const [minutes, setMinutes] = useState(String(initial?.averageMinutesPerUnit ?? 20));
  const [labelTouched, setLabelTouched] = useState(false);
  const [minutesTouched, setMinutesTouched] = useState(false);

  const errors = useMemo(() => {
    const out: { label?: string; minutes?: string } = {};
    if (label.trim().length === 0) out.label = t('catalogs.errors.label_required');
    const m = parseFloat(minutes);
    if (isNaN(m) || m <= 0) out.minutes = t('catalogs.errors.minutes_invalid');
    return out;
  }, [label, minutes, t]);

  const canSubmit = !errors.label && !errors.minutes && !saving;

  const handleSubmit = () => {
    setLabelTouched(true);
    setMinutesTouched(true);
    if (!canSubmit) return;
    onSubmit({
      id: initial?.id,
      speciesId,
      label: label.trim(),
      averageMinutesPerUnit: parseFloat(minutes),
      ordering: initial?.ordering ?? 100,
    });
  };

  return (
    <ScrollView contentContainerStyle={{ paddingHorizontal: 16, paddingTop: 16, paddingBottom: 32, gap: 16 }}>
      <View className="gap-2">
        <Text className="text-sm font-medium">{t('catalogs.categories.label')}</Text>
        <Input value={label} onChangeText={setLabel} onBlur={() => setLabelTouched(true)} />
        {labelTouched && errors.label ? (
          <Text className="text-sm text-danger dark:text-danger-dark">{errors.label}</Text>
        ) : null}
      </View>

      <View className="gap-2">
        <Text className="text-sm font-medium">{t('catalogs.categories.minutes')}</Text>
        <Input
          value={minutes}
          onChangeText={setMinutes}
          onBlur={() => setMinutesTouched(true)}
          keyboardType="numeric"
        />
        {minutesTouched && errors.minutes ? (
          <Text className="text-sm text-danger dark:text-danger-dark">{errors.minutes}</Text>
        ) : null}
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
