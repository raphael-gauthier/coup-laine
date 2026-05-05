import { useColorScheme, View } from 'react-native';
import { Minus, Plus } from 'lucide-react-native';
import { useTranslation } from 'react-i18next';
import { PressScale } from '@/ui/motion/press-scale';
import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { haptics } from '@/ui/motion/haptics';
import { useSpecies, useAnimalCategories } from '@/state/queries/species';
import type { AnimalCount } from '@/domain/models/animal-count';

interface Props {
  value: AnimalCount[];
  onChange: (next: AnimalCount[]) => void;
}

export function AnimalCountsEditor({ value, onChange }: Props) {
  const { t } = useTranslation();
  const { data: species = [] } = useSpecies();
  const { data: categories = [] } = useAnimalCategories();
  const isDark = useColorScheme() === 'dark';
  const stepperIconColor = isDark ? '#F0E8DC' : '#1C1612';

  const counts = new Map(value.map((c) => [c.categoryId, c.count]));

  const setCount = (categoryId: string, count: number) => {
    const safe = Math.max(0, count);
    const others = value.filter((c) => c.categoryId !== categoryId);
    onChange(safe > 0 ? [...others, { categoryId, count: safe }] : others);
  };

  return (
    <View className="gap-3">
      <Text className="text-sm font-medium">{t('clients.animal_counts')}</Text>
      {species.map((s) => {
        const speciesCategories = categories.filter((c) => c.speciesId === s.id);
        if (speciesCategories.length === 0) return null;
        return (
          <Surface key={s.id} variant="muted" className="rounded-2xl p-3 gap-2">
            <Text className="font-semibold">{s.label}</Text>
            {speciesCategories.map((cat) => {
              const count = counts.get(cat.id) ?? 0;
              return (
                <View key={cat.id} className="flex-row items-center justify-between">
                  <Text className="flex-1">{cat.label}</Text>
                  <View className="flex-row items-center gap-3">
                    <PressScale
                      onPress={() => {
                        void haptics.selection();
                        setCount(cat.id, count - 1);
                      }}
                      accessibilityLabel={t('common.decrement')}
                    >
                      <View className="w-11 h-11 rounded-full items-center justify-center bg-background dark:bg-[#4A3F33]">
                        <Minus size={16} color={stepperIconColor} />
                      </View>
                    </PressScale>
                    <Text className="w-8 text-center text-lg font-semibold">{count}</Text>
                    <PressScale
                      onPress={() => {
                        void haptics.selection();
                        setCount(cat.id, count + 1);
                      }}
                      accessibilityLabel={t('common.increment')}
                    >
                      <View className="w-11 h-11 rounded-full items-center justify-center bg-background dark:bg-[#4A3F33]">
                        <Plus size={16} color={stepperIconColor} />
                      </View>
                    </PressScale>
                  </View>
                </View>
              );
            })}
          </Surface>
        );
      })}
    </View>
  );
}
