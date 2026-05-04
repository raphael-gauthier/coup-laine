import { ScrollView, View } from 'react-native';
import Svg, { Defs, LinearGradient, Stop, Rect } from 'react-native-svg';
import { ChevronsRight } from 'lucide-react-native';
import { useTranslation } from 'react-i18next';
import { PressScale } from '@/ui/motion/press-scale';
import { Text } from '@/ui/primitives/text';
import { cn } from '@/lib/cn';
import { useMapFiltersStore, type MapFilter } from '@/state/ui/map-filters-store';
import { useMapKpis } from '@/state/queries/kpis';
import { useResolvedColorScheme } from '@/ui/theme/theme-provider';
import { haptics } from '@/ui/motion/haptics';

const FADE_WIDTH = 48;
const BG_HEX = { light: '#FAF6F0', dark: '#16120F' };
const CHEVRON_HEX = { light: '#5C4E40', dark: '#B4A490' };

type ChipDef = { filter: MapFilter; labelKey: string; count: number };

export function MapStatusChips() {
  const { t } = useTranslation();
  const { activeFilter, setFilter } = useMapFiltersStore();
  const { data: kpis } = useMapKpis();
  const scheme = useResolvedColorScheme();
  const bgHex = BG_HEX[scheme];

  const chips: ChipDef[] = [
    { filter: 'all',       labelKey: 'map.chip_all',        count: kpis?.total ?? 0 },
    { filter: 'waiting',   labelKey: 'map.chip_waiting',    count: kpis?.waiting ?? 0 },
    { filter: 'scheduled', labelKey: 'map.chip_scheduled',  count: kpis?.scheduled ?? 0 },
    { filter: 'done',      labelKey: 'map.chip_done',       count: kpis?.done ?? 0 },
    { filter: 'noAnimals', labelKey: 'map.chip_no_animals', count: kpis?.noAnimals ?? 0 },
    { filter: 'banned',    labelKey: 'map.chip_banned',     count: kpis?.banned ?? 0 },
  ];

  return (
    <View style={{ position: 'relative' }}>
      <ScrollView
        horizontal
        showsHorizontalScrollIndicator={false}
        style={{ flexGrow: 0 }}
        contentContainerStyle={{ paddingHorizontal: 12, paddingVertical: 8, paddingRight: FADE_WIDTH + 12, gap: 8 }}
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

      {/* Right-edge fade + chevron indicating more content */}
      <View
        pointerEvents="none"
        style={{ position: 'absolute', right: 0, top: 0, bottom: 0, width: FADE_WIDTH, justifyContent: 'center', alignItems: 'flex-end', paddingRight: 4 }}
      >
        <Svg
          width={FADE_WIDTH}
          height="100%"
          style={{ position: 'absolute', right: 0, top: 0, bottom: 0 }}
        >
          <Defs>
            <LinearGradient id="chipsFade" x1="0" y1="0" x2="1" y2="0">
              <Stop offset="0" stopColor={bgHex} stopOpacity={0} />
              <Stop offset="0.6" stopColor={bgHex} stopOpacity={1} />
              <Stop offset="1" stopColor={bgHex} stopOpacity={1} />
            </LinearGradient>
          </Defs>
          <Rect x={0} y={0} width={FADE_WIDTH} height="100%" fill="url(#chipsFade)" />
        </Svg>
        <ChevronsRight size={14} color={CHEVRON_HEX[scheme]} opacity={0.5} />
      </View>
    </View>
  );
}
