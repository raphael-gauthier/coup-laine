import { Easing } from 'react-native-reanimated';

export const motion = {
  duration: {
    instant: 100,
    fast: 200,
    normal: 300,
    slow: 500,
  },
  easing: {
    standard: Easing.bezier(0.4, 0.0, 0.2, 1),
    decelerate: Easing.bezier(0.0, 0.0, 0.2, 1),
    accelerate: Easing.bezier(0.4, 0.0, 1, 1),
  },
  spring: {
    soft: { damping: 18, stiffness: 120, mass: 1 },
    medium: { damping: 15, stiffness: 150, mass: 1 },
    bouncy: { damping: 10, stiffness: 180, mass: 1 },
  },
} as const;
