import { Modal, View, ScrollView, TouchableOpacity } from 'react-native';
import { X } from 'lucide-react-native';
import { useTranslation } from 'react-i18next';
import { router } from 'expo-router';
import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { Button } from '@/ui/primitives/button';
import { PressScale } from '@/ui/motion/press-scale';
import { useStatusRegistry } from '@/state/queries/statuses';
import { useResolvedColorScheme } from '@/ui/theme/theme-provider';

interface Props {
  visible: boolean;
  currentManualId: string | null;
  onSelect: (statusId: string | null) => void;
  onClose: () => void;
}

export function ManualStatusPicker({ visible, currentManualId, onSelect, onClose }: Props) {
  const { t } = useTranslation();
  const { data: registry } = useStatusRegistry();
  const scheme = useResolvedColorScheme();
  const manuals = (registry?.list ?? []).filter((s) => s.kind === 'manual');

  return (
    <Modal visible={visible} animationType="slide" transparent presentationStyle="overFullScreen">
      <TouchableOpacity style={{ flex: 1, backgroundColor: 'rgba(0,0,0,0.4)' }} onPress={onClose} activeOpacity={1} />
      <Surface className="rounded-t-3xl px-4 pb-8 pt-4">
        <View className="flex-row items-center justify-between mb-4">
          <Text className="text-lg font-semibold">{t('statuses.manual_picker_title')}</Text>
          <PressScale onPress={onClose} accessibilityLabel={t('common.close')}>
            <X size={22} color="#5C4E40" />
          </PressScale>
        </View>

        <ScrollView contentContainerStyle={{ paddingBottom: 8, gap: 8 }} style={{ maxHeight: 360 }}>
          <PressScale onPress={() => onSelect(null)} accessibilityLabel={t('statuses.manual_picker_none')}>
            <Surface variant="muted" className="flex-row items-center rounded-2xl px-4 py-3 gap-3">
              <View style={{ width: 16, height: 16, borderRadius: 8, borderWidth: 2, borderColor: '#DCD0C0' }} />
              <Text>{t('statuses.manual_picker_none')}</Text>
            </Surface>
          </PressScale>
          {manuals.length === 0 ? (
            <Text variant="muted" className="text-sm py-4">
              {t('statuses.manual_picker_empty')}
            </Text>
          ) : null}
          {manuals.map((s) => {
            const hex = scheme === 'dark' ? s.colorDark : s.colorLight;
            const selected = s.id === currentManualId;
            return (
              <PressScale key={s.id} onPress={() => onSelect(s.id)} accessibilityLabel={s.label}>
                <Surface variant="muted" className="flex-row items-center rounded-2xl px-4 py-3 gap-3">
                  <View
                    style={{
                      width: 16, height: 16, borderRadius: 8, backgroundColor: hex,
                      borderWidth: selected ? 2 : 0, borderColor: '#1C1612',
                    }}
                  />
                  <Text className="flex-1">{s.label}</Text>
                </Surface>
              </PressScale>
            );
          })}
        </ScrollView>

        <Button
          className="mt-2"
          variant="ghost"
          onPress={() => {
            onClose();
            router.push('/(tabs)/settings/statuses' as never);
          }}
        >
          {t('statuses.manual_picker_create')}
        </Button>
      </Surface>
    </Modal>
  );
}
