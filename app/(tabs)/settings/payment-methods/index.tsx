import { useMemo, useState } from 'react';
import { View, ScrollView, TouchableOpacity } from 'react-native';
import { useRouter } from 'expo-router';
import { Plus, ChevronRight, ChevronDown, Wallet } from 'lucide-react-native';
import { useTranslation } from 'react-i18next';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { Button } from '@/ui/primitives/button';
import { Fab } from '@/ui/primitives/fab';
import { SectionHeader } from '@/ui/primitives/section-header';
import { ListSkeleton } from '@/ui/primitives/skeleton';
import { PressScale } from '@/ui/motion/press-scale';
import { EmptyState } from '@/ui/components/empty-state';
import { ErrorState } from '@/ui/components/error-state';
import { ScreenHeader } from '@/ui/components/screen-header';
import { usePaymentMethods } from '@/state/queries/payment-methods';
import { haptics } from '@/ui/motion/haptics';
import { useOnContrastColor, useMutedForegroundColor } from '@/ui/theme/colors';

export default function PaymentMethodsListScreen() {
  const { t } = useTranslation();
  const router = useRouter();
  const onContrast = useOnContrastColor();
  const mutedFg = useMutedForegroundColor();
  const { data: methods = [], isError, isLoading, refetch } = usePaymentMethods('all');

  const [archivedExpanded, setArchivedExpanded] = useState(false);

  const grouped = useMemo(() => {
    const active = methods.filter((m) => m.isActive);
    const archived = methods.filter((m) => !m.isActive);
    return { active, archived };
  }, [methods]);

  if (isError) return <ErrorState onRetry={() => refetch()} />;

  const isEmpty = methods.length === 0;

  return (
    <Surface className="flex-1">
      <ScreenHeader title={t('catalogs.payment_methods.list_title')} />
      {isLoading ? (
        <ListSkeleton />
      ) : isEmpty ? (
        <EmptyState
          icon={<Wallet size={48} color={mutedFg} />}
          title={t('catalogs.payment_methods.empty_title')}
          message={t('catalogs.payment_methods.empty_message')}
          action={
            <Button
              onPress={() => { void haptics.selection(); router.push('/(tabs)/settings/payment-methods/new' as never); }}
              accessibilityLabel={t('catalogs.payment_methods.empty_cta')}
            >
              <Plus size={16} color={onContrast} />
              <Text variant="onPrimary" className="font-semibold">
                {t('catalogs.payment_methods.empty_cta')}
              </Text>
            </Button>
          }
        />
      ) : (
        <ScrollView contentContainerStyle={{ paddingHorizontal: 16, paddingBottom: 96 }}>
          <SectionHeader title={t('catalogs.payment_methods.list_title')} />
          {grouped.active.map((m) => (
            <PressScale key={m.id} onPress={() => { void haptics.selection(); router.push(`/(tabs)/settings/payment-methods/${m.id}` as never); }} accessibilityLabel={m.label}>
              <Surface variant="muted" className="flex-row items-center rounded-2xl px-4 py-3 gap-3 mb-2">
                <Text className="font-semibold flex-1">{m.label}</Text>
                <ChevronRight size={18} color={mutedFg} />
              </Surface>
            </PressScale>
          ))}

          {grouped.archived.length > 0 ? (
            <View>
              <TouchableOpacity onPress={() => setArchivedExpanded(!archivedExpanded)}>
                <View className="flex-row items-center justify-between pt-4 pb-1 px-1">
                  <Text variant="muted" className="text-xs font-semibold uppercase tracking-widest">
                    {t('catalogs.payment_methods.archived_section')} ({grouped.archived.length})
                  </Text>
                  {archivedExpanded ? <ChevronDown size={14} color={mutedFg} /> : <ChevronRight size={14} color={mutedFg} />}
                </View>
              </TouchableOpacity>
              {archivedExpanded ? grouped.archived.map((m) => (
                <PressScale key={m.id} onPress={() => router.push(`/(tabs)/settings/payment-methods/${m.id}` as never)} accessibilityLabel={m.label}>
                  <Surface variant="muted" className="flex-row items-center rounded-2xl px-4 py-3 gap-3 mb-2">
                    <Text className="font-semibold flex-1">{m.label}</Text>
                    <Text variant="muted" className="text-xs">{t('catalogs.payment_methods.inactive_badge')}</Text>
                    <ChevronRight size={18} color={mutedFg} />
                  </Surface>
                </PressScale>
              )) : null}
            </View>
          ) : null}
        </ScrollView>
      )}

      <Fab icon={Plus} onPress={() => router.push('/(tabs)/settings/payment-methods/new' as never)} accessibilityLabel={t('catalogs.payment_methods.new_title')} />
    </Surface>
  );
}
