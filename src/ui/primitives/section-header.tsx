import { View } from 'react-native';
import { Text } from './text';
import { cn } from '@/lib/cn';

interface Props {
  title: string;
  className?: string;
}

export function SectionHeader({ title, className }: Props) {
  return (
    <View className={cn('pt-4 pb-1 px-1', className)}>
      <Text variant="muted" className="text-xs font-semibold uppercase tracking-widest">
        {title}
      </Text>
    </View>
  );
}
