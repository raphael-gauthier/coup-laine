import { useState } from 'react';
import { ScrollView, View } from 'react-native';
import { useTranslation } from 'react-i18next';
import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { Button } from '@/ui/primitives/button';
import { ScreenHeader } from '@/ui/components/screen-header';
import { AddressAutocompleteInput } from '@/ui/components/address-autocomplete-input';
import { useBaseAddress, useSetBaseAddress, type BaseAddress } from '@/state/queries/settings';
import { haptics } from '@/ui/motion/haptics';
import { errorToast } from '@/ui/components/error-toast';
import type { BanResult } from '@/infra/services/ban-geocoding';

export default function BaseScreen() {
  const { t } = useTranslation();
  const { data: current } = useBaseAddress();
  const setBase = useSetBaseAddress();
  const [pending, setPending] = useState<BaseAddress | null>(null);

  const onSelect = (r: BanResult) => {
    setPending({
      label: r.label,
      city: r.city,
      postcode: r.postcode,
      lat: r.lat,
      lon: r.lon,
    });
  };

  const onSave = () => {
    if (!pending) return;
    setBase.mutate(pending, {
      onSuccess: () => {
        void haptics.success();
        setPending(null);
      },
      onError: (err) => {
        errorToast(t('common.error_generic'), err instanceof Error ? err.message : undefined);
      },
    });
  };

  return (
    <Surface className="flex-1">
      <ScreenHeader title={t('settings.base.screen_title')} />
      <ScrollView contentContainerClassName="px-4 pt-2 gap-4" keyboardShouldPersistTaps="handled">
        {current && (
          <Surface variant="muted" className="rounded-2xl px-4 py-3">
            <Text variant="muted" className="text-sm">{t('settings.base.current_label')}</Text>
            <Text className="mt-1">{current.label}</Text>
          </Surface>
        )}

        <View className="gap-2">
          <Text className="text-sm font-medium">{t('settings.base.address_label')}</Text>
          <AddressAutocompleteInput
            initialValue={current?.label ?? ''}
            placeholder={t('settings.base.address_placeholder')}
            onSelect={onSelect}
          />
        </View>

        <Button
          onPress={onSave}
          disabled={!pending || setBase.isPending}
          loading={setBase.isPending}
        >
          {t('settings.base.save_button')}
        </Button>
      </ScrollView>
    </Surface>
  );
}
