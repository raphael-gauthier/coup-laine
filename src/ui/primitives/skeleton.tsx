import { useEffect } from 'react';
import { View, type StyleProp, type ViewStyle } from 'react-native';
import Animated, {
  useAnimatedStyle,
  useSharedValue,
  withRepeat,
  withTiming,
  withSequence,
} from 'react-native-reanimated';
import { motion } from '@/ui/motion/motion-tokens';
import { cn } from '@/lib/cn';

interface Props {
  className?: string;
  style?: StyleProp<ViewStyle>;
}

export function Skeleton({ className, style }: Props) {
  const opacity = useSharedValue(0.5);

  useEffect(() => {
    opacity.value = withRepeat(
      withSequence(
        withTiming(1, { duration: motion.duration.slow }),
        withTiming(0.5, { duration: motion.duration.slow })
      ),
      -1,
      true
    );
  }, [opacity]);

  const animatedStyle = useAnimatedStyle(() => ({ opacity: opacity.value }));

  return (
    <Animated.View
      className={cn('bg-muted dark:bg-muted-dark rounded-2xl', className)}
      style={[animatedStyle, style]}
    />
  );
}

export function ListSkeleton({ rows = 5 }: { rows?: number }) {
  return (
    <View style={{ paddingHorizontal: 16, paddingTop: 12, gap: 8 }}>
      {Array.from({ length: rows }).map((_, i) => (
        <Skeleton key={i} className="h-20" />
      ))}
    </View>
  );
}
