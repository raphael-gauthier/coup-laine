import { ScrollView, View } from 'react-native';
import { useTranslation } from 'react-i18next';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import type { TFunction } from 'i18next';

import { Button } from '@/ui/primitives/button';
import { RHFTextField } from '@/ui/components/rhf-text-field';
import { haptics } from '@/ui/motion/haptics';
import type { AnimalCategory } from '@/domain/models/animal-category';
import type { UpsertCategoryInput } from '@/state/queries/catalogs';

interface Props {
  initial?: AnimalCategory;
  speciesId: string;
  saving?: boolean;
  onSubmit: (input: UpsertCategoryInput) => void;
  onCancel?: () => void;
}

interface FormValues {
  label: string;
}

function makeSchema(t: TFunction) {
  return z.object({
    label: z.string().trim().min(1, t('catalogs.errors.label_required')),
  });
}

export function AnimalCategoryForm({ initial, speciesId, saving, onSubmit, onCancel }: Props) {
  const { t } = useTranslation();
  const { control, handleSubmit } = useForm<FormValues>({
    defaultValues: {
      label: initial?.label ?? '',
    },
    resolver: zodResolver(makeSchema(t)),
    mode: 'onTouched',
  });

  const onValid = (values: FormValues) => {
    onSubmit({
      id: initial?.id,
      speciesId,
      label: values.label.trim(),
      ordering: initial?.ordering ?? 100,
    });
  };

  const onInvalid = () => {
    void haptics.error();
  };

  return (
    <ScrollView contentContainerStyle={{ paddingHorizontal: 16, paddingTop: 16, paddingBottom: 32, gap: 16 }}>
      <RHFTextField
        control={control}
        name="label"
        label={t('catalogs.categories.label')}
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
