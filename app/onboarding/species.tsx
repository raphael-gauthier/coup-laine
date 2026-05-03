import { useState } from 'react';
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
import { newId } from '@/lib/id';

interface DefaultSpecies {
  id: string;
  label: string;
  iconKey: string;
  categories: { label: string }[];
}

const DEFAULT_SPECIES: DefaultSpecies[] = [
  {
    id: 'species-moutons',
    label: 'Moutons',
    iconKey: 'sheep',
    categories: [{ label: 'Adultes' }, { label: 'Agneaux' }],
  },
  {
    id: 'species-chevres',
    label: 'Chèvres',
    iconKey: 'goat',
    categories: [{ label: 'Adultes' }, { label: 'Chevreaux' }],
  },
  {
    id: 'species-bovins',
    label: 'Bovins',
    iconKey: 'cow',
    categories: [{ label: 'Vaches' }, { label: 'Veaux' }],
  },
  {
    id: 'species-volailles',
    label: 'Volailles',
    iconKey: 'bird',
    categories: [{ label: 'Poules' }, { label: 'Canards' }],
  },
];

export default function OnboardingSpeciesScreen() {
  const { t } = useTranslation();
  const router = useRouter();
  const upsertSpecies = useUpsertSpecies();
  const upsertCategory = useUpsertAnimalCategory();

  const [enabled, setEnabled] = useState<Record<string, boolean>>(
    Object.fromEntries(DEFAULT_SPECIES.map((s) => [s.id, true]))
  );
  const [saving, setSaving] = useState(false);

  const onContinue = async () => {
    setSaving(true);
    try {
      const selected = DEFAULT_SPECIES.filter((s) => enabled[s.id]);
      for (const [i, sp] of selected.entries()) {
        await upsertSpecies.mutateAsync({
          id: sp.id,
          label: sp.label,
          iconKey: sp.iconKey,
          ordering: i + 1,
        });
        for (const [j, cat] of sp.categories.entries()) {
          await upsertCategory.mutateAsync({
            id: newId(),
            speciesId: sp.id,
            label: cat.label,
            ordering: j + 1,
          });
        }
      }
      void haptics.success();
      router.push('/onboarding/recap' as never);
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
          {DEFAULT_SPECIES.map((sp) => (
            <Surface key={sp.id} variant="muted" className="flex-row items-center justify-between rounded-2xl px-4 py-3">
              <Text className="font-semibold">{sp.label}</Text>
              <ThemedSwitch
                value={!!enabled[sp.id]}
                onValueChange={(v) => setEnabled((prev) => ({ ...prev, [sp.id]: v }))}
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
          onPress={() => router.push('/onboarding/recap' as never)}
          disabled={saving}
        >
          {t('onboarding.species.skip')}
        </Button>
      </ScrollView>
    </Surface>
  );
}
