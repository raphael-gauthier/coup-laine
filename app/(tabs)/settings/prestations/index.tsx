import { View } from 'react-native';
import { Stack, useRouter } from 'expo-router';
import { FlashList } from '@shopify/flash-list';
import { Plus, ChevronRight } from 'lucide-react-native';
import { useTranslation } from 'react-i18next';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { Button } from '@/ui/primitives/button';
import { PressScale } from '@/ui/motion/press-scale';
import { ErrorState } from '@/ui/components/error-state';
import { usePrestations } from '@/state/queries/species';
import { haptics } from '@/ui/motion/haptics';

export default function PrestationsListScreen() {
  const { t } = useTranslation();
  const router = useRouter();
  const { data: prestations = [], isError, refetch } = usePrestations();

  if (isError) return <ErrorState onRetry={() => refetch()} />;

  return (
    <Surface className="flex-1">
      <Stack.Screen
        options={{
          title: t('catalogs.prestations.list_title'),
          headerRight: () => (
            <Button size="sm" onPress={() => router.push('/(tabs)/settings/prestations/new' as never)}>
              <Plus size={16} color="white" />
              <Text variant="onPrimary" className="font-semibold">{t('catalogs.prestations.new_title')}</Text>
            </Button>
          ),
        }}
      />
      <FlashList
        data={prestations}
        keyExtractor={(p) => p.id}
        contentContainerStyle={{ paddingHorizontal: 16, paddingTop: 12, paddingBottom: 24 }}
        ItemSeparatorComponent={() => <View className="h-2" />}
        renderItem={({ item }) => (
          <PressScale
            onPress={() => {
              void haptics.selection();
              router.push(`/(tabs)/settings/prestations/${item.id}` as never);
            }}
          >
            <Surface variant="muted" className="flex-row items-center rounded-2xl px-4 py-3 gap-3">
              <View className="flex-1">
                <Text className="font-semibold">{item.label}</Text>
                {!item.isActive ? (
                  <Text variant="muted" className="text-xs mt-0.5">{t('catalogs.prestations.inactive_badge')}</Text>
                ) : null}
              </View>
              <ChevronRight size={18} color="#5C4E40" />
            </Surface>
          </PressScale>
        )}
      />
    </Surface>
  );
}
