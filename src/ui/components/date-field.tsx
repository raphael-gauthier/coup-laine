import { useEffect, useState } from 'react';
import { Platform, View, useColorScheme } from 'react-native';
import MaskInput from 'react-native-mask-input';
import DateTimePicker from '@react-native-community/datetimepicker';
import { Calendar } from 'lucide-react-native';
import { useTranslation } from 'react-i18next';
import { format } from 'date-fns';

import { PressScale } from '@/ui/motion/press-scale';
import { FormField } from '@/ui/components/form-field';
import { useForegroundColor, useMutedForegroundColor } from '@/ui/theme/colors';
import { parseDateInput } from '@/domain/use-cases/parse-date-input';

const DATE_MASK = [/\d/, /\d/, '/', /\d/, /\d/, '/', /\d/, /\d/, /\d/, /\d/];

interface Props {
  label: string;
  value: Date | null;
  onChange: (date: Date | null) => void;
  onValidityChange?: (valid: boolean) => void;
  /** When false, an empty field is valid and emits `onChange(null)`. Default: true. */
  required?: boolean;
  accessibilityLabel?: string;
}

export function DateField({
  label, value, onChange, onValidityChange, required = true, accessibilityLabel,
}: Props) {
  const { t } = useTranslation();
  const fg = useForegroundColor();
  const mutedFg = useMutedForegroundColor();
  const isDark = useColorScheme() === 'dark';
  const [text, setText] = useState(value ? format(value, 'dd/MM/yyyy') : '');
  const [error, setError] = useState<string | null>(null);
  const [pickerOpen, setPickerOpen] = useState(false);

  // Resync the buffer when the committed value changes from outside
  // (e.g. the season screen's "Aujourd'hui" reset button).
  useEffect(() => {
    setText(value ? format(value, 'dd/MM/yyyy') : '');
    setError(null);
    onValidityChange?.(true);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [value]);

  const handleText = (masked: string) => {
    setText(masked);
    const result = parseDateInput(masked);
    if (result.ok) {
      setError(null);
      onValidityChange?.(true);
      onChange(result.date);
    } else if (result.reason === 'empty' && !required) {
      setError(null);
      onValidityChange?.(true);
      onChange(null);
    } else {
      setError(t('dateField.invalid'));
      onValidityChange?.(false);
    }
  };

  const handlePicked = (d: Date) => {
    setText(format(d, 'dd/MM/yyyy'));
    setError(null);
    onValidityChange?.(true);
    onChange(d);
  };

  return (
    <FormField label={label} error={error ?? undefined}>
      <View className="flex-row items-center rounded-2xl border border-border dark:border-border-dark bg-input dark:bg-input-dark px-4">
        <MaskInput
          value={text}
          onChangeText={handleText}
          mask={DATE_MASK}
          keyboardType="number-pad"
          placeholder={t('dateField.placeholder')}
          placeholderTextColor={isDark ? '#B4A490' : '#5C4E40'}
          style={{ flex: 1, paddingVertical: 12, fontSize: 16, color: fg }}
          accessibilityLabel={accessibilityLabel ?? label}
        />
        <PressScale
          onPress={() => setPickerOpen(true)}
          accessibilityLabel={t('dateField.open_picker')}
          className="pl-2 py-2"
        >
          <Calendar size={20} color={mutedFg} />
        </PressScale>
      </View>
      {pickerOpen ? (
        <DateTimePicker
          value={value ?? new Date()}
          mode="date"
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
