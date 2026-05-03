import { useState, useMemo } from 'react';
import { ScrollView, View, Switch } from 'react-native';
import { useTranslation } from 'react-i18next';

import { Text } from '@/ui/primitives/text';
import { Input } from '@/ui/primitives/input';
import { Button } from '@/ui/primitives/button';
import type { Prestation } from '@/domain/models/prestation';
import type { UpsertPrestationInput } from '@/state/queries/catalogs';

interface Props {
  initial?: Prestation;
  saving?: boolean;
  onSubmit: (input: UpsertPrestationInput) => void;
  onCancel?: () => void;
}

function centsToEurosString(cents: number | null | undefined): string {
  if (cents == null) return '';
  return (cents / 100).toFixed(2);
}

export function PrestationForm({ initial, saving, onSubmit, onCancel }: Props) {
  const { t } = useTranslation();
  const [label, setLabel] = useState(initial?.label ?? '');
  const [priceEuros, setPriceEuros] = useState(centsToEurosString(initial?.priceCents));
  const [minutes, setMinutes] = useState(String(initial?.minutes ?? 0));
  const [categoryId, setCategoryId] = useState(initial?.categoryId ?? '');
  const [isActive, setIsActive] = useState(initial?.isActive ?? true);
  const [labelTouched, setLabelTouched] = useState(false);
  const [priceTouched, setPriceTouched] = useState(false);
  const [minutesTouched, setMinutesTouched] = useState(false);

  const errors = useMemo(() => {
    const out: { label?: string; price?: string; minutes?: string } = {};
    if (label.trim().length === 0) out.label = t('catalogs.errors.label_required');
    if (priceEuros.trim().length > 0) {
      const p = parseFloat(priceEuros.replace(',', '.'));
      if (isNaN(p) || p < 0) out.price = t('catalogs.errors.price_invalid');
    }
    const m = parseInt(minutes, 10);
    if (isNaN(m) || m < 0) out.minutes = t('catalogs.errors.minutes_invalid');
    return out;
  }, [label, priceEuros, minutes, t]);

  const canSubmit = !errors.label && !errors.price && !errors.minutes && !saving;

  const handleSubmit = () => {
    setLabelTouched(true);
    setPriceTouched(true);
    setMinutesTouched(true);
    if (!canSubmit) return;
    const trimmedPrice = priceEuros.trim();
    const priceCents = trimmedPrice
      ? Math.round(parseFloat(trimmedPrice.replace(',', '.')) * 100)
      : null;
    onSubmit({
      id: initial?.id,
      label: label.trim(),
      priceCents,
      minutes: parseInt(minutes, 10),
      categoryId: categoryId.trim() || null,
      isActive,
      ordering: initial?.ordering ?? 100,
    });
  };

  return (
    <ScrollView contentContainerStyle={{ paddingHorizontal: 16, paddingTop: 16, paddingBottom: 32, gap: 16 }}>
      <View className="gap-2">
        <Text className="text-sm font-medium">{t('catalogs.prestations.label')}</Text>
        <Input value={label} onChangeText={setLabel} onBlur={() => setLabelTouched(true)} />
        {labelTouched && errors.label ? (
          <Text className="text-sm text-danger dark:text-danger-dark">{errors.label}</Text>
        ) : null}
      </View>

      <View className="gap-2">
        <Text className="text-sm font-medium">{t('catalogs.prestations.price')}</Text>
        <Input
          value={priceEuros}
          onChangeText={setPriceEuros}
          onBlur={() => setPriceTouched(true)}
          keyboardType="decimal-pad"
          placeholder="0,00"
        />
        {priceTouched && errors.price ? (
          <Text className="text-sm text-danger dark:text-danger-dark">{errors.price}</Text>
        ) : null}
      </View>

      <View className="gap-2">
        <Text className="text-sm font-medium">{t('catalogs.prestations.minutes')}</Text>
        <Input
          value={minutes}
          onChangeText={setMinutes}
          onBlur={() => setMinutesTouched(true)}
          keyboardType="number-pad"
          placeholder="20"
        />
        {minutesTouched && errors.minutes ? (
          <Text className="text-sm text-danger dark:text-danger-dark">{errors.minutes}</Text>
        ) : null}
      </View>

      <View className="gap-2">
        <Text className="text-sm font-medium">{t('catalogs.prestations.category_id')}</Text>
        {/* TODO R1.E: replace with cascading species → category picker */}
        <Input
          value={categoryId}
          onChangeText={setCategoryId}
          autoCapitalize="none"
          placeholder="sheep-adult"
        />
      </View>

      <View className="flex-row items-center justify-between">
        <Text className="text-sm font-medium">{t('catalogs.prestations.active')}</Text>
        <Switch value={isActive} onValueChange={setIsActive} />
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
