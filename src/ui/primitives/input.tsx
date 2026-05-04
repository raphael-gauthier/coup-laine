import { TextInput, useColorScheme, type TextInputProps } from 'react-native';
import { cn } from '@/lib/cn';

interface Props extends TextInputProps {
  className?: string;
}

export function Input({ className, style, ...rest }: Props) {
  const isDark = useColorScheme() === 'dark';
  return (
    <TextInput
      placeholderTextColor={isDark ? '#B4A490' : '#5C4E40'}
      className={cn(
        'rounded-2xl border border-border dark:border-border-dark',
        'bg-input dark:bg-input-dark',
        'px-4 py-3 text-base text-foreground dark:text-foreground-dark',
        className
      )}
      style={[{ lineHeight: 20 }, style]}
      {...rest}
    />
  );
}
