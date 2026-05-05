import type { ReactNode } from 'react';
import { ActivityIndicator, View } from 'react-native';
import { cva, type VariantProps } from 'class-variance-authority';
import { PressScale } from '@/ui/motion/press-scale';
import { haptics } from '@/ui/motion/haptics';
import { cn } from '@/lib/cn';
import { Text } from './text';

const buttonSurfaceVariants = cva(
  'flex-row items-center justify-center rounded-2xl px-5 py-3',
  {
    variants: {
      variant: {
        primary: 'bg-primary dark:bg-primary-dark',
        secondary: 'bg-muted dark:bg-muted-dark',
        ghost: 'bg-transparent',
        danger: 'bg-danger dark:bg-danger-dark',
        accent: 'bg-accent dark:bg-accent-dark',
      },
      size: {
        sm: 'px-3 py-2',
        md: 'px-5 py-3',
        lg: 'px-6 py-4',
      },
    },
    defaultVariants: { variant: 'primary', size: 'md' },
  }
);

const labelSize = cva('font-semibold', {
  variants: {
    size: {
      sm: 'text-sm',
      md: 'text-base',
      lg: 'text-lg',
    },
  },
  defaultVariants: { size: 'md' },
});

type ButtonVariant = 'primary' | 'secondary' | 'ghost' | 'danger' | 'accent';

const TEXT_VARIANT_FOR: Record<ButtonVariant, 'default' | 'onPrimary' | 'onDanger' | 'onAccent'> = {
  primary: 'onPrimary',
  secondary: 'default',
  ghost: 'default',
  danger: 'onDanger',
  accent: 'onAccent',
};

type CommonProps = VariantProps<typeof buttonSurfaceVariants> & {
  onPress?: () => void;
  disabled?: boolean;
  loading?: boolean;
  className?: string;
  hapticOnPress?: boolean;
};

// String children auto-derive the accessibility name from the visible label,
// so accessibilityLabel is optional. Custom (icon/composite) children must
// pass an explicit accessibilityLabel.
type Props =
  | (CommonProps & { children: string; accessibilityLabel?: string })
  | (CommonProps & { children: Exclude<ReactNode, string>; accessibilityLabel: string });

export function Button({
  children,
  onPress,
  disabled,
  loading,
  className,
  variant,
  size,
  hapticOnPress = true,
  accessibilityLabel,
}: Props) {
  const resolvedAccessibilityLabel =
    accessibilityLabel ?? (typeof children === 'string' ? children : '');
  const handlePress = () => {
    if (disabled || loading) return;
    if (hapticOnPress) void haptics.selection();
    onPress?.();
  };

  const resolvedVariant = (variant ?? 'primary') as ButtonVariant;
  const textVariant = TEXT_VARIANT_FOR[resolvedVariant];

  return (
    <PressScale
      onPress={handlePress}
      disabled={disabled || loading}
      accessibilityLabel={resolvedAccessibilityLabel}
      accessibilityRole="button"
      className={cn(
        buttonSurfaceVariants({ variant, size }),
        (disabled || loading) && 'opacity-60',
        className
      )}
    >
      {loading ? (
        <ActivityIndicator />
      ) : typeof children === 'string' ? (
        <Text variant={textVariant} className={labelSize({ size })}>
          {children}
        </Text>
      ) : (
        <View className="flex-row items-center gap-2">{children}</View>
      )}
    </PressScale>
  );
}
