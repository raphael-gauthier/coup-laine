import { Modal, ScrollView, TouchableOpacity, View } from 'react-native';
import { useTranslation } from 'react-i18next';
import { X } from 'lucide-react-native';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { PressScale } from '@/ui/motion/press-scale';
import { usePaymentMethods } from '@/state/queries/payment-methods';
import type { PaymentMethod } from '@/domain/models/payment-method';

interface Props {
  visible: boolean;
  selectedId: string | null;
  onPick: (method: PaymentMethod) => void;
  onClose: () => void;
}

export function PaymentMethodPicker({ visible, selectedId, onPick, onClose }: Props) {
  const { t } = useTranslation();
  const { data: methods = [] } = usePaymentMethods('active');

  return (
    <Modal visible={visible} animationType="slide" transparent presentationStyle="overFullScreen">
      <TouchableOpacity
        style={{ flex: 1, backgroundColor: 'rgba(0,0,0,0.4)' }}
        onPress={onClose}
        activeOpacity={1}
      />
      <Surface className="rounded-t-3xl px-4 pb-8 pt-4" style={{ maxHeight: '65%' }}>
        <View className="flex-row items-center justify-between mb-4">
          <Text className="text-lg font-semibold">{t('payments.method_picker_title')}</Text>
          <PressScale onPress={onClose} accessibilityLabel={t('common.close')}>
            <X size={22} color="#5C4E40" />
          </PressScale>
        </View>
        <ScrollView>
          {methods.map((m) => (
            <PressScale key={m.id} onPress={() => onPick(m)} accessibilityLabel={m.label}>
              <View
                className={`flex-row items-center px-4 py-3 rounded-xl mb-1 ${selectedId === m.id ? 'bg-primary dark:bg-primary-dark' : ''}`}
              >
                <Text
                  className={selectedId === m.id ? 'text-primary-foreground dark:text-primary-dark-foreground' : ''}
                >
                  {m.label}
                </Text>
              </View>
            </PressScale>
          ))}
        </ScrollView>
      </Surface>
    </Modal>
  );
}
