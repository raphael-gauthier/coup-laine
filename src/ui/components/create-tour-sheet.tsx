import { Modal, TouchableOpacity, View } from 'react-native';
import { useTranslation } from 'react-i18next';
import { ChevronRight, Pencil, Sparkles, X } from 'lucide-react-native';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { PressScale } from '@/ui/motion/press-scale';
import { haptics } from '@/ui/motion/haptics';

interface Props {
  visible: boolean;
  onClose: () => void;
  onPickManual: () => void;
  onPickOptimized: () => void;
}

export function CreateTourSheet({ visible, onClose, onPickManual, onPickOptimized }: Props) {
  const { t } = useTranslation();

  const pick = (handler: () => void) => () => {
    void haptics.selection();
    handler();
  };

  return (
    <Modal visible={visible} animationType="slide" transparent presentationStyle="overFullScreen" onRequestClose={onClose}>
      <TouchableOpacity
        style={{ flex: 1, backgroundColor: 'rgba(0,0,0,0.4)' }}
        onPress={onClose}
        activeOpacity={1}
      />
      <Surface className="rounded-t-3xl px-4 pt-4 pb-8">
        <View className="flex-row items-start justify-between mb-1">
          <View className="flex-1 pr-2">
            <Text className="text-lg font-semibold">{t('tours.create_sheet_title')}</Text>
            <Text variant="muted" className="text-sm mt-0.5">
              {t('tours.create_sheet_subtitle')}
            </Text>
          </View>
          <PressScale
            onPress={onClose}
            className="p-1"
            accessibilityLabel={t('common.close')}
          >
            <X size={22} color="#5C4E40" />
          </PressScale>
        </View>

        <View className="gap-2 mt-4">
          <PressScale onPress={pick(onPickManual)} accessibilityLabel={t('tours.create_manual')}>
            <Surface
              variant="muted"
              className="flex-row items-center rounded-2xl px-4 py-4 gap-3"
            >
              <View className="w-10 h-10 rounded-full bg-background dark:bg-background-dark items-center justify-center">
                <Pencil size={20} color="#5C4E40" />
              </View>
              <View className="flex-1">
                <Text className="font-semibold text-base">{t('tours.create_manual')}</Text>
                <Text variant="muted" className="text-sm mt-0.5">
                  {t('tours.create_manual_hint')}
                </Text>
              </View>
              <ChevronRight size={18} color="#5C4E40" />
            </Surface>
          </PressScale>

          <PressScale onPress={pick(onPickOptimized)} accessibilityLabel={t('tours.create_optimized')}>
            <Surface
              variant="muted"
              className="flex-row items-center rounded-2xl px-4 py-4 gap-3"
            >
              <View className="w-10 h-10 rounded-full bg-background dark:bg-background-dark items-center justify-center">
                <Sparkles size={20} color="#5C4E40" />
              </View>
              <View className="flex-1">
                <Text className="font-semibold text-base">{t('tours.create_optimized')}</Text>
                <Text variant="muted" className="text-sm mt-0.5">
                  {t('tours.create_optimized_hint')}
                </Text>
              </View>
              <ChevronRight size={18} color="#5C4E40" />
            </Surface>
          </PressScale>
        </View>
      </Surface>
    </Modal>
  );
}
