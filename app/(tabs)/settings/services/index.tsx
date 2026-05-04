import { useMemo, useState } from 'react';
import { View, ScrollView, TouchableOpacity } from 'react-native';
import { useRouter } from 'expo-router';
import { Plus, ChevronRight, ChevronDown } from 'lucide-react-native';
import { useTranslation } from 'react-i18next';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { SectionHeader } from '@/ui/primitives/section-header';
import { PressScale } from '@/ui/motion/press-scale';
import { ErrorState } from '@/ui/components/error-state';
import { ScreenHeader } from '@/ui/components/screen-header';
import { useServices, useAnimalCategories, useSpecies } from '@/state/queries/species';
import { haptics } from '@/ui/motion/haptics';
import { useOnContrastColor } from '@/ui/theme/colors';
import { formatMinutes } from '@/lib/format-minutes';

export default function ServicesListScreen() {
  const { t } = useTranslation();
  const router = useRouter();
  const onContrast = useOnContrastColor();
  const { data: services = [], isError, refetch } = useServices();
  const { data: categories = [] } = useAnimalCategories();
  const { data: speciesList = [] } = useSpecies();

  const [archivedExpanded, setArchivedExpanded] = useState(false);

  const grouped = useMemo(() => {
    const categoriesById = new Map(categories.map((c) => [c.id, c]));
    const speciesById = new Map(speciesList.map((s) => [s.id, s]));

    // active services with a category
    const withCategory = services.filter((p) => p.isActive && p.categoryId);
    // active services without a category
    const noCategory = services.filter((p) => p.isActive && !p.categoryId);
    // archived services
    const archived = services.filter((p) => !p.isActive);

    // Group by species
    const bySpecies = new Map<string, { speciesLabel: string; categories: Map<string, { catLabel: string; items: typeof services }> }>();

    for (const p of withCategory) {
      const cat = categoriesById.get(p.categoryId!);
      if (!cat) continue;
      const sp = speciesById.get(cat.speciesId);
      if (!sp) continue;

      if (!bySpecies.has(sp.id)) {
        bySpecies.set(sp.id, { speciesLabel: sp.label, categories: new Map() });
      }
      const spGroup = bySpecies.get(sp.id)!;
      if (!spGroup.categories.has(cat.id)) {
        spGroup.categories.set(cat.id, { catLabel: cat.label, items: [] });
      }
      spGroup.categories.get(cat.id)!.items.push(p);
    }

    return { bySpecies, noCategory, archived };
  }, [services, categories, speciesList]);

  if (isError) return <ErrorState onRetry={() => refetch()} />;

  return (
    <Surface className="flex-1">
      <ScreenHeader title={t('catalogs.services.list_title')} />
      <ScrollView contentContainerStyle={{ paddingHorizontal: 16, paddingBottom: 96 }}>

        {Array.from(grouped.bySpecies.entries()).map(([spId, spGroup]) => (
          <View key={spId}>
            <SectionHeader title={spGroup.speciesLabel} />
            {Array.from(spGroup.categories.entries()).map(([catId, catGroup]) => (
              <View key={catId} className="mb-2">
                <Text variant="muted" className="text-xs font-medium px-1 mb-1">{catGroup.catLabel}</Text>
                {catGroup.items.map((item) => (
                  <ServiceRow key={item.id} item={item} onPress={() => {
                    void haptics.selection();
                    router.push(`/(tabs)/settings/services/${item.id}` as never);
                  }} />
                ))}
              </View>
            ))}
          </View>
        ))}

        {grouped.noCategory.length > 0 ? (
          <View>
            <SectionHeader title={t('catalogs.services.no_category')} />
            {grouped.noCategory.map((item) => (
              <ServiceRow key={item.id} item={item} onPress={() => {
                void haptics.selection();
                router.push(`/(tabs)/settings/services/${item.id}` as never);
              }} />
            ))}
          </View>
        ) : null}

        {grouped.archived.length > 0 ? (
          <View>
            <TouchableOpacity onPress={() => setArchivedExpanded(!archivedExpanded)}>
              <View className="flex-row items-center justify-between pt-4 pb-1 px-1">
                <Text variant="muted" className="text-xs font-semibold uppercase tracking-widest">
                  {t('catalogs.services.archived_section')} ({grouped.archived.length})
                </Text>
                {archivedExpanded ? <ChevronDown size={14} color="#5C4E40" /> : <ChevronRight size={14} color="#5C4E40" />}
              </View>
            </TouchableOpacity>
            {archivedExpanded ? grouped.archived.map((item) => (
              <ServiceRow key={item.id} item={item} onPress={() => {
                void haptics.selection();
                router.push(`/(tabs)/settings/services/${item.id}` as never);
              }} />
            )) : null}
          </View>
        ) : null}

      </ScrollView>

      {/* FAB */}
      <PressScale
        onPress={() => {
          void haptics.selection();
          router.push('/(tabs)/settings/services/new' as never);
        }}
        style={{ position: 'absolute', bottom: 24, right: 24 }}
      >
        <Surface
          variant="primary"
          className="rounded-full p-4"
          style={{ shadowColor: '#000', shadowOpacity: 0.2, shadowRadius: 6, elevation: 6 }}
        >
          <Plus size={24} color={onContrast} />
        </Surface>
      </PressScale>
    </Surface>
  );
}

function ServiceRow({ item, onPress }: { item: { label: string; priceCents: number | null; minutes: number; isActive: boolean }; onPress: () => void }) {
  const { t } = useTranslation();
  const priceStr = item.priceCents != null ? `${(item.priceCents / 100).toFixed(2)} €` : '—';
  return (
    <PressScale onPress={onPress}>
      <Surface variant="muted" className="flex-row items-center rounded-2xl px-4 py-3 gap-3 mb-2">
        <View className="flex-1">
          <Text className="font-semibold">{item.label}</Text>
          <Text variant="muted" className="text-xs">{priceStr} · {formatMinutes(item.minutes)}</Text>
          {!item.isActive ? (
            <Text variant="muted" className="text-xs mt-0.5">{t('catalogs.services.inactive_badge')}</Text>
          ) : null}
        </View>
        <ChevronRight size={18} color="#5C4E40" />
      </Surface>
    </PressScale>
  );
}
