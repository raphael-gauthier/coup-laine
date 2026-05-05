import { useState } from 'react';
import { ScrollView, View, Modal, TouchableOpacity } from 'react-native';
import { useTranslation } from 'react-i18next';
import { Controller, useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import type { TFunction } from 'i18next';
import { ChevronDown, X } from 'lucide-react-native';

import { Text } from '@/ui/primitives/text';
import { Button } from '@/ui/primitives/button';
import { Surface } from '@/ui/primitives/surface';
import { PressScale } from '@/ui/motion/press-scale';
import { RHFTextField } from '@/ui/components/rhf-text-field';
import { haptics } from '@/ui/motion/haptics';
import { useSpecies, useAnimalCategories } from '@/state/queries/species';
import type { Service } from '@/domain/models/service';
import type { UpsertServiceInput } from '@/state/queries/catalogs';
import { ThemedSwitch } from '@/ui/primitives/themed-switch';

interface Props {
  initial?: Service;
  saving?: boolean;
  onSubmit: (input: UpsertServiceInput) => void;
  onCancel?: () => void;
}

interface FormValues {
  label: string;
  priceEuros: string;
  minutes: string;
  categoryId: string | null;
  isActive: boolean;
}

function centsToEurosString(cents: number | null | undefined): string {
  if (cents == null) return '';
  return (cents / 100).toFixed(2);
}

function makeSchema(t: TFunction) {
  return z.object({
    label: z.string().trim().min(1, t('catalogs.errors.label_required')),
    priceEuros: z.string().refine(
      (v) => {
        const trimmed = v.trim();
        if (trimmed.length === 0) return true;
        const p = parseFloat(trimmed.replace(',', '.'));
        return !isNaN(p) && p >= 0;
      },
      { message: t('catalogs.errors.price_invalid') },
    ),
    minutes: z.string().refine(
      (v) => {
        const m = parseInt(v, 10);
        return !isNaN(m) && m >= 0;
      },
      { message: t('catalogs.errors.minutes_invalid') },
    ),
    categoryId: z.string().nullable(),
    isActive: z.boolean(),
  });
}

export function ServiceForm({ initial, saving, onSubmit, onCancel }: Props) {
  const { t } = useTranslation();
  const { data: speciesList = [] } = useSpecies();
  const { data: categories = [] } = useAnimalCategories();

  const { control, handleSubmit } = useForm<FormValues>({
    defaultValues: {
      label: initial?.label ?? '',
      priceEuros: centsToEurosString(initial?.priceCents),
      minutes: String(initial?.minutes ?? 0),
      categoryId: initial?.categoryId ?? null,
      isActive: initial?.isActive ?? true,
    },
    resolver: zodResolver(makeSchema(t)),
    mode: 'onTouched',
  });

  const [categoryPickerVisible, setCategoryPickerVisible] = useState(false);

  const onValid = (values: FormValues) => {
    const trimmedPrice = values.priceEuros.trim();
    const priceCents = trimmedPrice
      ? Math.round(parseFloat(trimmedPrice.replace(',', '.')) * 100)
      : null;
    onSubmit({
      id: initial?.id,
      label: values.label.trim(),
      priceCents,
      minutes: parseInt(values.minutes, 10),
      categoryId: values.categoryId,
      isActive: values.isActive,
      ordering: initial?.ordering ?? 100,
    });
  };

  const onInvalid = () => {
    void haptics.error();
  };

  return (
    <>
    <ScrollView contentContainerStyle={{ paddingHorizontal: 16, paddingTop: 16, paddingBottom: 32, gap: 16 }}>
      <RHFTextField
        control={control}
        name="label"
        label={t('catalogs.services.label')}
      />

      <RHFTextField
        control={control}
        name="priceEuros"
        label={t('catalogs.services.price')}
        keyboardType="decimal-pad"
        placeholder="0,00"
      />

      <RHFTextField
        control={control}
        name="minutes"
        label={t('catalogs.services.minutes')}
        keyboardType="number-pad"
        placeholder="20"
      />

      <Controller
        control={control}
        name="categoryId"
        render={({ field }) => {
          const selectedCategory = field.value ? categories.find((c) => c.id === field.value) : null;
          const selectedCategoryLabel = selectedCategory?.label ?? t('catalogs.services.no_category_option');
          return (
            <>
              <View className="gap-2">
                <Text className="text-sm font-medium">{t('catalogs.services.category_id')}</Text>
                <PressScale onPress={() => setCategoryPickerVisible(true)} accessibilityLabel={selectedCategoryLabel}>
                  <Surface variant="muted" className="flex-row items-center justify-between rounded-2xl px-4 py-3">
                    <Text className={field.value ? '' : 'opacity-50'}>{selectedCategoryLabel}</Text>
                    <ChevronDown size={16} color="#5C4E40" />
                  </Surface>
                </PressScale>
              </View>

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
                    <Text className="text-lg font-semibold">{t('catalogs.services.category_picker_title')}</Text>
                    <PressScale onPress={() => setCategoryPickerVisible(false)} accessibilityLabel={t('common.close')}>
                      <X size={22} color="#5C4E40" />
                    </PressScale>
                  </View>

                  <ScrollView>
                    {/* No category option */}
                    <PressScale
                      onPress={() => { field.onChange(null); setCategoryPickerVisible(false); }}
                      accessibilityLabel={t('catalogs.services.no_category_option')}
                    >
                      <View className={`flex-row items-center px-3 py-3 rounded-xl mb-1 ${!field.value ? 'bg-primary dark:bg-primary-dark' : ''}`}>
                        <Text className={!field.value ? 'text-primary-foreground dark:text-primary-dark-foreground' : ''}>
                          {t('catalogs.services.no_category_option')}
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
                                field.onChange(cat.id);
                                setCategoryPickerVisible(false);
                              }}
                              accessibilityLabel={cat.label}
                            >
                              <View className={`flex-row items-center px-4 py-3 rounded-xl mb-1 ${field.value === cat.id ? 'bg-primary dark:bg-primary-dark' : ''}`}>
                                <Text className={field.value === cat.id ? 'text-primary-foreground dark:text-primary-dark-foreground' : ''}>
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
        }}
      />

      <Controller
        control={control}
        name="isActive"
        render={({ field }) => (
          <View className="flex-row items-center justify-between">
            <Text className="text-sm font-medium">{t('catalogs.services.active')}</Text>
            <ThemedSwitch value={field.value} onValueChange={field.onChange} />
          </View>
        )}
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
    </>
  );
}
