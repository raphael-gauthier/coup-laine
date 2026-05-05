import { useEffect, useState } from 'react';
import { ScrollView, View } from 'react-native';
import { useRouter } from 'expo-router';
import { useTranslation } from 'react-i18next';
import { Briefcase } from 'lucide-react-native';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { Button } from '@/ui/primitives/button';
import { PressScale } from '@/ui/motion/press-scale';
import { haptics } from '@/ui/motion/haptics';
import { cn } from '@/lib/cn';
import { PROFESSION_PRESETS } from '@/domain/catalog/profession-catalog';
import { useUserProfessions, useSetUserProfessions } from '@/state/queries/settings';
import { usePrimaryColor } from '@/ui/theme/colors';

export default function OnboardingProfessionScreen() {
  const { t } = useTranslation();
  const router = useRouter();
  const { data: persisted = [] } = useUserProfessions();
  const setProfessions = useSetUserProfessions();
  const primary = usePrimaryColor();
  const [selected, setSelected] = useState<Set<string>>(new Set());
  const [hydrated, setHydrated] = useState(false);

  useEffect(() => {
    if (!hydrated && persisted.length > 0) {
      setSelected(new Set(persisted));
      setHydrated(true);
    }
  }, [persisted, hydrated]);

  const toggle = (id: string) => {
    void haptics.selection();
    setSelected((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  };

  const onContinue = () => {
    setProfessions.mutate(Array.from(selected), {
      onSuccess: () => {
        void haptics.success();
        router.push('/onboarding/species' as never);
      },
    });
  };

  const onSkip = () => {
    setProfessions.mutate([], {
      onSuccess: () => router.push('/onboarding/species' as never),
    });
  };

  return (
    <Surface className="flex-1">
      <ScrollView contentContainerStyle={{ flexGrow: 1, padding: 24, gap: 24 }}>
        <View className="items-center gap-3 mt-12">
          <Briefcase size={48} color={primary} />
          <Text className="text-2xl font-bold text-center">{t('onboarding.profession.title')}</Text>
          <Text variant="muted" className="text-center">{t('onboarding.profession.message')}</Text>
        </View>

        <View className="flex-row flex-wrap gap-2 mt-2">
          {PROFESSION_PRESETS.map((m) => {
            const active = selected.has(m.id);
            return (
              <PressScale key={m.id} onPress={() => toggle(m.id)} accessibilityLabel={m.label}>
                <View
                  className={cn(
                    'rounded-full px-4 py-2 border',
                    active
                      ? 'bg-primary dark:bg-primary-dark border-primary dark:border-primary-dark'
                      : 'bg-muted dark:bg-muted-dark border-border dark:border-border-dark'
                  )}
                >
                  <Text variant={active ? 'onPrimary' : 'default'} className="font-medium">
                    {m.label}
                  </Text>
                </View>
              </PressScale>
            );
          })}
        </View>

        <View style={{ flex: 1 }} />

        <Button
          onPress={onContinue}
          disabled={setProfessions.isPending}
          loading={setProfessions.isPending}
          accessibilityLabel={t('onboarding.profession.cta')}
        >
          <Text variant="onPrimary" className="font-semibold">{t('onboarding.profession.cta')}</Text>
        </Button>

        <Button variant="secondary" onPress={onSkip} disabled={setProfessions.isPending}>
          {t('onboarding.profession.skip')}
        </Button>
      </ScrollView>
    </Surface>
  );
}
