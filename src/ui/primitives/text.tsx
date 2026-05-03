import { Text as RNText, type TextProps as RNTextProps } from 'react-native';
import { cva, type VariantProps } from 'class-variance-authority';
import { cn } from '@/lib/cn';

/**
 * Themed text — variant picks the right `text-x dark:text-x-dark` pair.
 * Default ('default') is the primary foreground on a background surface;
 * the `on*` variants are for text rendered on a coloured surface
 * (primary/accent/danger/success buttons, etc.).
 */
const textVariants = cva('', {
  variants: {
    variant: {
      default: 'text-foreground dark:text-foreground-dark',
      muted: 'text-muted-foreground dark:text-muted-dark-foreground',
      primary: 'text-primary dark:text-primary-dark',
      onPrimary: 'text-primary-foreground dark:text-primary-dark-foreground',
      onAccent: 'text-accent-foreground dark:text-accent-dark-foreground',
      onDanger: 'text-danger-foreground dark:text-danger-dark-foreground',
      onSuccess: 'text-success-foreground dark:text-success-dark-foreground',
    },
  },
  defaultVariants: { variant: 'default' },
});

interface Props extends RNTextProps, VariantProps<typeof textVariants> {
  className?: string;
}

export function Text({ className, variant, ...rest }: Props) {
  return <RNText className={cn(textVariants({ variant }), className)} {...rest} />;
}
