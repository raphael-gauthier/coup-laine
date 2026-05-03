import { View } from 'react-native';
import { ChevronRight, Calendar } from 'lucide-react-native';
import { useTranslation } from 'react-i18next';
import { format, parseISO } from 'date-fns';
import { fr } from 'date-fns/locale';
import { PressScale } from '@/ui/motion/press-scale';
import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { haptics } from '@/ui/motion/haptics';
import type { Tour, TourStatus } from '@/domain/models/tour';
import { cn } from '@/lib/cn';

interface Props {
  tour: Tour;
  stopCount: number;
  onPress: () => void;
}

const STATUS_BG: Record<TourStatus, string> = {
  planned: 'bg-waiting dark:bg-waiting-dark',
  completed: 'bg-shorn dark:bg-shorn-dark',
};
const STATUS_TEXT: Record<TourStatus, string> = {
  planned: 'text-primary-foreground dark:text-primary-dark-foreground',
  completed: 'text-primary-foreground dark:text-primary-dark-foreground',
};

export function TourCard({ tour, stopCount, onPress }: Props) {
  const { t } = useTranslation();
  const date = format(parseISO(`${tour.scheduledDate}T${tour.departureTime}:00`), 'PPPp', { locale: fr });

  return (
    <PressScale
      onPress={() => {
        void haptics.selection();
        onPress();
      }}
    >
      <Surface variant="muted" className="flex-row items-center rounded-2xl px-4 py-3 gap-3">
        <View className="flex-1">
          <View className="flex-row items-center gap-2">
            <View className={cn('px-2 py-0.5 rounded-full', STATUS_BG[tour.status])}>
              <Text className={cn('text-xs font-semibold', STATUS_TEXT[tour.status])}>
                {t(`tours.status_${tour.status}`)}
              </Text>
            </View>
            <Text variant="muted" className="text-xs">
              {t('tours.stops_count', { count: stopCount })}
            </Text>
          </View>
          <View className="flex-row items-center gap-1 mt-1">
            <Calendar size={14} color="#5C4E40" />
            <Text className="font-semibold">{date}</Text>
          </View>
        </View>
        <ChevronRight size={18} color="#5C4E40" />
      </Surface>
    </PressScale>
  );
}
