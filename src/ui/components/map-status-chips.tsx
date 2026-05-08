import { ScrollView, View } from 'react-native';
import Svg, { Defs, LinearGradient, Stop, Rect } from 'react-native-svg';
import { ChevronsRight } from 'lucide-react-native';
import { useTranslation } from 'react-i18next';
import { PressScale } from '@/ui/motion/press-scale';
import { Text } from '@/ui/primitives/text';
import { cn } from '@/lib/cn';
import { useMapFiltersStore } from '@/state/ui/map-filters-store';
import { useMapKpis } from '@/state/queries/kpis';
import { useStatusRegistry } from '@/state/queries/statuses';
import { useResolvedColorScheme } from '@/ui/theme/theme-provider';
import { haptics } from '@/ui/motion/haptics';

const FADE_WIDTH = 48;
const BG_HEX = { light: '#FAF6F0', dark: '#16120F' };
const CHEVRON_HEX = { light: '#5C4E40', dark: '#B4A490' };

export function MapStatusChips() {
  const { t } = useTranslation();
  const { activeFilter, setFilter } = useMapFiltersStore();
  const { data: kpis } = useMapKpis();
  const { data: registry } = useStatusRegistry();
  const scheme = useResolvedColorScheme();
  const bgHex = BG_HEX[scheme];

  const all = registry?.list ?? [];
  const total = all.reduce((acc, s) => acc + (kpis?.get(s.id) ?? 0), 0);

  return (
    <View style={{ position: 'relative' }}>
      <ScrollView
        horizontal
        showsHorizontalScrollIndicator={false}
        style={{ flexGrow: 0 }}
        contentContainerStyle={{ paddingHorizontal: 12, paddingVertical: 8, paddingRight: FADE_WIDTH + 12, gap: 8 }}
      >
        {/* "Tous" pseudo-chip */}
        <PressScale
          key="__all"
          onPress={() => { void haptics.selection(); setFilter(null); }}
          accessibilityLabel={t('map.chip_all')}
        >
          <View
            className={cn(
              'flex-row items-center gap-1.5 px-4 py-2 rounded-full border',
              activeFilter === null
                ? 'bg-primary dark:bg-primary-dark border-primary dark:border-primary-dark'
                : 'bg-background dark:bg-background-dark border-border dark:border-border-dark',
            )}
          >
            <Text className={cn(
              'text-sm font-semibold',
              activeFilter === null
                ? 'text-primary-foreground dark:text-primary-dark-foreground'
                : 'text-foreground dark:text-foreground-dark',
            )}>{t('map.chip_all')}</Text>
            <Text className={cn(
              'text-sm',
              activeFilter === null
                ? 'text-primary-foreground dark:text-primary-dark-foreground'
                : 'text-muted-foreground dark:text-muted-dark-foreground',
            )}>{total}</Text>
          </View>
        </PressScale>

        {all.map((s) => {
          const active = activeFilter === s.id;
          const count = kpis?.get(s.id) ?? 0;
          const dotHex = scheme === 'dark' ? s.colorDark : s.colorLight;
          return (
            <PressScale
              key={s.id}
              onPress={() => { void haptics.selection(); setFilter(s.id); }}
              accessibilityLabel={s.label}
            >
              <View
                className={cn(
                  'flex-row items-center gap-1.5 px-4 py-2 rounded-full border',
                  active
                    ? 'bg-primary dark:bg-primary-dark border-primary dark:border-primary-dark'
                    : 'bg-background dark:bg-background-dark border-border dark:border-border-dark',
                )}
              >
                <View style={{ width: 10, height: 10, borderRadius: 5, backgroundColor: dotHex }} />
                <Text className={cn(
                  'text-sm font-semibold',
                  active
                    ? 'text-primary-foreground dark:text-primary-dark-foreground'
                    : 'text-foreground dark:text-foreground-dark',
                )}>{s.label}</Text>
                <Text className={cn(
                  'text-sm',
                  active
                    ? 'text-primary-foreground dark:text-primary-dark-foreground'
                    : 'text-muted-foreground dark:text-muted-dark-foreground',
                )}>{count}</Text>
              </View>
            </PressScale>
          );
        })}
      </ScrollView>

      <View
        pointerEvents="none"
        style={{ position: 'absolute', right: 0, top: 0, bottom: 0, width: FADE_WIDTH, justifyContent: 'center', alignItems: 'flex-end', paddingRight: 4 }}
      >
        <Svg width={FADE_WIDTH} height="100%" style={{ position: 'absolute', right: 0, top: 0, bottom: 0 }}>
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
