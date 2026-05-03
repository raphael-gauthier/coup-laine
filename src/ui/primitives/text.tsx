import { Text as RNText, type TextProps as RNTextProps } from 'react-native';
import { cn } from '@/lib/cn';

interface Props extends RNTextProps {
  className?: string;
}

export function Text({ className, ...rest }: Props) {
  return <RNText className={cn('text-foreground', className)} {...rest} />;
}
