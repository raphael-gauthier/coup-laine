import { View } from 'react-native';
import { Plus, X } from 'lucide-react-native';
import { useTranslation } from 'react-i18next';
import { PressScale } from '@/ui/motion/press-scale';
import { Input } from '@/ui/primitives/input';
import { Text } from '@/ui/primitives/text';
import { Button } from '@/ui/primitives/button';
import { formatPhone } from '@/lib/phone-formatter';

interface Props {
  value: string[];
  onChange: (next: string[]) => void;
}

export function PhonesEditor({ value, onChange }: Props) {
  const { t } = useTranslation();

  const update = (index: number, raw: string) => {
    const next = [...value];
    next[index] = raw;
    onChange(next);
  };
  const remove = (index: number) => {
    onChange(value.filter((_, i) => i !== index));
  };
  const add = () => onChange([...value, '']);

  return (
    <View className="gap-2">
      <Text className="text-sm font-medium">{t('clients.phones')}</Text>
      {value.map((phone, index) => (
        <View key={index} className="flex-row items-center gap-2">
          <Input
            value={phone}
            onChangeText={(v) => update(index, v)}
            onBlur={() => update(index, formatPhone(phone))}
            keyboardType="phone-pad"
            placeholder={t('clients.phone_placeholder')}
            className="flex-1"
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
