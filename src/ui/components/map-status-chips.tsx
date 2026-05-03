import { ScrollView, View } from 'react-native';
import { useTranslation } from 'react-i18next';
import { PressScale } from '@/ui/motion/press-scale';
import { Text } from '@/ui/primitives/text';
import { cn } from '@/lib/cn';
import { useMapFiltersStore, type MapFilter } from '@/state/ui/map-filters-store';
import { useMapKpis } from '@/state/queries/kpis';
import { haptics } from '@/ui/motion/haptics';

type ChipDef = { filter: MapFilter; labelKey: string; count: number };

export function MapStatusChips() {
  const { t } = useTranslation();
  const { activeFilter, setFilter } = useMapFiltersStore();
  const { data: kpis } = useMapKpis();

  const chips: ChipDef[] = [
    { filter: 'all',       labelKey: 'map.chip_all',        count: kpis?.total ?? 0 },
    { filter: 'waiting',   labelKey: 'map.chip_waiting',    count: kpis?.waiting ?? 0 },
    { filter: 'scheduled', labelKey: 'map.chip_scheduled',  count: kpis?.scheduled ?? 0 },
    { filter: 'done',      labelKey: 'map.chip_done',       count: kpis?.done ?? 0 },
    { filter: 'noAnimals', labelKey: 'map.chip_no_animals', count: kpis?.noAnimals ?? 0 },
    { filter: 'banned',    labelKey: 'map.chip_banned',     count: kpis?.banned ?? 0 },
  ];

  return (
    <ScrollView
      horizontal
      showsHorizontalScrollIndicator={false}
      contentContainerStyle={{ paddingHorizontal: 12, paddingVertical: 8, gap: 8 }}
    >
      {chips.map(({ filter, labelKey, count }) => {
        const active = activeFilter === filter;
        return (
          <PressScale
            key={filter}
            onPress={() => {
              void haptics.selection();
              setFilter(filter);
            }}
          >
            <View
              className={cn(
                'flex-row items-center gap-1 px-3 py-1.5 rounded-full border',
                active
                  ? 'bg-primary dark:bg-primary-dark border-primary dark:border-primary-dark'
                  : 'bg-background dark:bg-background-dark border-border dark:border-border-dark'
              )}
            >
              <Text
                className={cn(
                  'text-xs font-semibold',
                  active
                    ? 'text-primary-foreground dark:text-primary-dark-foreground'
                    : 'text-foreground dark:text-foreground-dark'
                )}
              >
                {t(labelKey)}
              </Text>
              <Text
                className={cn(
                  'text-xs',
                  active
                    ? 'text-primary-foreground dark:text-primary-dark-foreground'
                    : 'text-muted-foreground dark:text-muted-dark-foreground'
                )}
              >
                {count}
              </Text>
            </View>
          </PressScale>
        );
      })}
    </ScrollView>
  );
}
