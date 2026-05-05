import { Check } from 'lucide-react-native';
import { PressScale } from '@/ui/motion/press-scale';
import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { haptics } from '@/ui/motion/haptics';

interface Props {
  label: string;
  selected: boolean;
  onPress: () => void;
}

export function RadioRow({ label, selected, onPress }: Props) {
  const handle = () => {
    void haptics.selection();
    onPress();
  };
  return (
    <PressScale onPress={handle} accessibilityLabel={label}>
      <Surface className="flex-row items-center justify-between rounded-2xl border border-border dark:border-border-dark px-4 py-4">
        <Text className="text-base">{label}</Text>
        {selected && <Check size={20} color="#A1602F" />}
      </Surface>
    </PressScale>
  );
}
