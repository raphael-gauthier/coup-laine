import { useColorScheme, View } from 'react-native';
import { Plus, X } from 'lucide-react-native';
import { useTranslation } from 'react-i18next';
import MaskInput from 'react-native-mask-input';
import { PressScale } from '@/ui/motion/press-scale';
import { Text } from '@/ui/primitives/text';
import { Button } from '@/ui/primitives/button';

interface Props {
  value: string[];
  onChange: (next: string[]) => void;
}

// French phone format: +33 X XX XX XX XX (9 digits after +33)
const FR_PHONE_MASK = [
  '+', '3', '3', ' ',
  /\d/, ' ',
  /\d/, /\d/, ' ',
  /\d/, /\d/, ' ',
  /\d/, /\d/, ' ',
  /\d/, /\d/,
];

function ensurePrefix(raw: string): string {
  if (!raw) return '+33 ';
  // Accept legacy "06 12 34 56 78" by converting to +33 form
  const digits = raw.replace(/\D/g, '');
  if (digits.startsWith('33')) return `+${digits}`;
  if (digits.startsWith('0')) return `+33${digits.slice(1)}`;
  return raw.startsWith('+') ? raw : `+33${digits}`;
}

export function PhonesEditor({ value, onChange }: Props) {
  const { t } = useTranslation();
  const isDark = useColorScheme() === 'dark';

  const update = (index: number, masked: string) => {
    const next = [...value];
    next[index] = masked;
    onChange(next);
  };
  const remove = (index: number) => onChange(value.filter((_, i) => i !== index));
  const add = () => onChange([...value, '+33 ']);

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
            value={ensurePrefix(phone)}
            onChangeText={(masked) => update(index, masked)}
            mask={FR_PHONE_MASK}
            keyboardType="phone-pad"
            placeholder="+33 6 12 34 56 78"
            placeholderTextColor={isDark ? '#5C4E40' : '#94816C'}
          />
          <PressScale onPress={() => remove(index)}>
            <View className="w-10 h-10 rounded-full items-center justify-center bg-muted dark:bg-muted-dark">
              <X size={18} color="#B23832" />
            </View>
          </PressScale>
        </View>
      ))}
      <Button variant="ghost" size="sm" onPress={add}>
        <Plus size={16} />
        <Text className="font-semibold">{t('clients.add_phone')}</Text>
      </Button>
    </View>
  );
}
