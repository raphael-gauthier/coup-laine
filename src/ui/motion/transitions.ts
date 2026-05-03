import type { NativeStackNavigationOptions } from '@react-navigation/native-stack';

/** Default stack transition: native slide horizontal. */
export const stackSlide: NativeStackNavigationOptions = {
  animation: 'slide_from_right',
  animationDuration: 250,
};

/** Modal-style slide from bottom with fade backdrop. */
export const modalSlide: NativeStackNavigationOptions = {
  presentation: 'modal',
  animation: 'slide_from_bottom',
  animationDuration: 300,
};

/** No animation, used for tab roots. */
export const noAnimation: NativeStackNavigationOptions = {
  animation: 'none',
};
