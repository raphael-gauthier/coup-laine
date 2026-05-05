import { View, ScrollView } from 'react-native';
import { useTranslation } from 'react-i18next';
import { Controller, useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import type { TFunction } from 'i18next';

import { Text } from '@/ui/primitives/text';
import { Button } from '@/ui/primitives/button';
import { AddressAutocompleteInput } from '@/ui/components/address-autocomplete-input';
import { PhonesEditor } from '@/ui/components/phones-editor';
import { AnimalCountsEditor } from '@/ui/components/animal-counts-editor';
import { RHFTextField } from '@/ui/components/rhf-text-field';
import { haptics } from '@/ui/motion/haptics';
import type { Client } from '@/domain/models/client';
import { AnimalCountList, type AnimalCount } from '@/domain/models/animal-count';
import type { UpsertClientInput } from '@/state/queries/clients';
import type { BanResult } from '@/infra/services/ban-geocoding';

interface Props {
  initial?: Client;
  saving?: boolean;
  onSubmit: (input: UpsertClientInput) => void;
  onCancel?: () => void;
}

interface AddressValue {
  label: string | null;
  city: string | null;
  postcode: string | null;
  lat: number | null;
  lon: number | null;
}

interface FormValues {
  displayName: string;
  phones: string[];
  address: AddressValue;
  animalCounts: AnimalCount[];
}

function makeSchema(t: TFunction) {
  return z.object({
    displayName: z.string().trim().min(1, t('clients.errors.display_name_required')),
    phones: z.array(z.string()),
    address: z.object({
      label: z.string().nullable(),
      city: z.string().nullable(),
      postcode: z.string().nullable(),
      lat: z.number().nullable(),
      lon: z.number().nullable(),
    }),
    animalCounts: AnimalCountList,
  });
}

export function ClientForm({ initial, saving, onSubmit, onCancel }: Props) {
  const { t } = useTranslation();
  const { control, handleSubmit } = useForm<FormValues>({
    defaultValues: {
      displayName: initial?.displayName ?? '',
      phones: initial?.phones ?? [],
      address: {
        label: initial?.addressLabel ?? null,
        city: initial?.addressCity ?? null,
        postcode: initial?.addressPostcode ?? null,
        lat: initial?.latitude ?? null,
        lon: initial?.longitude ?? null,
      },
      animalCounts: initial?.animalCounts ?? [],
    },
    resolver: zodResolver(makeSchema(t)),
    mode: 'onTouched',
  });

  const onValid = (values: FormValues) => {
    onSubmit({
      id: initial?.id,
      displayName: values.displayName.trim(),
      phones: values.phones.filter((p) => p.trim().length > 0),
      addressLabel: values.address.label,
      addressCity: values.address.city,
      addressPostcode: values.address.postcode,
      latitude: values.address.lat,
      longitude: values.address.lon,
      isWaiting: initial?.isWaiting ?? false,
      animalCounts: values.animalCounts,
    });
  };

  const onInvalid = () => {
    void haptics.error();
  };

  return (
    <ScrollView contentContainerClassName="px-4 py-4 gap-4" keyboardShouldPersistTaps="handled">
      <RHFTextField
        control={control}
        name="displayName"
        label={t('clients.display_name')}
        placeholder={t('clients.display_name_placeholder')}
      />

      <Controller
        control={control}
        name="address"
        render={({ field }) => {
          const onSelectAddress = (r: BanResult) => {
            field.onChange({
              label: r.label,
              city: r.city,
              postcode: r.postcode,
              lat: r.lat,
              lon: r.lon,
            });
          };
          return (
            <View className="gap-2">
              <Text className="text-sm font-medium">{t('clients.address')}</Text>
              <AddressAutocompleteInput
                initialValue={field.value.label ?? ''}
                placeholder={t('clients.address_placeholder')}
                onSelect={onSelectAddress}
              />
            </View>
          );
        }}
      />

      <Controller
        control={control}
        name="phones"
        render={({ field }) => (
          <PhonesEditor value={field.value} onChange={field.onChange} />
        )}
      />

      <Controller
        control={control}
        name="animalCounts"
        render={({ field }) => (
          <AnimalCountsEditor value={field.value} onChange={field.onChange} />
        )}
      />

      <View className="flex-row gap-2 mt-4">
        {onCancel ? (
          <Button variant="secondary" className="flex-1" onPress={onCancel} disabled={saving}>
            {t('common.cancel')}
          </Button>
        ) : null}
        <Button
          className="flex-1"
          onPress={handleSubmit(onValid, onInvalid)}
          loading={saving}
        >
          {t('common.save')}
        </Button>
      </View>
    </ScrollView>
  );
}
