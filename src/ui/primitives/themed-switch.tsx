import { Pressable, useColorScheme } from 'react-native';
import Animated, {
  interpolateColor,
  useAnimatedStyle,
  useDerivedValue,
  withSpring,
} from 'react-native-reanimated';
import { motion } from '@/ui/motion/motion-tokens';
import { haptics } from '@/ui/motion/haptics';

const TRACK_WIDTH = 48;
const TRACK_HEIGHT = 28;
const THUMB_SIZE = 22;
const PADDING = 3;
const THUMB_TRAVEL = TRACK_WIDTH - THUMB_SIZE - PADDING * 2;

const PRIMARY_LIGHT = '#A1602F';
const PRIMARY_DARK = '#C68A58';
const TRACK_OFF_LIGHT = '#DCD0C0';
const TRACK_OFF_DARK = '#3C322A';
const THUMB_LIGHT = '#FAF6F0';
const THUMB_DARK = '#F0E8DC';

interface Props {
  value: boolean;
  onValueChange: (v: boolean) => void;
  disabled?: boolean;
  testID?: string;
}

export function ThemedSwitch({ value, onValueChange, disabled, testID }: Props) {
  const isDark = useColorScheme() === 'dark';
  const onColor = isDark ? PRIMARY_DARK : PRIMARY_LIGHT;
  const offColor = isDark ? TRACK_OFF_DARK : TRACK_OFF_LIGHT;
  const thumb = isDark ? THUMB_DARK : THUMB_LIGHT;

  const progress = useDerivedValue(() =>
    withSpring(value ? 1 : 0, motion.spring.medium)
  );

  const trackStyle = useAnimatedStyle(() => ({
    backgroundColor: interpolateColor(progress.value, [0, 1], [offColor, onColor]),
  }));

  const thumbStyle = useAnimatedStyle(() => ({
    transform: [{ translateX: progress.value * THUMB_TRAVEL }],
  }));

  return (
    <Pressable
      testID={testID}
      disabled={disabled}
      onPress={() => {
        void haptics.selection();
        onValueChange(!value);
      }}
      style={{ opacity: disabled ? 0.5 : 1 }}
      accessibilityRole="switch"
      accessibilityState={{ checked: value, disabled }}
    >
      <Animated.View
        style={[
          {
            width: TRACK_WIDTH,
            height: TRACK_HEIGHT,
            borderRadius: TRACK_HEIGHT / 2,
            padding: PADDING,
            justifyContent: 'center',
          },
          trackStyle,
        ]}
      >
        <Animated.View
          style={[
            {
              width: THUMB_SIZE,
              height: THUMB_SIZE,
              borderRadius: THUMB_SIZE / 2,
              backgroundColor: thumb,
              shadowColor: '#000',
              shadowOpacity: 0.18,
              shadowRadius: 2,
              shadowOffset: { width: 0, height: 1 },
              elevation: 2,
            },
            thumbStyle,
          ]}
        />
      </Animated.View>
    </Pressable>
  );
}
