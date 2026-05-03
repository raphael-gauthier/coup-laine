import { useState } from 'react';
import { ScrollView, View } from 'react-native';
import { useRouter } from 'expo-router';
import { useTranslation } from 'react-i18next';
import { Home } from 'lucide-react-native';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { Button } from '@/ui/primitives/button';
import { AddressAutocompleteInput } from '@/ui/components/address-autocomplete-input';
import { useSetBaseAddress, type BaseAddress } from '@/state/queries/settings';
import { errorToast } from '@/ui/components/error-toast';
import { haptics } from '@/ui/motion/haptics';
import type { BanResult } from '@/infra/services/ban-geocoding';

export default function OnboardingBaseScreen() {
  const { t } = useTranslation();
  const router = useRouter();
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
        router.push('/onboarding/species' as never);
      },
      onError: (err) => {
        errorToast(t('common.error_generic'), err instanceof Error ? err.message : undefined);
      },
    });
  };

  return (
    <Surface className="flex-1">
      <ScrollView contentContainerStyle={{ flexGrow: 1, padding: 24, gap: 24 }} keyboardShouldPersistTaps="handled">
        <View className="items-center gap-3 mt-12">
          <Home size={48} color="#A1602F" />
          <Text className="text-2xl font-bold text-center">{t('onboarding.base.title')}</Text>
          <Text variant="muted" className="text-center">{t('onboarding.base.message')}</Text>
        </View>

        <View className="gap-2">
          <Text className="text-sm font-medium">{t('settings.base.address_label')}</Text>
          <AddressAutocompleteInput
            placeholder={t('settings.base.address_placeholder')}
            onSelect={onSelect}
          />
        </View>

        <View style={{ flex: 1 }} />

        <Button
          onPress={onSave}
          disabled={!pending || setBase.isPending}
          loading={setBase.isPending}
        >
          <Text variant="onPrimary" className="font-semibold">{t('onboarding.base.cta')}</Text>
        </Button>
      </ScrollView>
    </Surface>
  );
}
