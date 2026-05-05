import { useEffect, useMemo, useState } from 'react';
import { ScrollView, View } from 'react-native';
import { useRouter } from 'expo-router';
import { useTranslation } from 'react-i18next';
import { ClipboardList } from 'lucide-react-native';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { Button } from '@/ui/primitives/button';
import { ThemedSwitch } from '@/ui/primitives/themed-switch';
import { haptics } from '@/ui/motion/haptics';
import { usePrimaryColor } from '@/ui/theme/colors';
import { useUserProfessions } from '@/state/queries/settings';
import { useSpecies } from '@/state/queries/species';
import { useUpsertService } from '@/state/queries/catalogs';
import {
  SPECIES_CATALOG,
  speciesByKey,
  unionServicesFromProfessions,
  type SpeciesKey,
} from '@/domain/catalog/profession-catalog';

type Row = { speciesKey: SpeciesKey; speciesLabel: string; categoryId: string; label: string; key: string };

export default function OnboardingServicesScreen() {
  const { t } = useTranslation();
  const router = useRouter();
  const { data: professionIds = [] } = useUserProfessions();
  const { data: speciesList = [] } = useSpecies();
  const upsertService = useUpsertService();
  const [saving, setSaving] = useState(false);
  const primary = usePrimaryColor();

  const enabledSpeciesKeys = useMemo<SpeciesKey[]>(() => {
    const dbIds = new Set(speciesList.map((s) => s.id));
    return SPECIES_CATALOG.filter((s) => dbIds.has(s.id)).map((s) => s.key);
  }, [speciesList]);

  const rows = useMemo<Row[]>(() => {
    const services = unionServicesFromProfessions(professionIds, enabledSpeciesKeys);
    return services.map((p) => {
      const sp = speciesByKey(p.speciesKey);
      return {
        speciesKey: p.speciesKey,
        speciesLabel: sp.label,
        categoryId: sp.defaultCategoryId,
        label: p.label,
        key: `${p.speciesKey}|${p.label}`,
      };
    });
  }, [professionIds, enabledSpeciesKeys]);

  const [checked, setChecked] = useState<Record<string, boolean>>({});
  const [hydrated, setHydrated] = useState(false);

  useEffect(() => {
    if (hydrated) return;
    if (rows.length === 0) return;
    setChecked(Object.fromEntries(rows.map((r) => [r.key, true])));
    setHydrated(true);
  }, [rows, hydrated]);

  const grouped = useMemo(() => {
    const map = new Map<SpeciesKey, Row[]>();
    for (const r of rows) {
      const arr = map.get(r.speciesKey) ?? [];
      arr.push(r);
      map.set(r.speciesKey, arr);
    }
    return Array.from(map.entries());
  }, [rows]);

  const onContinue = async () => {
    if (rows.length === 0) {
      router.push('/onboarding/recap' as never);
      return;
    }
    setSaving(true);
    try {
      const orderingByCategory = new Map<string, number>();
      for (const r of rows) {
        if (!checked[r.key]) continue;
        const next = (orderingByCategory.get(r.categoryId) ?? 0) + 1;
        orderingByCategory.set(r.categoryId, next);
        await upsertService.mutateAsync({
          label: r.label,
          priceCents: null,
          minutes: 0,
          categoryId: r.categoryId,
          isActive: true,
          ordering: next,
        });
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
          <ClipboardList size={48} color={primary} />
          <Text className="text-2xl font-bold text-center">{t('onboarding.services.title')}</Text>
          <Text variant="muted" className="text-center">{t('onboarding.services.message')}</Text>
        </View>

        {grouped.length === 0 ? (
          <Surface variant="muted" className="rounded-2xl p-4">
            <Text variant="muted" className="text-center">{t('onboarding.services.skip')}</Text>
          </Surface>
        ) : (
          <View className="gap-3">
            {grouped.map(([speciesKey, items]) => (
              <Surface key={speciesKey} variant="muted" className="rounded-2xl p-3 gap-2">
                <Text className="font-semibold">{speciesByKey(speciesKey).label}</Text>
                {items.map((r) => (
                  <View key={r.key} className="flex-row items-center justify-between">
                    <Text className="flex-1">{r.label}</Text>
                    <ThemedSwitch
                      value={!!checked[r.key]}
                      onValueChange={(v) => setChecked((prev) => ({ ...prev, [r.key]: v }))}
                    />
                  </View>
                ))}
              </Surface>
            ))}
          </View>
        )}

        <View style={{ flex: 1 }} />

        <Button
          onPress={() => void onContinue()}
          disabled={saving}
          loading={saving}
          accessibilityLabel={t('onboarding.services.cta')}
        >
          <Text variant="onPrimary" className="font-semibold">{t('onboarding.services.cta')}</Text>
        </Button>

        <Button
          variant="secondary"
          onPress={() => router.push('/onboarding/recap' as never)}
          disabled={saving}
        >
          {t('onboarding.services.skip')}
        </Button>
      </ScrollView>
    </Surface>
  );
}
