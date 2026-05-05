import { View, Modal, ScrollView, TouchableOpacity } from 'react-native';
import { X, Plus, Minus, Check } from 'lucide-react-native';
import { useEffect, useMemo, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { useRouter } from 'expo-router';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { Button } from '@/ui/primitives/button';
import { PressScale } from '@/ui/motion/press-scale';
import { useServices, useAnimalCategories, useSpecies } from '@/state/queries/species';
import type { TourStopService } from '@/domain/models/tour-stop-service';
import type { AnimalCount } from '@/domain/models/animal-count';
import { haptics } from '@/ui/motion/haptics';
import { useOnContrastColor, useForegroundColor } from '@/ui/theme/colors';
import { cn } from '@/lib/cn';
import { formatMinutes } from '@/lib/format-minutes';

function formatEur(cents: number | null): string {
  if (cents == null) return '—';
  return `${(cents / 100).toFixed(2)} €`;
}

interface Props {
  visible: boolean;
  clientAnimalCounts: AnimalCount[];
  initialSelection: TourStopService[];
  onConfirm: (services: TourStopService[]) => void;
  onClose: () => void;
}

interface SelectedEntry {
  qty: number;
}

export function ServicePickerSheet({
  visible,
  clientAnimalCounts,
  initialSelection,
  onConfirm,
  onClose,
}: Props) {
  const { t } = useTranslation();
  const router = useRouter();
  const onContrast = useOnContrastColor();
  const fg = useForegroundColor();
  const { data: services = [] } = useServices();
  const { data: categories = [] } = useAnimalCategories();
  const { data: species = [] } = useSpecies();

  const categoriesById = useMemo(
    () => new Map(categories.map((c) => [c.id, c])),
    [categories]
  );
  const speciesById = useMemo(
    () => new Map(species.map((s) => [s.id, s])),
    [species]
  );
  const countByCategoryId = useMemo(
    () => new Map(clientAnimalCounts.map((a) => [a.categoryId, a.count])),
    [clientAnimalCounts]
  );

  const active = useMemo(() => services.filter((p) => p.isActive), [services]);

  // Suggested = service whose category matches a client category with count > 0.
  const suggested = useMemo(
    () =>
      active.filter((p) => {
        if (!p.categoryId) return false;
        const c = countByCategoryId.get(p.categoryId);
        return typeof c === 'number' && c > 0;
      }),
    [active, countByCategoryId]
  );
  const suggestedIds = useMemo(() => new Set(suggested.map((p) => p.id)), [suggested]);
  const other = useMemo(() => active.filter((p) => !suggestedIds.has(p.id)), [active, suggestedIds]);

  const [selected, setSelected] = useState<Record<string, SelectedEntry>>({});
  const [hydrated, setHydrated] = useState(false);

  // Hydrate on first render where data is loaded. Auto-fill suggested with
  // qty from the client's animal count for that category.
  useEffect(() => {
    if (hydrated) return;
    // Wait for the services catalog to be present, otherwise `suggested`
    // is empty for the wrong reason and we lock the user in with no
    // pre-selection.
    if (services.length === 0) return;
    const next: Record<string, SelectedEntry> = {};
    for (const s of initialSelection) {
      next[s.serviceId] = { qty: s.qty };
    }
    for (const p of suggested) {
      if (next[p.id]) continue;
      const count = p.categoryId ? countByCategoryId.get(p.categoryId) ?? 1 : 1;
      next[p.id] = { qty: Math.max(1, count) };
    }
    setSelected(next);
    setHydrated(true);
  }, [
    hydrated,
    services.length,
    initialSelection,
    suggested,
    countByCategoryId,
  ]);

  const toggle = (id: string) => {
    void haptics.selection();
    setSelected((prev) => {
      const next = { ...prev };
      if (next[id]) delete next[id];
      else {
        const p = active.find((x) => x.id === id);
        const count =
          p?.categoryId ? countByCategoryId.get(p.categoryId) ?? 1 : 1;
        next[id] = { qty: Math.max(1, count) };
      }
      return next;
    });
  };

  const setQty = (id: string, qty: number) => {
    setSelected((prev) => {
      if (!prev[id]) return prev;
      return { ...prev, [id]: { qty: Math.max(1, qty) } };
    });
  };

  const buildService = (p: typeof active[number], qty: number): TourStopService => {
    const category = p.categoryId ? categoriesById.get(p.categoryId) : null;
    const sp = category ? speciesById.get(category.speciesId) : null;
    return {
      serviceId: p.id,
      qty,
      nameSnapshot: p.label,
      priceCentsSnapshot: p.priceCents ?? 0,
      minutesSnapshot: p.minutes,
      categoryIdSnapshot: p.categoryId,
      categoryNameSnapshot: category?.label ?? null,
      speciesNameSnapshot: sp?.label ?? null,
    };
  };

  const handleConfirm = () => {
    void haptics.success();
    const out: TourStopService[] = [];
    for (const p of active) {
      const sel = selected[p.id];
      if (!sel || sel.qty <= 0) continue;
      out.push(buildService(p, sel.qty));
    }
    onConfirm(out);
  };

  const ServiceRow = ({ item }: { item: typeof active[number] }) => {
    const sel = selected[item.id];
    const checked = !!sel;
    const category = item.categoryId ? categoriesById.get(item.categoryId) : null;
    const sp = category ? speciesById.get(category.speciesId) : null;
    return (
      <View className="flex-row items-center py-3 gap-3 border-b border-border dark:border-border-dark">
        <PressScale onPress={() => toggle(item.id)} accessibilityLabel={item.label}>
          <View
            className={cn(
              'w-6 h-6 rounded-md items-center justify-center border',
              checked
                ? 'bg-primary dark:bg-primary-dark border-primary dark:border-primary-dark'
                : 'border-border dark:border-border-dark'
            )}
          >
            {checked ? <Check size={14} color={onContrast} /> : null}
          </View>
        </PressScale>
        <View className="flex-1">
          <Text className="text-sm font-medium">{item.label}</Text>
          <Text variant="muted" className="text-xs">
            {[sp?.label, category?.label].filter(Boolean).join(' · ') || '—'}
          </Text>
          <Text variant="muted" className="text-xs">
            {formatEur(item.priceCents)} · {formatMinutes(item.minutes)}
          </Text>
        </View>
        {checked ? (
          <View className="flex-row items-center gap-2">
            <PressScale
              onPress={() => setQty(item.id, sel.qty - 1)}
              accessibilityLabel={t('common.decrement')}
            >
              <View className="w-8 h-8 rounded-full bg-muted dark:bg-muted-dark items-center justify-center">
                <Minus size={14} color={fg} />
              </View>
            </PressScale>
            <Text className="w-8 text-center font-semibold">{sel.qty}</Text>
            <PressScale
              onPress={() => setQty(item.id, sel.qty + 1)}
              accessibilityLabel={t('common.increment')}
            >
              <View className="w-8 h-8 rounded-full bg-muted dark:bg-muted-dark items-center justify-center">
                <Plus size={14} color={fg} />
              </View>
            </PressScale>
          </View>
        ) : null}
      </View>
    );
  };

  return (
    <Modal visible={visible} animationType="slide" transparent presentationStyle="overFullScreen">
      <TouchableOpacity
        style={{ flex: 1, backgroundColor: 'rgba(0,0,0,0.4)' }}
        onPress={onClose}
        activeOpacity={1}
      />
      <Surface className="rounded-t-3xl" style={{ maxHeight: '80%' }}>
        <View className="flex-row items-center justify-between px-4 pt-4 pb-2">
          <Text className="text-lg font-semibold">{t('tours.add_service')}</Text>
          <PressScale onPress={onClose} accessibilityLabel={t('common.close')}>
            <X size={22} color="#5C4E40" />
          </PressScale>
        </View>

        <ScrollView contentContainerStyle={{ paddingHorizontal: 16, paddingBottom: 16 }}>
          {active.length === 0 ? (
            <View className="items-center py-8 gap-3">
              <Text className="text-base font-semibold">{t('tours.picker_empty_title')}</Text>
              <Text variant="muted" className="text-center text-sm">
                {t('tours.picker_empty_message')}
              </Text>
              <Button
                variant="primary"
                onPress={() => {
                  onClose();
                  router.push('/(tabs)/settings/services' as never);
                }}
                accessibilityLabel={t('tours.picker_empty_cta')}
              >
                <Text variant="onPrimary" className="font-semibold">
                  {t('tours.picker_empty_cta')}
                </Text>
              </Button>
            </View>
          ) : (
            <>
              {suggested.length > 0 ? (
                <>
                  <Text variant="muted" className="text-xs font-semibold uppercase tracking-widest py-2">
                    {t('tours.picker_suggested')}
                  </Text>
                  {suggested.map((p) => <ServiceRow key={p.id} item={p} />)}
                </>
              ) : null}

              {other.length > 0 ? (
                <>
                  <Text variant="muted" className="text-xs font-semibold uppercase tracking-widest py-2 mt-2">
                    {t('tours.picker_other')}
                  </Text>
                  {other.map((p) => <ServiceRow key={p.id} item={p} />)}
                </>
              ) : null}
            </>
          )}
        </ScrollView>

        {active.length > 0 ? (
          <View className="px-4 pt-2 pb-6 border-t border-border dark:border-border-dark">
            <Button onPress={handleConfirm} accessibilityLabel={t('tours.picker_confirm')}>
              <Text variant="onPrimary" className="font-semibold">
                {t('tours.picker_confirm')}
              </Text>
            </Button>
          </View>
        ) : null}
      </Surface>
    </Modal>
  );
}
