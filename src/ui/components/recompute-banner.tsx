import { View } from 'react-native';
import { RefreshCw } from 'lucide-react-native';
import { useTranslation } from 'react-i18next';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { Button } from '@/ui/primitives/button';
import { useClientsPendingRecompute, useRecomputeAll } from '@/state/queries/recompute';

export function RecomputeBanner() {
  const { t } = useTranslation();
  const { data: pending = [] } = useClientsPendingRecompute();
  const recompute = useRecomputeAll();

  if (pending.length === 0) return null;

  return (
    <Surface variant="muted" className="mx-4 mt-3 rounded-2xl px-4 py-3 gap-2">
      <View className="flex-row items-center gap-2">
        <RefreshCw size={16} color="#5C4E40" />
        <Text className="text-sm font-medium flex-1">
          {t('recompute.banner_title', { count: pending.length })}
        </Text>
      </View>
      <Text variant="muted" className="text-xs">{t('recompute.banner_message')}</Text>
      <Button
        size="sm"
        variant="secondary"
        onPress={() => recompute.mutate()}
        loading={recompute.isPending}
      >
        {recompute.isPending ? t('recompute.running') : t('recompute.banner_cta')}
      </Button>
    </Surface>
  );
}
