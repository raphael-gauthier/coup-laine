import { View } from 'react-native';
import { ChevronRight, Calendar, FileText } from 'lucide-react-native';
import { useTranslation } from 'react-i18next';
import { format, parseISO, formatDistanceToNow } from 'date-fns';
import { fr } from 'date-fns/locale';
import { PressScale } from '@/ui/motion/press-scale';
import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { haptics } from '@/ui/motion/haptics';
import type { Tour, TourStatus } from '@/domain/models/tour';
import { useTourKpis } from '@/state/queries/kpis';
import { formatMinutes } from '@/lib/format-minutes';
import { cn } from '@/lib/cn';

interface Props {
  tour: Tour;
  stopCount: number;
  onPress: () => void;
}

const STATUS_BG: Record<TourStatus, string> = {
  draft: 'bg-muted dark:bg-muted-dark',
  planned: 'bg-waiting dark:bg-waiting-dark',
  completed: 'bg-shorn dark:bg-shorn-dark',
};
const STATUS_TEXT: Record<TourStatus, string> = {
  draft: 'text-muted-foreground dark:text-muted-dark-foreground',
  planned: 'text-primary-foreground dark:text-primary-dark-foreground',
  completed: 'text-primary-foreground dark:text-primary-dark-foreground',
};

function formatEur(cents: number): string {
  return `${(cents / 100).toFixed(0)} €`;
}

export function TourCard({ tour, stopCount, onPress }: Props) {
  const { t } = useTranslation();
  const kpisQuery = useTourKpis(tour.status === 'draft' ? undefined : tour.id);
  const kpis = kpisQuery.data;

  if (tour.status === 'draft') {
    const titleDisplay = tour.title ?? t('tours.draft_fallback_title', {
      date: format(parseISO(tour.createdAt), 'd MMM', { locale: fr }),
    });
    const modifiedAt = formatDistanceToNow(parseISO(tour.updatedAt), { locale: fr, addSuffix: true });

    return (
      <PressScale
        onPress={() => {
          void haptics.selection();
          onPress();
        }}
        accessibilityLabel={titleDisplay}
      >
        <Surface variant="muted" className="rounded-2xl px-4 py-3 gap-2">
          <View className="flex-row items-center justify-between">
            <View className={cn('px-2 py-0.5 rounded-full', STATUS_BG.draft)}>
              <Text className={cn('text-xs font-semibold', STATUS_TEXT.draft)}>
                {t('tours.draft_status_label')}
              </Text>
            </View>
            <ChevronRight size={18} color="#5C4E40" />
          </View>
          <View className="flex-row items-center gap-1">
            <FileText size={14} color="#5C4E40" />
            <Text className="font-semibold">{titleDisplay}</Text>
          </View>
          <Text variant="muted" className="text-xs">
            {t('tours.stop_summary_count_label', { count: stopCount })} · {t('tours.draft_modified_at', { when: modifiedAt })}
          </Text>
        </Surface>
      </PressScale>
    );
  }

  // planned / completed (existing rendering, kept identical)
  const dateString = tour.scheduledDate && tour.departureTime
    ? format(parseISO(`${tour.scheduledDate}T${tour.departureTime}:00`), 'PPPp', { locale: fr })
    : '';

  return (
    <PressScale
      onPress={() => {
        void haptics.selection();
        onPress();
      }}
      accessibilityLabel={dateString}
    >
      <Surface variant="muted" className="rounded-2xl px-4 py-3 gap-2">
        <View className="flex-row items-center justify-between">
          <View className="flex-row items-center gap-2">
            <View className={cn('px-2 py-0.5 rounded-full', STATUS_BG[tour.status])}>
              <Text className={cn('text-xs font-semibold', STATUS_TEXT[tour.status])}>
                {t(`tours.status_${tour.status}`)}
              </Text>
            </View>
          </View>
          <ChevronRight size={18} color="#5C4E40" />
        </View>

        <View className="flex-row items-center gap-1">
          <Calendar size={14} color="#5C4E40" />
          <Text className="font-semibold">{dateString}</Text>
        </View>

        {kpis ? (
          <View className="flex-row flex-wrap gap-x-3 gap-y-1">
            <Text variant="muted" className="text-xs">
              {t('tours.stops_count', { count: kpis.stopCount })}
            </Text>
            <Text variant="muted" className="text-xs">
              {kpis.animalsTotal} {t('tours.kpi_animals')}
            </Text>
            <Text variant="muted" className="text-xs">
              {kpis.distanceKm.toFixed(1)} km
            </Text>
            <Text variant="muted" className="text-xs">
              {formatMinutes(kpis.durationMinutes)}
              {kpis.driveMinutes > 0 ? ` (+${formatMinutes(kpis.driveMinutes)} ${t('tours.kpi_drive')})` : ''}
            </Text>
            <Text variant="muted" className="text-xs">
              {formatEur(kpis.revenueCents)}
            </Text>
            {kpis.travelFeeCents > 0 ? (
              <Text variant="muted" className="text-xs">
                {t('tours.kpi_travel_fees')}: {formatEur(kpis.travelFeeCents)}
              </Text>
            ) : null}
          </View>
        ) : (
          <Text variant="muted" className="text-xs">
            {t('tours.stops_count', { count: stopCount })}
          </Text>
        )}
      </Surface>
    </PressScale>
  );
}
