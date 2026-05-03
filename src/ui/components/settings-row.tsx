import { View } from 'react-native';
import { ChevronRight } from 'lucide-react-native';
import { PressScale } from '@/ui/motion/press-scale';
import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { haptics } from '@/ui/motion/haptics';

interface Props {
  label: string;
  hint?: string;
  onPress: () => void;
  testID?: string;
}

export function SettingsRow({ label, hint, onPress, testID }: Props) {
  const handle = () => {
    void haptics.selection();
    onPress();
  };
  return (
    <PressScale onPress={handle} testID={testID}>
      <Surface className="flex-row items-center justify-between rounded-2xl border border-border dark:border-border-dark px-4 py-4">
        <View className="flex-1 pr-4">
          <Text className="text-base font-medium">{label}</Text>
          {hint ? <Text variant="muted" className="text-sm mt-0.5">{hint}</Text> : null}
        </View>
        <ChevronRight size={20} color="#5C4E40" />
      </Surface>
    </PressScale>
  );
}
