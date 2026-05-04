import { useColorScheme, View } from 'react-native';
import { Plus, X } from 'lucide-react-native';
import { useTranslation } from 'react-i18next';
import MaskInput from 'react-native-mask-input';
import { PressScale } from '@/ui/motion/press-scale';
import { Text } from '@/ui/primitives/text';
import { Button } from '@/ui/primitives/button';
import { useForegroundColor } from '@/ui/theme/colors';

interface Props {
  value: string[];
  onChange: (next: string[]) => void;
}

// French local phone format: 0X XX XX XX XX (10 digits in 5 pairs).
const FR_LOCAL_MASK = [
  /\d/, /\d/, ' ',
  /\d/, /\d/, ' ',
  /\d/, /\d/, ' ',
  /\d/, /\d/, ' ',
  /\d/, /\d/,
];

// Normalize any input form (+33…, 33…, legacy spaced storage, partial typing)
// to the masked local form "0X XX XX XX XX". The +33/33 prefix is stripped only
// once the digit run reaches 11+, so users typing "33" by hand aren't disturbed
// mid-entry.
function toLocalMasked(raw: string): string {
  if (!raw) return '';
  let digits = raw.replace(/\D/g, '');
  if (digits.startsWith('33') && digits.length >= 11) {
    digits = `0${digits.slice(2)}`;
  }
  digits = digits.slice(0, 10);
  return digits.match(/.{1,2}/g)?.join(' ') ?? digits;
}

export function PhonesEditor({ value, onChange }: Props) {
  const { t } = useTranslation();
  const isDark = useColorScheme() === 'dark';
  const fg = useForegroundColor();

  const update = (index: number, masked: string) => {
    const next = [...value];
    next[index] = toLocalMasked(masked);
    onChange(next);
  };
  const remove = (index: number) => onChange(value.filter((_, i) => i !== index));
  const add = () => onChange([...value, '']);

  const inputStyle = {
    flex: 1,
    backgroundColor: isDark ? '#302820' : '#EAE0D3',
    color: isDark ? '#F0E8DC' : '#1C1612',
    borderRadius: 16,
    paddingHorizontal: 16,
    paddingVertical: 12,
    fontSize: 15,
  } as const;

  return (
    <View className="gap-2">
      <Text className="text-sm font-medium">{t('clients.phones')}</Text>
      {value.map((phone, index) => (
        <View key={index} className="flex-row items-center gap-2">
          <MaskInput
            style={inputStyle}
            value={toLocalMasked(phone)}
            onChangeText={(masked) => update(index, masked)}
            mask={FR_LOCAL_MASK}
            keyboardType="phone-pad"
            placeholder="06 12 34 56 78"
            placeholderTextColor={isDark ? '#B4A490' : '#94816C'}
          />
          <PressScale onPress={() => remove(index)}>
            <View className="w-10 h-10 rounded-full items-center justify-center bg-muted dark:bg-muted-dark">
              <X size={18} color="#B23832" />
            </View>
          </PressScale>
        </View>
      ))}
      <Button variant="ghost" size="sm" onPress={add}>
        <Plus size={16} color={fg} />
        <Text className="font-semibold">{t('clients.add_phone')}</Text>
      </Button>
    </View>
  );
}
