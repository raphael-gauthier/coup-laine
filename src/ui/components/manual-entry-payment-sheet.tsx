import { useEffect, useState } from 'react';
import { Modal, TouchableOpacity, View } from 'react-native';
import { useTranslation } from 'react-i18next';
import { X } from 'lucide-react-native';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { Button } from '@/ui/primitives/button';
import { PressScale } from '@/ui/motion/press-scale';
import { PaymentEditor } from '@/ui/components/payment-editor';
import { useMarkManualEntryPayment } from '@/state/queries/history';
import { haptics } from '@/ui/motion/haptics';
import type { Payment } from '@/domain/models/payment';

interface Props {
  visible: boolean;
  entryId: string | null;
  clientId: string;
  initial: Payment | null;
  onClose: () => void;
}

export function ManualEntryPaymentSheet({ visible, entryId, clientId, initial, onClose }: Props) {
  const { t } = useTranslation();
  const [draft, setDraft] = useState<Payment>(initial ?? {
    methodId: null, methodLabelSnapshot: null, isPaid: false, paidAt: null,
  });
  const [error, setError] = useState<string | null>(null);
  const mark = useMarkManualEntryPayment();

  useEffect(() => { if (visible && initial) setDraft(initial); }, [visible, initial]);

  if (!entryId) return null;

  const onSave = () => {
    if (draft.isPaid && !draft.methodId) {
      setError(t('payments.method_required'));
      void haptics.error();
      return;
    }
    setError(null);
    mark.mutate({ entryId, clientId, payment: draft }, {
      onSuccess: () => { void haptics.success(); onClose(); },
    });
  };

  return (
    <Modal visible={visible} animationType="slide" transparent presentationStyle="overFullScreen">
      <TouchableOpacity style={{ flex: 1, backgroundColor: 'rgba(0,0,0,0.4)' }} onPress={onClose} activeOpacity={1} />
      <Surface className="rounded-t-3xl px-4 pb-8 pt-4" style={{ maxHeight: '85%' }}>
        <View className="flex-row items-center justify-between mb-4">
          <Text className="text-lg font-semibold">{t('payments.editor_title')}</Text>
          <PressScale onPress={onClose} accessibilityLabel={t('common.close')}>
            <X size={22} color="#5C4E40" />
          </PressScale>
        </View>
        <PaymentEditor value={draft} onChange={setDraft} methodError={error} />
        <Button className="mt-4" onPress={onSave} loading={mark.isPending}>
          {t('common.save')}
        </Button>
      </Surface>
    </Modal>
  );
}
