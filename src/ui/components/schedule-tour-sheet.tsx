import { useState } from 'react';
import { Modal, Platform, TouchableOpacity, View } from 'react-native';
import DateTimePicker from '@react-native-community/datetimepicker';
import { format } from 'date-fns';
import { fr } from 'date-fns/locale';
import { useTranslation } from 'react-i18next';
import { X } from 'lucide-react-native';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { Button } from '@/ui/primitives/button';
import { PressScale } from '@/ui/motion/press-scale';

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
  const [showDatePicker, setShowDatePicker] = useState(false);
  const [showTimePicker, setShowTimePicker] = useState(false);

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

        <View className="gap-2 mb-4">
          <Text className="text-sm font-medium">{t('tours.scheduled_date')}</Text>
          <PressScale
            onPress={() => setShowDatePicker(true)}
            accessibilityLabel={t('tours.scheduled_date')}
          >
            <Surface variant="muted" className="rounded-2xl px-4 py-3">
              <Text>{format(date, 'PPPP', { locale: fr })}</Text>
            </Surface>
          </PressScale>
          {showDatePicker ? (
            <DateTimePicker
              value={date}
              mode="date"
              onChange={(_, d) => {
                setShowDatePicker(Platform.OS === 'ios');
                if (d) setDate(d);
              }}
            />
          ) : null}
        </View>

        <View className="gap-2 mb-4">
          <Text className="text-sm font-medium">{t('tours.departure_time')}</Text>
          <PressScale
            onPress={() => setShowTimePicker(true)}
            accessibilityLabel={t('tours.departure_time')}
          >
            <Surface variant="muted" className="rounded-2xl px-4 py-3">
              <Text>{time}</Text>
            </Surface>
          </PressScale>
          {showTimePicker ? (
            <DateTimePicker
              value={(() => {
                const [h, m] = time.split(':').map(Number);
                const d = new Date();
                d.setHours(h ?? 0, m ?? 0, 0, 0);
                return d;
              })()}
              mode="time"
              is24Hour
              onChange={(_, d) => {
                setShowTimePicker(Platform.OS === 'ios');
                if (d) setTime(format(d, 'HH:mm'));
              }}
            />
          ) : null}
        </View>

        <View className="flex-row gap-2">
          <Button variant="ghost" className="flex-1" onPress={onClose}>
            {t('common.cancel')}
          </Button>
          <Button className="flex-1" onPress={confirm}>
            {t('tours.schedule_sheet_confirm')}
          </Button>
        </View>
      </Surface>
    </Modal>
  );
}
