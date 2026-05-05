import type { ComponentType } from 'react';
import { PressScale } from '@/ui/motion/press-scale';
import { haptics } from '@/ui/motion/haptics';
import { Surface } from '@/ui/primitives/surface';
import { useOnContrastColor } from '@/ui/theme/colors';

interface IconProps {
  size?: number;
  color?: string;
}

interface Props {
  icon: ComponentType<IconProps>;
  onPress: () => void;
  accessibilityLabel: string;
}

/**
 * Floating Action Button — bottom-right, primary surface, icon-only.
 * Standardised for list screens that surface a "create new" affordance.
 */
export function Fab({ icon: Icon, onPress, accessibilityLabel }: Props) {
  const onContrast = useOnContrastColor();
  return (
    <PressScale
      onPress={() => {
        void haptics.selection();
        onPress();
      }}
      accessibilityLabel={accessibilityLabel}
      style={{ position: 'absolute', bottom: 24, right: 24 }}
    >
      <Surface
        variant="primary"
        className="rounded-full p-4"
        style={{ shadowColor: '#000', shadowOpacity: 0.2, shadowRadius: 6, elevation: 6 }}
      >
        <Icon size={24} color={onContrast} />
      </Surface>
    </PressScale>
  );
}
