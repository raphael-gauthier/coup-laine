import { View } from 'react-native';
import type { ReactNode } from 'react';
import { Text } from '@/ui/primitives/text';

interface Props {
  icon?: ReactNode;
  title: string;
  message?: string;
  action?: ReactNode;
}

export function EmptyState({ icon, title, message, action }: Props) {
  return (
    <View className="flex-1 items-center justify-center px-8 gap-4">
      {icon}
      <Text className="text-lg font-semibold text-center">{title}</Text>
      {message ? (
        <Text variant="muted" className="text-center">{message}</Text>
      ) : null}
      {action}
    </View>
  );
}
