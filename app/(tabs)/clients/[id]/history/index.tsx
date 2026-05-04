import { View } from 'react-native';
import { useLocalSearchParams, useRouter } from 'expo-router';
import { FlashList } from '@shopify/flash-list';
import Animated, { FadeIn, FadeOut, LinearTransition } from 'react-native-reanimated';
import { Plus, History as HistoryIcon } from 'lucide-react-native';
import { useTranslation } from 'react-i18next';

import { motion } from '@/ui/motion/motion-tokens';
import { PressScale } from '@/ui/motion/press-scale';
import { haptics } from '@/ui/motion/haptics';
import { Surface } from '@/ui/primitives/surface';
import { EmptyState } from '@/ui/components/empty-state';
import { ErrorState } from '@/ui/components/error-state';
import { HistoryRow } from '@/ui/components/history-row';
import { ScreenHeader } from '@/ui/components/screen-header';
import { useClientHistory } from '@/state/queries/history';
import { useOnContrastColor } from '@/ui/theme/colors';

export default function ClientHistoryScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const router = useRouter();
  const { t } = useTranslation();
  const onContrast = useOnContrastColor();
  const { data: entries = [], isError, refetch } = useClientHistory(id);

  if (isError) return <ErrorState onRetry={() => refetch()} />;

  return (
    <Surface className="flex-1">
      <ScreenHeader title={t('history.title')} />
      {entries.length === 0 ? (
        <EmptyState
          icon={<HistoryIcon size={48} color="#5C4E40" />}
          title={t('history.empty_title')}
          message={t('history.empty_message')}
        />
      ) : (
        <FlashList
          data={entries}
          keyExtractor={(e) => `${e.source}-${e.tourStopId ?? e.manualEntryId}`}
          contentContainerStyle={{ paddingHorizontal: 16, paddingTop: 12, paddingBottom: 96 }}
          ItemSeparatorComponent={() => <View className="h-2" />}
          renderItem={({ item }) => (
            <Animated.View
              entering={FadeIn.duration(motion.duration.fast)}
              exiting={FadeOut.duration(motion.duration.fast)}
              layout={LinearTransition.duration(motion.duration.normal)}
            >
              <HistoryRow
                entry={item}
                onPress={() => {
                  if (item.source === 'tour' && item.tourId) {
                    router.push(`/(tabs)/tours/${item.tourId}` as never);
                  } else if (item.source === 'manual' && item.manualEntryId) {
                    router.push(`/(tabs)/clients/${id}/history/${item.manualEntryId}` as never);
                  }
                }}
              />
            </Animated.View>
          )}
        />
      )}

      <PressScale
        onPress={() => {
          void haptics.selection();
          router.push(`/(tabs)/clients/${id}/history/new` as never);
        }}
        accessibilityLabel={t('history.manual.new_title')}
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
