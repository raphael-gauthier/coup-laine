import { useState } from 'react';
import { Modal, TouchableOpacity, View } from 'react-native';
import { format } from 'date-fns';
import { useTranslation } from 'react-i18next';
import { X } from 'lucide-react-native';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { Button } from '@/ui/primitives/button';
import { PressScale } from '@/ui/motion/press-scale';
import { DateField } from '@/ui/components/date-field';
import { TimeField } from '@/ui/components/time-field';

interface Props {
  visible: boolean;
  initialDate: Date | null;
  initialTime: string | null;
  onClose: () => void;
  onConfirm: (input: { scheduledDate: string; departureTime: string }) => void;
}

export function ScheduleTourSheet({ visible, initialDate, initialTime, onClose, onConfirm }: Props) {
  const { t } = useTranslation();
  const [date, setDate] = useState<Date>(initialDate ?? new Date());
  const [time, setTime] = useState<string>(initialTime ?? '08:00');
  const [dateValid, setDateValid] = useState(true);
  const [timeValid, setTimeValid] = useState(true);

  const confirm = () => {
    onConfirm({
      scheduledDate: format(date, 'yyyy-MM-dd'),
      departureTime: time,
    });
  };

  return (
    <Modal
      visible={visible}
      animationType="slide"
      transparent
      presentationStyle="overFullScreen"
      onRequestClose={onClose}
    >
      <TouchableOpacity
        style={{ flex: 1, backgroundColor: 'rgba(0,0,0,0.4)' }}
        onPress={onClose}
        activeOpacity={1}
      />
      <Surface className="rounded-t-3xl px-4 pt-4 pb-8">
        <View className="flex-row items-center justify-between mb-4">
          <Text className="text-lg font-semibold">{t('tours.schedule_sheet_title')}</Text>
          <PressScale onPress={onClose} className="p-1" accessibilityLabel={t('common.close')}>
            <X size={22} color="#5C4E40" />
          </PressScale>
        </View>

        <View className="mb-4">
          <DateField
            label={t('tours.scheduled_date')}
            value={date}
            onChange={(d) => { if (d) setDate(d); }}
            onValidityChange={setDateValid}
          />
        </View>

        <View className="mb-4">
          <TimeField
            label={t('tours.departure_time')}
            value={time}
            onChange={(v) => { if (v) setTime(v); }}
            onValidityChange={setTimeValid}
          />
        </View>

        <View className="flex-row gap-2">
          <Button variant="ghost" className="flex-1" onPress={onClose}>
            {t('common.cancel')}
          </Button>
          <Button className="flex-1" onPress={confirm} disabled={!dateValid || !timeValid}>
            {t('tours.schedule_sheet_confirm')}
          </Button>
        </View>
      </Surface>
    </Modal>
  );
}
