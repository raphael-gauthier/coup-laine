import { View } from 'react-native';
import { TriangleAlert } from 'lucide-react-native';
import { Text } from '@/ui/primitives/text';
import { Button } from '@/ui/primitives/button';
import { useTranslation } from 'react-i18next';

interface Props {
  title?: string;
  message?: string;
  onRetry?: () => void;
}

export function ErrorState({ title, message, onRetry }: Props) {
  const { t } = useTranslation();
  return (
    <View className="flex-1 items-center justify-center px-8 gap-4">
      <TriangleAlert size={48} color="#B23832" />
      <Text className="text-lg font-semibold text-center">
        {title ?? t('common.error_generic')}
      </Text>
      {message ? <Text variant="muted" className="text-center">{message}</Text> : null}
      {onRetry ? <Button onPress={onRetry}>{t('common.retry')}</Button> : null}
    </View>
  );
}
