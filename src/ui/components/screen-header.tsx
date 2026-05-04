import type { ReactNode } from 'react';
import { View } from 'react-native';
import { useRouter } from 'expo-router';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { ChevronLeft } from 'lucide-react-native';
import { useTranslation } from 'react-i18next';
import { Text } from '@/ui/primitives/text';
import { PressScale } from '@/ui/motion/press-scale';

interface Props {
  title: string;
  variant?: 'root' | 'sub';
  rightSlot?: ReactNode;
}

export function ScreenHeader({ title, variant = 'sub', rightSlot }: Props) {
  const router = useRouter();
  const insets = useSafeAreaInsets();
  const { t } = useTranslation();

  return (
    <View
      className="flex-row items-center gap-2 pb-2"
      style={{
        paddingTop: insets.top + 8,
        paddingLeft: variant === 'sub' ? 8 : 16,
        paddingRight: 16,
      }}
    >
      {variant === 'sub' ? (
        <PressScale
          onPress={() => router.back()}
          accessibilityLabel={t('common.back')}
          accessibilityRole="button"
          className="p-2"
        >
          <ChevronLeft size={28} color="#5C4E40" />
        </PressScale>
      ) : null}
      <Text
        className="flex-1 text-3xl font-bold tracking-tight"
        numberOfLines={1}
      >
        {title}
      </Text>
      {rightSlot}
    </View>
  );
}
