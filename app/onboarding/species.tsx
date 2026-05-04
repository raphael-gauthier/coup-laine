import { useEffect, useState } from 'react';
import { ScrollView, View } from 'react-native';
import { ThemedSwitch } from '@/ui/primitives/themed-switch';
import { useRouter } from 'expo-router';
import { useTranslation } from 'react-i18next';
import { Leaf } from 'lucide-react-native';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { Button } from '@/ui/primitives/button';
import { haptics } from '@/ui/motion/haptics';
import { useUpsertSpecies, useUpsertAnimalCategory } from '@/state/queries/catalogs';
import { useUserProfessions } from '@/state/queries/settings';
import {
  SPECIES_CATALOG,
  unionSpeciesFromProfessions,
  type SpeciesKey,
} from '@/domain/catalog/profession-catalog';

export default function OnboardingSpeciesScreen() {
  const { t } = useTranslation();
  const router = useRouter();
  const upsertSpecies = useUpsertSpecies();
  const upsertCategory = useUpsertAnimalCategory();
  const { data: professionIds, isSuccess } = useUserProfessions();

  const [enabled, setEnabled] = useState<Record<SpeciesKey, boolean>>(
    () => Object.fromEntries(SPECIES_CATALOG.map((s) => [s.key, false])) as Record<SpeciesKey, boolean>
  );
  const [hydrated, setHydrated] = useState(false);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    if (hydrated || !isSuccess) return;
    const fromProfessions = unionSpeciesFromProfessions(professionIds ?? []);
    if (fromProfessions.length > 0) {
      setEnabled((prev) => {
        const next = { ...prev };
        for (const k of fromProfessions) next[k] = true;
        return next;
      });
    }
    setHydrated(true);
  }, [professionIds, isSuccess, hydrated]);

  const onContinue = async () => {
    setSaving(true);
    try {
      const selected = SPECIES_CATALOG.filter((s) => enabled[s.key]);
      for (const sp of selected) {
        await upsertSpecies.mutateAsync({
          id: sp.id,
          label: sp.label,
          iconKey: sp.iconKey,
          ordering: sp.ordering,
        });
        await upsertCategory.mutateAsync({
          id: sp.defaultCategoryId,
          speciesId: sp.id,
          label: sp.label,
          ordering: 1,
        });
      }
      void haptics.success();
      router.push('/onboarding/services' as never);
    } catch {
      // errors already shown by the mutation hooks via errorToast
    } finally {
      setSaving(false);
    }
  };

  return (
    <Surface className="flex-1">
      <ScrollView contentContainerStyle={{ flexGrow: 1, padding: 24, gap: 24 }}>
        <View className="items-center gap-3 mt-12">
          <Leaf size={48} color="#A1602F" />
          <Text className="text-2xl font-bold text-center">{t('onboarding.species.title')}</Text>
          <Text variant="muted" className="text-center">{t('onboarding.species.message')}</Text>
        </View>

        <View className="gap-2 mt-4">
          {SPECIES_CATALOG.map((sp) => (
            <Surface key={sp.id} variant="muted" className="flex-row items-center justify-between rounded-2xl px-4 py-3">
              <Text className="font-semibold">{sp.label}</Text>
              <ThemedSwitch
                value={!!enabled[sp.key]}
                onValueChange={(v) => setEnabled((prev) => ({ ...prev, [sp.key]: v }))}
              />
            </Surface>
          ))}
        </View>

        <View style={{ flex: 1 }} />

        <Button
          onPress={() => void onContinue()}
          disabled={saving}
          loading={saving}
        >
          <Text variant="onPrimary" className="font-semibold">{t('onboarding.species.cta')}</Text>
        </Button>

        <Button
          variant="secondary"
          onPress={() => router.push('/onboarding/services' as never)}
          disabled={saving}
        >
          {t('onboarding.species.skip')}
        </Button>
      </ScrollView>
    </Surface>
  );
}
