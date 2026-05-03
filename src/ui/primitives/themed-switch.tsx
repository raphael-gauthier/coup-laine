import { Switch, useColorScheme, Platform } from 'react-native';
import type { SwitchProps } from 'react-native';

const PRIMARY_LIGHT = '#A1602F';
const PRIMARY_DARK = '#C68A58';
const TRACK_OFF_LIGHT = '#DCD0C0';
const TRACK_OFF_DARK = '#3C322A';
const THUMB_LIGHT = '#FAF6F0';
const THUMB_DARK = '#F0E8DC';

export function ThemedSwitch(props: Omit<SwitchProps, 'trackColor' | 'thumbColor' | 'ios_backgroundColor'>) {
  const isDark = useColorScheme() === 'dark';
  const onColor = isDark ? PRIMARY_DARK : PRIMARY_LIGHT;
  const offColor = isDark ? TRACK_OFF_DARK : TRACK_OFF_LIGHT;
  const thumb = isDark ? THUMB_DARK : THUMB_LIGHT;
  return (
    <Switch
      trackColor={{ false: offColor, true: onColor }}
      thumbColor={Platform.OS === 'android' ? thumb : undefined}
      ios_backgroundColor={offColor}
      {...props}
    />
  );
}
