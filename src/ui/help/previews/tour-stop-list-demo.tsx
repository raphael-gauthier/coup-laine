import { View } from 'react-native';
import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';

const STOPS = [
  { time: '08:15 → 09:00', name: 'Famille Le Goff',       summary: 'Tonte petit mouton ×5 → 18 €' },
  { time: '09:30 → 10:30', name: 'Ferme du Pré Vert',     summary: 'Tonte grande brebis ×8, Parage ×1 → 65 €' },
  { time: '11:00 → 12:00', name: 'GAEC des Trois Chênes', summary: 'Tonte petit mouton ×12 → 42 €' },
];

export function TourStopListDemo() {
  return (
    <View className="gap-2 w-full" style={{ maxWidth: 320 }}>
      {STOPS.map((s) => (
        <Surface key={s.name} variant="muted" className="rounded-2xl px-4 py-3 gap-1">
          <View className="flex-row items-center justify-between">
            <Text className="font-semibold flex-1">{s.name}</Text>
            <Text variant="muted" className="text-xs font-mono">{s.time}</Text>
          </View>
          <Text variant="muted" className="text-xs">{s.summary}</Text>
        </Surface>
      ))}
    </View>
  );
}
