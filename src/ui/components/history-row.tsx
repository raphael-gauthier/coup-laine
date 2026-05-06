import { View } from 'react-native';
import { ChevronRight, Calendar, Pencil } from 'lucide-react-native';
import { useTranslation } from 'react-i18next';
import { format, parseISO } from 'date-fns';
import { fr } from 'date-fns/locale';

import { PressScale } from '@/ui/motion/press-scale';
import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { haptics } from '@/ui/motion/haptics';
import { cn } from '@/lib/cn';
import type { Intervention } from '@/domain/models/intervention';

interface Props {
  entry: Intervention;
  onPress: () => void;
}

const SOURCE_BG = {
  tour: 'bg-shorn dark:bg-shorn-dark',
  manual: 'bg-muted dark:bg-muted-dark',
} as const;
const SOURCE_TEXT = {
  tour: 'text-primary-foreground dark:text-primary-dark-foreground',
  manual: 'text-muted-foreground dark:text-muted-dark-foreground',
} as const;

export function HistoryRow({ entry, onPress }: Props) {
  const { t } = useTranslation();
  const dateLabel = format(parseISO(`${entry.date}T00:00:00`), 'PPP', { locale: fr });

  const servicesCents = entry.services.reduce(
    (sum, s) => sum + (s.qty > 0 ? s.qty * s.priceCentsSnapshot : 0),
    0
  );
  const totalCents = servicesCents + (entry.travelFeeCents ?? 0);

  return (
    <PressScale
      onPress={() => {
        void haptics.selection();
        onPress();
      }}
      accessibilityLabel={dateLabel}
    >
      <Surface variant="muted" className="flex-row items-center rounded-2xl px-4 py-3 gap-3">
        <View className="flex-1">
          <View className="flex-row items-center gap-2">
            <View className={cn('px-2 py-0.5 rounded-full', SOURCE_BG[entry.source])}>
              <Text className={cn('text-xs font-semibold', SOURCE_TEXT[entry.source])}>
                {t(`history.source_${entry.source}`)}
              </Text>
            </View>
          </View>
          <View className="flex-row items-center gap-1 mt-1">
            <Calendar size={14} color="#5C4E40" />
            <Text className="font-semibold">{dateLabel}</Text>
          </View>
          {entry.notes ? (
            <Text variant="muted" className="text-sm mt-1" numberOfLines={2}>{entry.notes}</Text>
          ) : null}
        </View>
        {totalCents > 0 ? (
          <Text className="text-sm font-semibold">
            {(totalCents / 100).toFixed(0)} €
          </Text>
        ) : null}
        {entry.source === 'manual' ? (
          <Pencil size={16} color="#5C4E40" />
        ) : (
          <ChevronRight size={18} color="#5C4E40" />
        )}
      </Surface>
    </PressScale>
  );
}
