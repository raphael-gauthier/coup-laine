import { View } from 'react-native';
import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { useResolvedColorScheme } from '@/ui/theme/theme-provider';

const STATUSES = [
  { label: 'En attente de RDV', light: '#C88226', dark: '#DC9E4E' },
  { label: 'Planifié',          light: '#A1602F', dark: '#C68A58' },
  { label: 'VIP',               light: '#7A3E7A', dark: '#A66BA6' },
];

export function StatusRowDemo() {
  const scheme = useResolvedColorScheme();

  return (
    <View className="gap-3 w-full" style={{ maxWidth: 320 }}>
      {STATUSES.map((s) => {
        const hex = scheme === 'dark' ? s.dark : s.light;
        return (
          <Surface key={s.label} variant="muted" className="flex-row items-center rounded-2xl px-4 py-3 gap-3">
            <View
              style={{
                width: 24,
                height: 24,
                borderRadius: 12,
                backgroundColor: hex,
                borderWidth: 2,
                borderColor: '#DCD0C0',
              }}
            />
            <View className="flex-1">
              <Text className="font-medium">{s.label}</Text>
            </View>
          </Surface>
        );
      })}
    </View>
  );
}
