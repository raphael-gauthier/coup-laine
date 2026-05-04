import { useState, useMemo } from 'react';
import { ScrollView, View } from 'react-native';
import { useRouter } from 'expo-router';
import { useTranslation } from 'react-i18next';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { Input } from '@/ui/primitives/input';
import { Button } from '@/ui/primitives/button';
import { ScreenHeader } from '@/ui/components/screen-header';
import { errorToast } from '@/ui/components/error-toast';
import { useTourDraftStore } from '@/state/stores/tour-draft-store';
import { haptics } from '@/ui/motion/haptics';

export default function OptimizedConfigScreen() {
  const { t } = useTranslation();
  const router = useRouter();
  const setConfig = useTourDraftStore((s) => s.setOptimizedConfig);

  const [targetMinutes, setTargetMinutes] = useState('480');
  const [commune, setCommune] = useState('');
  const [targetTouched, setTargetTouched] = useState(false);

  const errors = useMemo(() => {
    const out: { targetMinutes?: string } = {};
    const m = parseInt(targetMinutes, 10);
    if (isNaN(m) || m <= 0) out.targetMinutes = t('tours.optimized_config_error_minutes');
    return out;
  }, [targetMinutes, t]);

  const canSubmit = !errors.targetMinutes;

  const onContinue = () => {
    setTargetTouched(true);
    if (!canSubmit) {
      void haptics.error();
      errorToast(t('tours.optimized_config_error_minutes'));
      return;
    }
    setConfig({
      targetMinutes: parseInt(targetMinutes, 10),
      commune: commune.trim() || null,
    });
    router.push('/(tabs)/tours/new/pick-clients' as never);
  };

  return (
    <Surface className="flex-1">
      <ScreenHeader title={t('tours.create_optimized')} />
      <ScrollView contentContainerStyle={{ paddingHorizontal: 16, paddingTop: 8, paddingBottom: 32, gap: 16 }}>

        <Surface variant="muted" className="rounded-2xl px-4 py-3">
          <Text variant="muted" className="text-sm">{t('tours.optimized_config_help')}</Text>
        </Surface>

        <View className="gap-2">
          <Text className="text-sm font-medium">{t('tours.optimized_target_minutes')}</Text>
          <Input
            value={targetMinutes}
            onChangeText={setTargetMinutes}
            onBlur={() => setTargetTouched(true)}
            keyboardType="number-pad"
            placeholder="480"
          />
          {targetTouched && errors.targetMinutes ? (
            <Text className="text-sm text-danger dark:text-danger-dark">{errors.targetMinutes}</Text>
          ) : null}
        </View>

        <View className="gap-2">
          <Text className="text-sm font-medium">{t('tours.optimized_commune')}</Text>
          <Input
            value={commune}
            onChangeText={setCommune}
            placeholder={t('tours.optimized_commune_placeholder')}
            autoCapitalize="words"
          />
        </View>

        <Button onPress={onContinue} disabled={!canSubmit}>
          {t('tours.optimized_continue')}
        </Button>

      </ScrollView>
    </Surface>
  );
}
