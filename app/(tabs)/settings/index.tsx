import { View } from 'react-native';
import { Text } from '@/ui/primitives/text';

export default function SettingsScreen() {
  return (
    <View className="flex-1 bg-background items-center justify-center">
      <Text className="text-foreground">Réglages (J2)</Text>
    </View>
  );
}
