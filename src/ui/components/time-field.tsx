import { useEffect, useState } from 'react';
import { Platform, View, useColorScheme } from 'react-native';
import MaskInput from 'react-native-mask-input';
import DateTimePicker from '@react-native-community/datetimepicker';
import { Clock } from 'lucide-react-native';
import { useTranslation } from 'react-i18next';
import { format } from 'date-fns';

import { PressScale } from '@/ui/motion/press-scale';
import { FormField } from '@/ui/components/form-field';
import { useForegroundColor, useMutedForegroundColor } from '@/ui/theme/colors';
import { parseTimeInput } from '@/domain/use-cases/parse-date-input';

const TIME_MASK = [/\d/, /\d/, ':', /\d/, /\d/];

function timeToDate(value: string | null): Date {
  const [h, m] = (value ?? '08:00').split(':').map(Number);
  const d = new Date();
  d.setHours(h ?? 0, m ?? 0, 0, 0);
  return d;
}

interface Props {
  label: string;
  value: string | null; // 'HH:mm'
  onChange: (value: string | null) => void;
  onValidityChange?: (valid: boolean) => void;
  /** When false, an empty field is valid and emits `onChange(null)`. Default: true. */
  required?: boolean;
  accessibilityLabel?: string;
}

export function TimeField({
  label, value, onChange, onValidityChange, required = true, accessibilityLabel,
}: Props) {
  const { t } = useTranslation();
  const fg = useForegroundColor();
  const mutedFg = useMutedForegroundColor();
  const isDark = useColorScheme() === 'dark';
  const [text, setText] = useState(value ?? '');
  const [error, setError] = useState<string | null>(null);
  const [pickerOpen, setPickerOpen] = useState(false);

  useEffect(() => {
    setText(value ?? '');
    setError(null);
    onValidityChange?.(true);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [value]);

  const handleText = (masked: string) => {
    setText(masked);
    const result = parseTimeInput(masked);
    if (result.ok) {
      setError(null);
      onValidityChange?.(true);
      onChange(result.value);
    } else if (result.reason === 'empty' && !required) {
      setError(null);
      onValidityChange?.(true);
      onChange(null);
    } else {
      setError(t('timeField.invalid'));
      onValidityChange?.(false);
    }
  };

  const handlePicked = (d: Date) => {
    const next = format(d, 'HH:mm');
    setText(next);
    setError(null);
    onValidityChange?.(true);
    onChange(next);
  };

  return (
    <FormField label={label} error={error ?? undefined}>
      <View className="flex-row items-center rounded-2xl border border-border dark:border-border-dark bg-input dark:bg-input-dark px-4">
        <MaskInput
          value={text}
          onChangeText={handleText}
          mask={TIME_MASK}
          keyboardType="number-pad"
          placeholder={t('timeField.placeholder')}
          placeholderTextColor={isDark ? '#B4A490' : '#5C4E40'}
          style={{ flex: 1, paddingVertical: 12, fontSize: 16, color: fg }}
          accessibilityLabel={accessibilityLabel ?? label}
        />
        <PressScale
          onPress={() => setPickerOpen(true)}
          accessibilityLabel={t('timeField.open_picker')}
          className="pl-2 py-2"
        >
          <Clock size={20} color={mutedFg} />
        </PressScale>
      </View>
      {pickerOpen ? (
        <DateTimePicker
          value={timeToDate(value)}
          mode="time"
          is24Hour
          onValueChange={(_, d) => {
            setPickerOpen(Platform.OS === 'ios');
            handlePicked(d);
          }}
          onDismiss={() => setPickerOpen(false)}
        />
      ) : null}
    </FormField>
  );
}
