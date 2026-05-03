import { View } from 'react-native';
import RNSlider from '@react-native-community/slider';
import { Text } from '@/ui/primitives/text';
import { useResolvedColorScheme } from '@/ui/theme/theme-provider';

interface Props {
  value: number;
  onChange: (v: number) => void;
  onCommit?: (v: number) => void;
  min: number;
  max: number;
  step?: number;
  label?: string;
  formatValue?: (v: number) => string;
}

const COLORS = {
  light: { thumb: '#A1602F', track: '#A1602F', bg: '#DCD0C0' },
  dark:  { thumb: '#C68A58', track: '#C68A58', bg: '#3C322A' },
};

export function Slider({ value, onChange, onCommit, min, max, step = 1, label, formatValue }: Props) {
  const scheme = useResolvedColorScheme();
  const c = COLORS[scheme];

  return (
    <View className="gap-1">
      {label ? (
        <View className="flex-row items-center justify-between">
          <Text className="text-sm font-medium">{label}</Text>
          <Text className="text-sm font-semibold">
            {formatValue ? formatValue(value) : value}
          </Text>
        </View>
      ) : null}
      <RNSlider
        minimumValue={min}
        maximumValue={max}
        step={step}
        value={value}
        onValueChange={onChange}
        onSlidingComplete={onCommit}
        minimumTrackTintColor={c.track}
        maximumTrackTintColor={c.bg}
        thumbTintColor={c.thumb}
      />
    </View>
  );
}
