import { useEffect, useRef, useState } from 'react';
import { View, ActivityIndicator } from 'react-native';
import { searchAddresses, type BanResult } from '@/infra/services/ban-geocoding';
import { Input } from '@/ui/primitives/input';
import { Text } from '@/ui/primitives/text';
import { Surface } from '@/ui/primitives/surface';
import { PressScale } from '@/ui/motion/press-scale';
import { haptics } from '@/ui/motion/haptics';

interface Props {
  initialValue?: string;
  placeholder?: string;
  onSelect: (result: BanResult) => void;
}

export function AddressAutocompleteInput({ initialValue = '', placeholder, onSelect }: Props) {
  const [query, setQuery] = useState(initialValue);
  const [results, setResults] = useState<BanResult[]>([]);
  const [loading, setLoading] = useState(false);
  const debounceRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const abortRef = useRef<AbortController | null>(null);

  useEffect(() => {
    if (debounceRef.current) clearTimeout(debounceRef.current);

    if (query.trim().length < 3) {
      setResults([]);
      setLoading(false);
      return;
    }

    setLoading(true);
    debounceRef.current = setTimeout(() => {
      abortRef.current?.abort();
      const controller = new AbortController();
      abortRef.current = controller;
      void searchAddresses(query, { signal: controller.signal })
        .then((r) => setResults(r))
        .finally(() => setLoading(false));
    }, 300);

    return () => {
      if (debounceRef.current) clearTimeout(debounceRef.current);
    };
  }, [query]);

  const handleSelect = (r: BanResult) => {
    void haptics.selection();
    setQuery(r.label);
    setResults([]);
    onSelect(r);
  };

  return (
    <View className="gap-2">
      <Input
        value={query}
        onChangeText={setQuery}
        placeholder={placeholder}
        autoCapitalize="none"
        autoCorrect={false}
      />
      {loading && (
        <View className="flex-row items-center gap-2 px-2">
          <ActivityIndicator size="small" />
          <Text variant="muted" className="text-sm">Recherche…</Text>
        </View>
      )}
      {results.length > 0 && (
        <Surface className="rounded-2xl border border-border dark:border-border-dark overflow-hidden">
          {results.map((item, index) => (
            <PressScale
              key={`${item.label}-${index}`}
              onPress={() => handleSelect(item)}
              className={index === 0 ? '' : 'border-t border-border dark:border-border-dark'}
            >
              <View className="px-4 py-3">
                <Text>{item.label}</Text>
              </View>
            </PressScale>
          ))}
        </Surface>
      )}
    </View>
  );
}
