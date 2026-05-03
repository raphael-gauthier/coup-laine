import { View } from 'react-native';
import { PressScale } from '@/ui/motion/press-scale';
import { Text } from '@/ui/primitives/text';
import { haptics } from '@/ui/motion/haptics';
import { cn } from '@/lib/cn';

export interface SegmentedControlOption<T extends string> {
  value: T;
  label: string;
}

interface Props<T extends string> {
  options: SegmentedControlOption<T>[];
  value: T;
  onChange: (v: T) => void;
}

export function SegmentedControl<T extends string>({ options, value, onChange }: Props<T>) {
  return (
    <View className="flex-row p-1 rounded-2xl bg-muted dark:bg-muted-dark gap-1">
      {options.map((opt) => {
        const selected = opt.value === value;
        return (
          <PressScale
            key={opt.value}
            onPress={() => {
              if (selected) return;
              void haptics.selection();
              onChange(opt.value);
            }}
            className={cn(
              'flex-1 py-2 rounded-xl items-center',
              selected && 'bg-background dark:bg-background-dark'
            )}
          >
            <Text className={cn('font-medium', selected ? '' : 'opacity-60')}>
              {opt.label}
            </Text>
          </PressScale>
        );
      })}
    </View>
  );
}
