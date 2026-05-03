import { View, Modal, ScrollView, TouchableOpacity } from 'react-native';
import { X, Plus } from 'lucide-react-native';
import { useMemo } from 'react';
import { useTranslation } from 'react-i18next';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { Button } from '@/ui/primitives/button';
import { PressScale } from '@/ui/motion/press-scale';
import { usePrestations, useAnimalCategories, useSpecies } from '@/state/queries/species';
import type { TourStopPrestation } from '@/domain/models/tour-stop-prestation';
import type { AnimalCount } from '@/domain/models/animal-count';
import { haptics } from '@/ui/motion/haptics';

function formatEur(cents: number | null): string {
  if (cents == null) return '—';
  return `${(cents / 100).toFixed(2)} €`;
}

interface Props {
  visible: boolean;
  clientAnimalCounts: AnimalCount[];
  onAdd: (prestation: TourStopPrestation) => void;
  onClose: () => void;
}

export function PrestationPickerSheet({ visible, clientAnimalCounts, onAdd, onClose }: Props) {
  const { t } = useTranslation();
  const { data: prestations = [] } = usePrestations();
  const { data: categories = [] } = useAnimalCategories();
  const { data: species = [] } = useSpecies();

  const clientCategoryIds = new Set(clientAnimalCounts.map((a) => a.categoryId));

  const categoriesById = useMemo(
    () => new Map(categories.map((c) => [c.id, c])),
    [categories]
  );
  const speciesById = useMemo(
    () => new Map(species.map((s) => [s.id, s])),
    [species]
  );

  const active = prestations.filter((p) => p.isActive);

  const suggested = active.filter((p) => p.categoryId && clientCategoryIds.has(p.categoryId));
  const other = active.filter((p) => !p.categoryId || !clientCategoryIds.has(p.categoryId));

  const buildPrestation = (p: typeof prestations[number]): TourStopPrestation => {
    const category = p.categoryId ? categoriesById.get(p.categoryId) : null;
    const sp = category ? speciesById.get(category.speciesId) : null;
    return {
      prestationId: p.id,
      qty: 1,
      nameSnapshot: p.label,
      priceCentsSnapshot: p.priceCents ?? 0,
      minutesSnapshot: p.minutes,
      categoryIdSnapshot: p.categoryId,
      categoryNameSnapshot: category?.label ?? null,
      speciesNameSnapshot: sp?.label ?? null,
    };
  };

  const handleAdd = (p: typeof prestations[number]) => {
    void haptics.selection();
    onAdd(buildPrestation(p));
  };

  const PrestationRow = ({ item }: { item: typeof prestations[number] }) => (
    <View className="flex-row items-center justify-between py-2 border-b border-border dark:border-border-dark">
      <View className="flex-1 pr-2">
        <Text className="text-sm font-medium">{item.label}</Text>
        <Text variant="muted" className="text-xs">
          {formatEur(item.priceCents)} · {item.minutes} min
        </Text>
      </View>
      <PressScale onPress={() => handleAdd(item)}>
        <View className="w-8 h-8 rounded-full bg-primary dark:bg-primary-dark items-center justify-center">
          <Plus size={16} color="white" />
        </View>
      </PressScale>
    </View>
  );

  return (
    <Modal visible={visible} animationType="slide" transparent presentationStyle="overFullScreen">
      <TouchableOpacity
        style={{ flex: 1, backgroundColor: 'rgba(0,0,0,0.4)' }}
        onPress={onClose}
        activeOpacity={1}
      />
      <Surface className="rounded-t-3xl" style={{ maxHeight: '70%' }}>
        <View className="flex-row items-center justify-between px-4 pt-4 pb-2">
          <Text className="text-lg font-semibold">{t('tours.add_prestation')}</Text>
          <PressScale onPress={onClose}>
            <X size={22} color="#5C4E40" />
          </PressScale>
        </View>

        <ScrollView contentContainerStyle={{ paddingHorizontal: 16, paddingBottom: 32 }}>
          {suggested.length > 0 ? (
            <>
              <Text variant="muted" className="text-xs font-semibold uppercase tracking-widest py-2">
                {t('tours.picker_suggested')}
              </Text>
              {suggested.map((p) => <PrestationRow key={p.id} item={p} />)}
            </>
          ) : null}

          {other.length > 0 ? (
            <>
              <Text variant="muted" className="text-xs font-semibold uppercase tracking-widest py-2 mt-2">
                {t('tours.picker_other')}
              </Text>
              {other.map((p) => <PrestationRow key={p.id} item={p} />)}
            </>
          ) : null}
        </ScrollView>
      </Surface>
    </Modal>
  );
}
