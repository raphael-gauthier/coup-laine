import { View } from 'react-native';
import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';

// Fake stops that mirror TourStopRow's visual: name + arrival→departure + services
const STOPS = [
  { name: 'Famille Le Goff', time: '08:15 → 09:00', services: 'Tonte ×12 → 96 €' },
  { name: 'Ferme du Pré Vert', time: '09:40 → 11:10', services: 'Tonte ×20 · Pedicure ×8 → 168 €' },
  { name: 'GAEC Ar Vro', time: '11:55 → 12:30', services: 'Tonte ×9 → 72 €' },
];

export function TourPlanningDemo() {
  return (
    <View className="gap-2" style={{ width: '100%' }}>
      {STOPS.map((stop) => (
        <Surface key={stop.name} variant="muted" className="rounded-2xl px-4 py-3 gap-1">
          <View className="flex-row items-center justify-between">
            <Text className="font-semibold flex-1" numberOfLines={1}>{stop.name}</Text>
            <Text variant="muted" className="text-xs font-mono">{stop.time}</Text>
          </View>
          <Text variant="muted" className="text-xs" numberOfLines={1}>{stop.services}</Text>
        </Surface>
      ))}
    </View>
  );
}
