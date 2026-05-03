import { View } from 'react-native';
import { Search, X } from 'lucide-react-native';
import { PressScale } from '@/ui/motion/press-scale';
import { Input } from '@/ui/primitives/input';

interface Props {
  value: string;
  onChange: (v: string) => void;
  placeholder?: string;
}

export function SearchBar({ value, onChange, placeholder }: Props) {
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
      />
      {value.length > 0 ? (
        <PressScale onPress={() => onChange('')}>
          <X size={18} color="#5C4E40" />
        </PressScale>
      ) : null}
    </View>
  );
}
