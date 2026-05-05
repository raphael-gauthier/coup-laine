import { View } from 'react-native';
import { useRouter } from 'expo-router';
import { FlashList } from '@shopify/flash-list';
import { Plus, ChevronRight, PawPrint } from 'lucide-react-native';
import { useTranslation } from 'react-i18next';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { Button } from '@/ui/primitives/button';
import { Fab } from '@/ui/primitives/fab';
import { ListSkeleton } from '@/ui/primitives/skeleton';
import { PressScale } from '@/ui/motion/press-scale';
import { EmptyState } from '@/ui/components/empty-state';
import { ErrorState } from '@/ui/components/error-state';
import { ScreenHeader } from '@/ui/components/screen-header';
import { useSpecies } from '@/state/queries/species';
import { haptics } from '@/ui/motion/haptics';
import { useOnContrastColor, useMutedForegroundColor } from '@/ui/theme/colors';

export default function SpeciesListScreen() {
  const { t } = useTranslation();
  const router = useRouter();
  const onContrast = useOnContrastColor();
  const mutedFg = useMutedForegroundColor();
  const { data: species = [], isError, isLoading, refetch } = useSpecies();

  if (isError) return <ErrorState onRetry={() => refetch()} />;

  return (
    <Surface className="flex-1">
      <ScreenHeader title={t('catalogs.species.list_title')} />
      {isLoading ? (
        <ListSkeleton />
      ) : species.length === 0 ? (
        <EmptyState
          icon={<PawPrint size={48} color={mutedFg} />}
          title={t('catalogs.species.empty_title')}
          message={t('catalogs.species.empty_message')}
          action={
            <Button
              onPress={() => {
                void haptics.selection();
                router.push('/(tabs)/settings/species/new' as never);
              }}
              accessibilityLabel={t('catalogs.species.empty_cta')}
            >
              <Plus size={16} color={onContrast} />
              <Text variant="onPrimary" className="font-semibold">
                {t('catalogs.species.empty_cta')}
              </Text>
            </Button>
          }
        />
      ) : (
        <FlashList
          data={species}
          keyExtractor={(s) => s.id}
          contentContainerStyle={{ paddingHorizontal: 16, paddingTop: 12, paddingBottom: 96 }}
          ItemSeparatorComponent={() => <View className="h-2" />}
          renderItem={({ item }) => (
            <PressScale
              onPress={() => {
                void haptics.selection();
                router.push(`/(tabs)/settings/species/${item.id}` as never);
              }}
              accessibilityLabel={item.label}
            >
              <Surface variant="muted" className="flex-row items-center rounded-2xl px-4 py-3 gap-3">
                <View className="flex-1">
                  <Text className="font-semibold">{item.label}</Text>
                  {!item.isCustom ? (
                    <Text variant="muted" className="text-xs mt-0.5">{t('catalogs.species.is_standard')}</Text>
                  ) : null}
                </View>
                <ChevronRight size={18} color={mutedFg} />
              </Surface>
            </PressScale>
          )}
        />
      )}

      <Fab
        icon={Plus}
        onPress={() => router.push('/(tabs)/settings/species/new' as never)}
        accessibilityLabel={t('catalogs.species.new_title')}
      />
    </Surface>
  );
}
