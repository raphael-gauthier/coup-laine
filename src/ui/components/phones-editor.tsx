import { useColorScheme, View } from 'react-native';
import { Plus, X } from 'lucide-react-native';
import { useTranslation } from 'react-i18next';
import { PhoneInput } from 'react-native-phone-entry';
import { PressScale } from '@/ui/motion/press-scale';
import { Text } from '@/ui/primitives/text';
import { Button } from '@/ui/primitives/button';

interface Props {
  value: string[];
  onChange: (next: string[]) => void;
}

export function PhonesEditor({ value, onChange }: Props) {
  const { t } = useTranslation();
  const isDark = useColorScheme() === 'dark';

  const update = (index: number, raw: string) => {
    const next = [...value];
    next[index] = raw;
    onChange(next);
  };
  const remove = (index: number) => onChange(value.filter((_, i) => i !== index));
  const add = () => onChange([...value, '']);

  return (
    <View className="gap-2">
      <Text className="text-sm font-medium">{t('clients.phones')}</Text>
      {value.map((phone, index) => (
        <View key={index} className="flex-row items-center gap-2">
          <View className="flex-1">
            <PhoneInput
              defaultValues={{
                countryCode: 'FR',
                callingCode: '+33',
                phoneNumber: phone || '+33',
              }}
              value={phone}
              onChangeText={(text) => update(index, text)}
              countryPickerProps={{ withFilter: true, withFlag: true, withAlphaFilter: true }}
              theme={{
                containerStyle: {
                  backgroundColor: isDark ? '#302820' : '#EAE0D3',
                  borderRadius: 16,
                  height: 48,
                  borderWidth: 0,
                },
                textInputStyle: {
                  fontSize: 15,
                  color: isDark ? '#F0E8DC' : '#1C1612',
                },
                codeTextStyle: {
                  fontSize: 15,
                  color: isDark ? '#F0E8DC' : '#1C1612',
                  fontWeight: '600',
                },
                flagButtonStyle: { paddingHorizontal: 8 },
                enableDarkTheme: isDark,
              }}
            />
          </View>
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
