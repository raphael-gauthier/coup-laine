import { View } from 'react-native';
import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { useResolvedColorScheme } from '@/ui/theme/theme-provider';

// Status hex pairs from migration 0009 seed.
const STATUSES = [
  { label: 'En attente', light: '#C88226', dark: '#DC9E4E', on: true },
  { label: 'Planifié',   light: '#A1602F', dark: '#C68A58', on: true },
  { label: 'Tondu',      light: '#5C7548', dark: '#98B282', on: false },
  { label: 'Défaut',     light: '#94A3B8', dark: '#64748B', on: true },
];

export function ClientFilterDemo() {
  const scheme = useResolvedColorScheme();

  return (
    <Surface variant="muted" className="rounded-2xl px-4 pt-3 pb-2 gap-0" style={{ width: '100%' }}>
      <Text className="text-sm font-semibold mb-2">Filtrer par statut</Text>
      {STATUSES.map((s) => {
        const dotHex = scheme === 'dark' ? s.dark : s.light;
        return (
          <View
            key={s.label}
            className="flex-row items-center justify-between py-2.5 border-b border-border dark:border-border-dark"
          >
            <View className="flex-row items-center gap-2">
              <View style={{ width: 10, height: 10, borderRadius: 5, backgroundColor: dotHex }} />
              <Text className="text-sm">{s.label}</Text>
            </View>
            {/* Simplified toggle indicator */}
            <View
              style={{
                width: 36,
                height: 20,
                borderRadius: 10,
                backgroundColor: s.on ? dotHex : '#D1D5DB',
                justifyContent: 'center',
                paddingHorizontal: 2,
              }}
            >
              <View
                style={{
                  width: 16,
                  height: 16,
                  borderRadius: 8,
                  backgroundColor: '#FFFFFF',
                  alignSelf: s.on ? 'flex-end' : 'flex-start',
                }}
              />
            </View>
          </View>
        );
      })}
    </Surface>
  );
}
