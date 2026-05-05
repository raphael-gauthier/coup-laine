import type { ReactNode } from 'react';
import {
  GestureResponderEvent,
  Pressable,
  PressableProps,
  StyleProp,
  ViewStyle,
} from 'react-native';
import Animated, {
  useAnimatedStyle,
  useSharedValue,
  withSpring,
} from 'react-native-reanimated';
import { motion } from './motion-tokens';

interface Props extends Omit<PressableProps, 'children' | 'style' | 'accessibilityLabel'> {
  children: ReactNode;
  scaleTo?: number;
  style?: StyleProp<ViewStyle>;
  // Required at the type level to prevent unlabelled pressables (a11y regression guard).
  accessibilityLabel: string;
}

const AnimatedPressable = Animated.createAnimatedComponent(Pressable);

/**
 * Wraps a pressable with a spring scale-down on press. Use for buttons,
 * cards, list items — any tappable surface.
 */
export function PressScale({
  children,
  scaleTo = 0.97,
  style,
  onPressIn,
  onPressOut,
  accessibilityRole = 'button',
  ...rest
}: Props) {
  const scale = useSharedValue(1);

  const animatedStyle = useAnimatedStyle(() => ({
    transform: [{ scale: scale.value }],
  }));

  const handlePressIn = (e: GestureResponderEvent) => {
    scale.value = withSpring(scaleTo, motion.spring.medium);
    onPressIn?.(e);
  };
  const handlePressOut = (e: GestureResponderEvent) => {
    scale.value = withSpring(1, motion.spring.medium);
    onPressOut?.(e);
  };

  return (
    <AnimatedPressable
      onPressIn={handlePressIn}
      onPressOut={handlePressOut}
      style={[animatedStyle, style]}
      accessibilityRole={accessibilityRole}
      {...rest}
    >
      {children}
    </AnimatedPressable>
  );
}
