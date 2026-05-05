import { Modal, ScrollView, TouchableOpacity, View } from 'react-native';
import { X } from 'lucide-react-native';
import { useMemo } from 'react';
import { useTranslation } from 'react-i18next';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { PressScale } from '@/ui/motion/press-scale';
import { useServices, useAnimalCategories, useSpecies } from '@/state/queries/species';
import type { Service } from '@/domain/models/service';
import { formatMinutes } from '@/lib/format-minutes';
import { useForegroundColor } from '@/ui/theme/colors';

function formatEur(cents: number | null): string {
  if (cents == null) return '—';
  return `${(cents / 100).toFixed(2)} €/u`;
}

interface Props {
  visible: boolean;
  excludedServiceIds: string[];
  onPick: (service: Service) => void;
  onClose: () => void;
}

export function OffPlanServicePicker({ visible, excludedServiceIds, onPick, onClose }: Props) {
  const { t } = useTranslation();
  const fg = useForegroundColor();
  const { data: services = [] } = useServices();
  const { data: categories = [] } = useAnimalCategories();
  const { data: speciesList = [] } = useSpecies();

  const categoriesById = useMemo(() => new Map(categories.map((c) => [c.id, c])), [categories]);
  const speciesById = useMemo(() => new Map(speciesList.map((s) => [s.id, s])), [speciesList]);

  const candidates = useMemo(() => {
    const excluded = new Set(excludedServiceIds);
    return services.filter((s) => s.isActive && !excluded.has(s.id));
  }, [services, excludedServiceIds]);

  return (
    <Modal visible={visible} animationType="slide" transparent presentationStyle="overFullScreen">
      <TouchableOpacity
        style={{ flex: 1, backgroundColor: 'rgba(0,0,0,0.4)' }}
        onPress={onClose}
        activeOpacity={1}
      />
      <Surface className="rounded-t-3xl" style={{ maxHeight: '70%' }}>
        <View className="flex-row items-center justify-between px-4 pt-4 pb-2">
          <Text className="text-lg font-semibold">{t('tours.bilan_off_plan_picker_title')}</Text>
          <PressScale onPress={onClose}>
            <X size={22} color={fg} />
          </PressScale>
        </View>

        <ScrollView contentContainerStyle={{ paddingHorizontal: 16, paddingBottom: 24, gap: 8 }}>
          {candidates.length === 0 ? (
            <Text variant="muted" className="text-sm py-8 text-center">
              {t('tours.bilan_off_plan_empty')}
            </Text>
          ) : (
            candidates.map((p) => {
              const category = p.categoryId ? categoriesById.get(p.categoryId) : null;
              const sp = category ? speciesById.get(category.speciesId) : null;
              const subtitle = [sp?.label, category?.label].filter(Boolean).join(' · ');
              return (
                <PressScale key={p.id} onPress={() => onPick(p)}>
                  <Surface variant="muted" className="rounded-2xl px-4 py-3 gap-1">
                    <Text className="text-sm font-semibold">{p.label}</Text>
                    <Text variant="muted" className="text-xs">
                      {subtitle ? `${subtitle} · ` : ''}{formatEur(p.priceCents)} · {formatMinutes(p.minutes)}
                    </Text>
                  </Surface>
                </PressScale>
              );
            })
          )}
        </ScrollView>
      </Surface>
    </Modal>
  );
}
