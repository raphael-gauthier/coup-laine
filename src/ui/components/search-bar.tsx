import { View } from 'react-native';
import { Search, X } from 'lucide-react-native';
import { useTranslation } from 'react-i18next';
import { PressScale } from '@/ui/motion/press-scale';
import { Input } from '@/ui/primitives/input';

interface Props {
  value: string;
  onChange: (v: string) => void;
  placeholder?: string;
  accessibilityLabel?: string;
}

export function SearchBar({ value, onChange, placeholder, accessibilityLabel }: Props) {
  const { t } = useTranslation();
  return (
    <View className="flex-row items-center gap-2 px-3 py-2 rounded-2xl bg-muted dark:bg-muted-dark">
      <Search size={18} color="#5C4E40" />
      <Input
        value={value}
        onChangeText={onChange}
        placeholder={placeholder}
        className="flex-1 border-0 bg-transparent dark:bg-transparent px-0 py-0"
        autoCapitalize="none"
        autoCorrect={false}
        accessibilityLabel={accessibilityLabel ?? placeholder ?? t('common.search')}
      />
      {value.length > 0 ? (
        <PressScale onPress={() => onChange('')} accessibilityLabel={t('common.dismiss')}>
          <X size={18} color="#5C4E40" />
        </PressScale>
      ) : null}
    </View>
  );
}
