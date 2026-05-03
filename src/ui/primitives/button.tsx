import type { ReactNode } from 'react';
import { ActivityIndicator, View } from 'react-native';
import { cva, type VariantProps } from 'class-variance-authority';
import { PressScale } from '@/ui/motion/press-scale';
import { haptics } from '@/ui/motion/haptics';
import { cn } from '@/lib/cn';
import { Text } from './text';

const buttonVariants = cva(
  'flex-row items-center justify-center rounded-2xl px-5 py-3',
  {
    variants: {
      variant: {
        primary: 'bg-primary dark:bg-primary-dark',
        secondary: 'bg-muted dark:bg-muted-dark',
        ghost: 'bg-transparent',
        danger: 'bg-danger dark:bg-danger-dark',
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

const labelVariants = cva('font-semibold', {
  variants: {
    variant: {
      primary: 'text-primary-foreground dark:text-primary-dark-foreground',
      secondary: 'text-foreground dark:text-foreground-dark',
      ghost: 'text-foreground dark:text-foreground-dark',
      danger: 'text-danger-foreground dark:text-danger-dark-foreground',
    },
    size: {
      sm: 'text-sm',
      md: 'text-base',
      lg: 'text-lg',
    },
  },
  defaultVariants: { variant: 'primary', size: 'md' },
});

interface Props extends VariantProps<typeof buttonVariants> {
  children: ReactNode;
  onPress?: () => void;
  disabled?: boolean;
  loading?: boolean;
  className?: string;
  hapticOnPress?: boolean;
}

export function Button({
  children,
  onPress,
  disabled,
  loading,
  className,
  variant,
  size,
  hapticOnPress = true,
}: Props) {
  const handlePress = () => {
    if (disabled || loading) return;
    if (hapticOnPress) void haptics.selection();
    onPress?.();
  };

  return (
    <PressScale
      onPress={handlePress}
      disabled={disabled || loading}
      className={cn(
        buttonVariants({ variant, size }),
        (disabled || loading) && 'opacity-60',
        className
      )}
    >
      {loading ? (
        <ActivityIndicator />
      ) : typeof children === 'string' ? (
        <Text className={labelVariants({ variant, size })}>{children}</Text>
      ) : (
        <View className="flex-row items-center gap-2">{children}</View>
      )}
    </PressScale>
  );
}
