import { View, ScrollView } from 'react-native';
import { useState, useMemo } from 'react';
import { useTranslation } from 'react-i18next';
import { Text } from '@/ui/primitives/text';
import { Input } from '@/ui/primitives/input';
import { Button } from '@/ui/primitives/button';
import { AddressAutocompleteInput } from '@/ui/components/address-autocomplete-input';
import { PhonesEditor } from '@/ui/components/phones-editor';
import { AnimalCountsEditor } from '@/ui/components/animal-counts-editor';
import type { Client } from '@/domain/models/client';
import type { UpsertClientInput } from '@/state/queries/clients';
import type { BanResult } from '@/infra/services/ban-geocoding';

interface Props {
  initial?: Client;
  saving?: boolean;
  onSubmit: (input: UpsertClientInput) => void;
  onCancel?: () => void;
}

export function ClientForm({ initial, saving, onSubmit, onCancel }: Props) {
  const { t } = useTranslation();
  const [displayName, setDisplayName] = useState(initial?.displayName ?? '');
  const [displayNameTouched, setDisplayNameTouched] = useState(false);
  const [phones, setPhones] = useState<string[]>(initial?.phones ?? []);
  const [address, setAddress] = useState<{
    label: string | null;
    city: string | null;
    postcode: string | null;
    lat: number | null;
    lon: number | null;
  }>({
    label: initial?.addressLabel ?? null,
    city: initial?.addressCity ?? null,
    postcode: initial?.addressPostcode ?? null,
    lat: initial?.latitude ?? null,
    lon: initial?.longitude ?? null,
  });
  const [animalCounts, setAnimalCounts] = useState(initial?.animalCounts ?? []);

  const onSelectAddress = (r: BanResult) => {
    setAddress({
      label: r.label,
      city: r.city,
      postcode: r.postcode,
      lat: r.lat,
      lon: r.lon,
    });
  };

  const errors = useMemo(() => {
    const out: { displayName?: string } = {};
    if (displayName.trim().length === 0) {
      out.displayName = t('clients.errors.display_name_required');
    }
    return out;
  }, [displayName, t]);

  const canSubmit = !errors.displayName && !saving;

  const handleSubmit = () => {
    setDisplayNameTouched(true);
    if (!canSubmit) return;
    onSubmit({
      id: initial?.id,
      displayName: displayName.trim(),
      phones: phones.filter((p) => p.trim().length > 0),
      addressLabel: address.label,
      addressCity: address.city,
      addressPostcode: address.postcode,
      latitude: address.lat,
      longitude: address.lon,
      isWaiting: initial?.isWaiting ?? false,
      animalCounts,
    });
  };

  return (
    <ScrollView contentContainerClassName="px-4 py-4 gap-4" keyboardShouldPersistTaps="handled">
      <View className="gap-2">
        <Text className="text-sm font-medium">{t('clients.display_name')}</Text>
        <Input
          value={displayName}
          onChangeText={setDisplayName}
          onBlur={() => setDisplayNameTouched(true)}
          placeholder={t('clients.display_name_placeholder')}
        />
        {displayNameTouched && errors.displayName ? (
          <Text className="text-sm text-danger dark:text-danger-dark">{errors.displayName}</Text>
        ) : null}
      </View>

      <View className="gap-2">
        <Text className="text-sm font-medium">{t('clients.address')}</Text>
        <AddressAutocompleteInput
          initialValue={address.label ?? ''}
          placeholder={t('clients.address_placeholder')}
          onSelect={onSelectAddress}
        />
      </View>

      <PhonesEditor value={phones} onChange={setPhones} />

      <AnimalCountsEditor value={animalCounts} onChange={setAnimalCounts} />

      <View className="flex-row gap-2 mt-4">
        {onCancel ? (
          <Button variant="secondary" className="flex-1" onPress={onCancel} disabled={saving}>
            {t('common.cancel')}
          </Button>
        ) : null}
        <Button
          className="flex-1"
          onPress={handleSubmit}
          disabled={!canSubmit}
          loading={saving}
        >
          {t('common.save')}
        </Button>
      </View>
    </ScrollView>
  );
}
