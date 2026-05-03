import { useState, useMemo } from 'react';
import { ScrollView, View, Modal, TouchableOpacity } from 'react-native';
import { useTranslation } from 'react-i18next';
import { ChevronDown, X } from 'lucide-react-native';

import { Text } from '@/ui/primitives/text';
import { Input } from '@/ui/primitives/input';
import { Button } from '@/ui/primitives/button';
import { Surface } from '@/ui/primitives/surface';
import { PressScale } from '@/ui/motion/press-scale';
import { useSpecies, useAnimalCategories } from '@/state/queries/species';
import type { Prestation } from '@/domain/models/prestation';
import type { UpsertPrestationInput } from '@/state/queries/catalogs';
import { ThemedSwitch } from '@/ui/primitives/themed-switch';

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
  const { data: speciesList = [] } = useSpecies();
  const { data: categories = [] } = useAnimalCategories();

  const [label, setLabel] = useState(initial?.label ?? '');
  const [priceEuros, setPriceEuros] = useState(centsToEurosString(initial?.priceCents));
  const [minutes, setMinutes] = useState(String(initial?.minutes ?? 0));
  const [categoryId, setCategoryId] = useState<string | null>(initial?.categoryId ?? null);
  const [isActive, setIsActive] = useState(initial?.isActive ?? true);
  const [labelTouched, setLabelTouched] = useState(false);
  const [priceTouched, setPriceTouched] = useState(false);
  const [minutesTouched, setMinutesTouched] = useState(false);
  const [categoryPickerVisible, setCategoryPickerVisible] = useState(false);

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
      categoryId,
      isActive,
      ordering: initial?.ordering ?? 100,
    });
  };

  // Resolved category label for display
  const selectedCategory = categoryId ? categories.find((c) => c.id === categoryId) : null;
  const selectedCategoryLabel = selectedCategory?.label ?? t('catalogs.prestations.no_category_option');

  return (
    <>
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
        <PressScale onPress={() => setCategoryPickerVisible(true)}>
          <Surface variant="muted" className="flex-row items-center justify-between rounded-2xl px-4 py-3">
            <Text className={categoryId ? '' : 'opacity-50'}>{selectedCategoryLabel}</Text>
            <ChevronDown size={16} color="#5C4E40" />
          </Surface>
        </PressScale>
      </View>

      <View className="flex-row items-center justify-between">
        <Text className="text-sm font-medium">{t('catalogs.prestations.active')}</Text>
        <ThemedSwitch value={isActive} onValueChange={setIsActive} />
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

    {/* Category picker modal */}
    <Modal
      visible={categoryPickerVisible}
      animationType="slide"
      transparent
      presentationStyle="overFullScreen"
    >
      <TouchableOpacity
        style={{ flex: 1, backgroundColor: 'rgba(0,0,0,0.4)' }}
        onPress={() => setCategoryPickerVisible(false)}
        activeOpacity={1}
      />
      <Surface className="rounded-t-3xl px-4 pb-8 pt-4" style={{ maxHeight: '65%' }}>
        <View className="flex-row items-center justify-between mb-4">
          <Text className="text-lg font-semibold">{t('catalogs.prestations.category_picker_title')}</Text>
          <PressScale onPress={() => setCategoryPickerVisible(false)}>
            <X size={22} color="#5C4E40" />
          </PressScale>
        </View>

        <ScrollView>
          {/* No category option */}
          <PressScale onPress={() => { setCategoryId(null); setCategoryPickerVisible(false); }}>
            <View className={`flex-row items-center px-3 py-3 rounded-xl mb-1 ${!categoryId ? 'bg-primary dark:bg-primary-dark' : ''}`}>
              <Text className={!categoryId ? 'text-primary-foreground dark:text-primary-dark-foreground' : ''}>
                {t('catalogs.prestations.no_category_option')}
              </Text>
            </View>
          </PressScale>

          {speciesList.map((sp) => {
            const spCategories = categories.filter((c) => c.speciesId === sp.id);
            if (spCategories.length === 0) return null;
            return (
              <View key={sp.id} className="mb-3">
                <Text variant="muted" className="text-xs font-semibold uppercase tracking-widest px-3 py-1">
                  {sp.label}
                </Text>
                {spCategories.map((cat) => (
                  <PressScale
                    key={cat.id}
                    onPress={() => {
                      setCategoryId(cat.id);
                      setCategoryPickerVisible(false);
                    }}
                  >
                    <View className={`flex-row items-center px-4 py-3 rounded-xl mb-1 ${categoryId === cat.id ? 'bg-primary dark:bg-primary-dark' : ''}`}>
                      <Text className={categoryId === cat.id ? 'text-primary-foreground dark:text-primary-dark-foreground' : ''}>
                        {cat.label}
                      </Text>
                    </View>
                  </PressScale>
                ))}
              </View>
            );
          })}
        </ScrollView>
      </Surface>
    </Modal>
    </>
  );
}
