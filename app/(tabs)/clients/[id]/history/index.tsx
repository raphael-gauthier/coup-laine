import { View } from 'react-native';
import { Stack, useLocalSearchParams, useRouter } from 'expo-router';
import { FlashList } from '@shopify/flash-list';
import Animated, { FadeIn, FadeOut, LinearTransition } from 'react-native-reanimated';
import { Plus, History as HistoryIcon } from 'lucide-react-native';
import { useTranslation } from 'react-i18next';

import { motion } from '@/ui/motion/motion-tokens';
import { Surface } from '@/ui/primitives/surface';
import { Button } from '@/ui/primitives/button';
import { Text } from '@/ui/primitives/text';
import { EmptyState } from '@/ui/components/empty-state';
import { ErrorState } from '@/ui/components/error-state';
import { HistoryRow } from '@/ui/components/history-row';
import { useClientHistory } from '@/state/queries/history';

export default function ClientHistoryScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const router = useRouter();
  const { t } = useTranslation();
  const { data: entries = [], isError, refetch } = useClientHistory(id);

  if (isError) return <ErrorState onRetry={() => refetch()} />;

  return (
    <Surface className="flex-1">
      <Stack.Screen
        options={{
          title: t('history.title'),
          headerRight: () => (
            <Button size="sm" onPress={() => router.push(`/(tabs)/clients/${id}/history/new` as never)}>
              <Plus size={16} color="white" />
              <Text variant="onPrimary" className="font-semibold">
                {t('history.manual.new_title')}
              </Text>
            </Button>
          ),
        }}
      />
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
          contentContainerStyle={{ paddingHorizontal: 16, paddingTop: 12, paddingBottom: 24 }}
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
    </Surface>
  );
}
