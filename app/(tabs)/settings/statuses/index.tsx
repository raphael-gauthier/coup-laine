import { ScrollView, View } from 'react-native';
import { useRouter } from 'expo-router';
import { useTranslation } from 'react-i18next';
import { Plus } from 'lucide-react-native';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { Fab } from '@/ui/primitives/fab';
import { PressScale } from '@/ui/motion/press-scale';
import { ScreenHeader } from '@/ui/components/screen-header';
import { useStatusRegistry } from '@/state/queries/statuses';
import { useResolvedColorScheme } from '@/ui/theme/theme-provider';
import { haptics } from '@/ui/motion/haptics';
import type { Status } from '@/domain/models/status';
import { TUTORIAL_KEYS } from '@/domain/tutorial/keys';
import { HelpButton } from '@/ui/help/help-button';
import { HelpSheetStatuses } from '@/ui/help/sheets/help-sheet-statuses';
import { useHelpSheet } from '@/ui/help/hooks';

export default function StatusesListScreen() {
  const { t } = useTranslation();
  const router = useRouter();
  const { data: registry } = useStatusRegistry();
  const scheme = useResolvedColorScheme();
  const helpSheet = useHelpSheet(TUTORIAL_KEYS.sheetStatuses);

  const all = registry?.list ?? [];
  const system = all.filter((s) => s.kind === 'system');
  const manual = all.filter((s) => s.kind === 'manual');

  const open = (s: Status) => {
    void haptics.selection();
    router.push(`/(tabs)/settings/statuses/${s.id}` as never);
  };

  return (
    <Surface className="flex-1">
      <ScreenHeader
        title={t('statuses.screen_title')}
        rightSlot={<HelpButton tutorialKey={TUTORIAL_KEYS.sheetStatuses} onPress={helpSheet.open} />}
      />
      <ScrollView contentContainerStyle={{ paddingHorizontal: 16, paddingTop: 8, paddingBottom: 96, gap: 12 }}>
        <Text variant="muted" className="text-xs uppercase">{t('statuses.section_system')}</Text>
        {system.map((s) => (
          <Row key={s.id} status={s} scheme={scheme} onPress={() => open(s)} />
        ))}

        <Text variant="muted" className="text-xs uppercase mt-4">{t('statuses.section_manual')}</Text>
        {manual.map((s) => (
          <Row key={s.id} status={s} scheme={scheme} onPress={() => open(s)} />
        ))}
      </ScrollView>

      <Fab
        icon={Plus}
        onPress={() => router.push('/(tabs)/settings/statuses/new' as never)}
        accessibilityLabel={t('statuses.new_status')}
      />

      <HelpSheetStatuses visible={helpSheet.isOpen} onClose={helpSheet.close} />
    </Surface>
  );
}

function Row({
  status, scheme, onPress,
}: { status: Status; scheme: 'light' | 'dark'; onPress: () => void }) {
  const hex = scheme === 'dark' ? status.colorDark : status.colorLight;
  return (
    <PressScale onPress={onPress} accessibilityLabel={status.label}>
      <Surface variant="muted" className="flex-row items-center rounded-2xl px-4 py-3 gap-3">
        <View
          style={{
            width: 24, height: 24, borderRadius: 12, backgroundColor: hex,
            borderWidth: 2, borderColor: '#DCD0C0',
          }}
        />
        <View className="flex-1">
          <Text className="font-medium">{status.label}</Text>
        </View>
      </Surface>
    </PressScale>
  );
}
