import { View } from 'react-native';
import { Calendar, ChevronRight } from 'lucide-react-native';
import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';

export function TourCardDemo() {
  return (
    <Surface variant="muted" className="rounded-2xl px-4 py-3 gap-2" style={{ width: '100%' }}>
      <View className="flex-row items-center justify-between">
        <View className="flex-row items-center gap-2">
          {/* "planned" status badge — bg-waiting token */}
          <View className="px-2 py-0.5 rounded-full bg-waiting dark:bg-waiting-dark">
            <Text className="text-xs font-semibold text-primary-foreground dark:text-primary-dark-foreground">
              Planifiée
            </Text>
          </View>
        </View>
        <ChevronRight size={18} color="#5C4E40" />
      </View>

      <View className="flex-row items-center gap-1">
        <Calendar size={14} color="#5C4E40" />
        <Text className="font-semibold">lundi 16 juin 2026, 08:00</Text>
      </View>

      <View className="flex-row flex-wrap gap-x-3 gap-y-1">
        <Text variant="muted" className="text-xs">4 arrêts</Text>
        <Text variant="muted" className="text-xs">52 animaux</Text>
        <Text variant="muted" className="text-xs">38,4 km</Text>
        <Text variant="muted" className="text-xs">3h10</Text>
        <Text variant="muted" className="text-xs">260 €</Text>
      </View>
    </Surface>
  );
}
