import type { ReactNode } from 'react';
import { View, type ViewProps } from 'react-native';
import { cva, type VariantProps } from 'class-variance-authority';
import { cn } from '@/lib/cn';

/**
 * Themed surface — abstracts the `bg-x dark:bg-x-dark` pair behind a variant.
 * Use this instead of writing `<View className="bg-background dark:bg-background-dark">`
 * everywhere; only fall back to a raw View when no themed background is needed.
 */
const surfaceVariants = cva('', {
  variants: {
    variant: {
      background: 'bg-background dark:bg-background-dark',
      muted: 'bg-muted dark:bg-muted-dark',
      primary: 'bg-primary dark:bg-primary-dark',
      accent: 'bg-accent dark:bg-accent-dark',
      danger: 'bg-danger dark:bg-danger-dark',
      success: 'bg-success dark:bg-success-dark',
      transparent: 'bg-transparent',
    },
  },
  defaultVariants: { variant: 'background' },
});

interface Props extends ViewProps, VariantProps<typeof surfaceVariants> {
  children?: ReactNode;
  className?: string;
}

export function Surface({ variant, className, children, ...rest }: Props) {
  return (
    <View className={cn(surfaceVariants({ variant }), className)} {...rest}>
      {children}
    </View>
  );
}
