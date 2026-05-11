import { View } from 'react-native';
import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';

const ROWS = [
  { label: 'Tonte petit mouton', category: 'Mouton', price: '3,50 €', duration: '5 min' },
  { label: 'Tonte grande brebis', category: 'Mouton', price: '5,00 €', duration: '8 min' },
  { label: 'Parage', category: 'Cheval', price: '25,00 €', duration: '15 min' },
];

export function ServiceRowDemo() {
  return (
    <View className="gap-2 w-full" style={{ maxWidth: 320 }}>
      {ROWS.map((item) => (
        <Surface key={item.label} variant="muted" className="flex-row items-center rounded-2xl px-4 py-3 gap-3">
          <View className="flex-1">
            <Text className="font-semibold">{item.label}</Text>
            <Text variant="muted" className="text-xs">{item.price} · {item.duration}</Text>
          </View>
        </Surface>
      ))}
    </View>
  );
}
