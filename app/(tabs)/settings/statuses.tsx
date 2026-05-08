import { useState } from 'react';
import { ScrollView, View } from 'react-native';
import { useTranslation } from 'react-i18next';
import { Plus } from 'lucide-react-native';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { Button } from '@/ui/primitives/button';
import { PressScale } from '@/ui/motion/press-scale';
import { ScreenHeader } from '@/ui/components/screen-header';
import { StatusEditSheet } from '@/ui/components/status-edit-sheet';
import { useStatusRegistry } from '@/state/queries/statuses';
import { useResolvedColorScheme } from '@/ui/theme/theme-provider';
import { haptics } from '@/ui/motion/haptics';
import type { Status } from '@/domain/models/status';

export default function StatusesScreen() {
  const { t } = useTranslation();
  const { data: registry } = useStatusRegistry();
  const scheme = useResolvedColorScheme();
  const [editing, setEditing] = useState<Status | null | 'new'>(null);

  const all = registry?.list ?? [];
  const system = all.filter((s) => s.kind === 'system');
  const manual = all.filter((s) => s.kind === 'manual');

  return (
    <Surface className="flex-1">
      <ScreenHeader title={t('statuses.screen_title')} />
      <ScrollView contentContainerStyle={{ paddingHorizontal: 16, paddingTop: 8, paddingBottom: 32, gap: 12 }}>
        <Text variant="muted" className="text-xs uppercase">{t('statuses.section_system')}</Text>
        {system.map((s) => (
          <Row key={s.id} status={s} scheme={scheme} onPress={() => { void haptics.selection(); setEditing(s); }} />
        ))}

        <Text variant="muted" className="text-xs uppercase mt-4">{t('statuses.section_manual')}</Text>
        {manual.map((s) => (
          <Row key={s.id} status={s} scheme={scheme} onPress={() => { void haptics.selection(); setEditing(s); }} />
        ))}

        <Button
          className="mt-2"
          variant="secondary"
          onPress={() => { void haptics.selection(); setEditing('new'); }}
          accessibilityLabel={t('statuses.new_status')}
        >
          <View className="flex-row items-center gap-2">
            <Plus size={16} color="#5C4E40" />
            <Text>{t('statuses.new_status')}</Text>
          </View>
        </Button>
      </ScrollView>

      <StatusEditSheet
        visible={editing !== null}
        status={editing === 'new' ? null : editing}
        onClose={() => setEditing(null)}
      />
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
