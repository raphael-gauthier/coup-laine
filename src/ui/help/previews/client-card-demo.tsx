import { View } from 'react-native';
import { MapPin, Hourglass, ChevronRight } from 'lucide-react-native';
import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { useResolvedColorScheme } from '@/ui/theme/theme-provider';

// Status "waiting" (en attente) hex pair from migration 0009 seed.
const STATUS_HEX = { light: '#C88226', dark: '#DC9E4E' };

export function ClientCardDemo() {
  const scheme = useResolvedColorScheme();
  const barHex = scheme === 'dark' ? STATUS_HEX.dark : STATUS_HEX.light;

  return (
    <Surface variant="muted" className="flex-row items-center rounded-2xl px-4 py-3 gap-3" style={{ width: '100%' }}>
      <View style={{ width: 4, height: 56, borderRadius: 2, backgroundColor: barHex }} />
      <View className="flex-1">
        <Text className="font-semibold" numberOfLines={1}>Famille Le Goff</Text>
        <View className="flex-row items-center gap-1 mt-0.5">
          <MapPin size={12} color="#5C4E40" />
          <Text variant="muted" className="text-sm flex-1" numberOfLines={1}>29780 Plouhinec</Text>
        </View>
        <Text className="text-sm mt-0.5" numberOfLines={1}>14 moutons</Text>
      </View>
      <Hourglass size={20} color="#A1602F" fill="#A1602F" />
      <ChevronRight size={18} color="#5C4E40" />
    </Surface>
  );
}
