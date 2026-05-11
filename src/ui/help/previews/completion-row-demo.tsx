import { View } from 'react-native';
import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';

// Mirrors StopCompletionEditor: client name, planned vs actual service rows with qty.
export function CompletionRowDemo() {
  return (
    <Surface variant="muted" className="rounded-2xl px-4 py-3 gap-3" style={{ width: '100%' }}>
      <Text className="text-base font-bold">Famille Le Goff</Text>

      <View className="gap-1">
        <Text className="text-sm font-semibold">Prévu</Text>
        <Text className="text-sm">Tonte ×14</Text>
      </View>

      <View className="gap-2">
        <Text className="text-sm font-semibold">Réalisé</Text>
        <View className="flex-row items-center gap-2">
          <Text className="flex-1 text-sm">Tonte</Text>
          <View
            className="rounded-lg border border-border dark:border-border-dark"
            style={{ width: 56, alignItems: 'center', paddingVertical: 6 }}
          >
            <Text className="text-sm text-center">12</Text>
          </View>
          {/* trash icon placeholder */}
          <View style={{ width: 16 }} />
        </View>
        <View className="flex-row items-center gap-2">
          <Text className="flex-1 text-sm">Pédicure</Text>
          <View
            className="rounded-lg border border-border dark:border-border-dark"
            style={{ width: 56, alignItems: 'center', paddingVertical: 6 }}
          >
            <Text className="text-sm text-center">4</Text>
          </View>
          <View style={{ width: 16 }} />
        </View>
      </View>

      <View className="flex-row items-center gap-1">
        <Text variant="muted" className="text-xs">Différence détectée —</Text>
        <Text className="text-xs font-medium text-danger dark:text-danger-dark">modifié</Text>
      </View>
    </Surface>
  );
}
