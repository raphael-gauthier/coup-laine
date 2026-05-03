import { useState } from 'react';
import { View, TextInput, FlatList, TouchableOpacity } from 'react-native';
import { Search, X } from 'lucide-react-native';
import Animated, { FadeIn, FadeOut } from 'react-native-reanimated';
import { useTranslation } from 'react-i18next';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { PressScale } from '@/ui/motion/press-scale';
import { matchesQuery } from '@/lib/text-search';
import { useResolvedColorScheme } from '@/ui/theme/theme-provider';
import type { Client } from '@/domain/models/client';

interface Props {
  clients: (Client & { latitude: number | null; longitude: number | null })[];
  onFlyTo: (lon: number, lat: number) => void;
}

const INPUT_COLOR = { light: '#1C1612', dark: '#F0E8DC' };
const INPUT_PLACEHOLDER = { light: '#5C4E40', dark: '#B4A490' };

export function MapSearchOverlay({ clients, onFlyTo }: Props) {
  const { t } = useTranslation();
  const [expanded, setExpanded] = useState(false);
  const [query, setQuery] = useState('');
  const scheme = useResolvedColorScheme();

  const results = query.trim()
    ? clients.filter((c) => matchesQuery(c.displayName, query) && c.latitude != null && c.longitude != null)
    : [];

  const handleSelect = (client: Client & { latitude: number | null; longitude: number | null }) => {
    if (client.latitude != null && client.longitude != null) {
      onFlyTo(client.longitude, client.latitude);
    }
    setExpanded(false);
    setQuery('');
  };

  if (!expanded) {
    return (
      <PressScale
        onPress={() => setExpanded(true)}
        style={{ position: 'absolute', top: 12, left: 12 }}
      >
        <Surface
          className="rounded-full p-3"
          style={{ shadowColor: '#000', shadowOpacity: 0.15, shadowRadius: 4, shadowOffset: { width: 0, height: 2 }, elevation: 4 }}
        >
          <Search size={20} color="#5C4E40" />
        </Surface>
      </PressScale>
    );
  }

  return (
    <Animated.View
      entering={FadeIn.duration(200)}
      exiting={FadeOut.duration(150)}
      style={{ position: 'absolute', top: 8, left: 8, right: 8 }}
    >
      <Surface
        className="rounded-2xl overflow-hidden"
        style={{ shadowColor: '#000', shadowOpacity: 0.15, shadowRadius: 8, shadowOffset: { width: 0, height: 2 }, elevation: 6 }}
      >
        <View className="flex-row items-center px-3 py-2 gap-2">
          <Search size={18} color="#5C4E40" />
          <TextInput
            autoFocus
            value={query}
            onChangeText={setQuery}
            placeholder={t('map.search_placeholder')}
            placeholderTextColor={INPUT_PLACEHOLDER[scheme]}
            style={{ flex: 1, fontSize: 15, color: INPUT_COLOR[scheme] }}
          />
          <TouchableOpacity onPress={() => { setExpanded(false); setQuery(''); }}>
            <X size={18} color="#5C4E40" />
          </TouchableOpacity>
        </View>

        {results.length > 0 ? (
          <FlatList
            data={results.slice(0, 6)}
            keyExtractor={(c) => c.id}
            style={{ maxHeight: 240 }}
            renderItem={({ item }) => (
              <TouchableOpacity
                onPress={() => handleSelect(item)}
                className="px-4 py-3 border-t border-border dark:border-border-dark"
              >
                <Text className="font-medium">{item.displayName}</Text>
                {item.addressCity ? (
                  <Text variant="muted" className="text-xs">{item.addressCity}</Text>
                ) : null}
              </TouchableOpacity>
            )}
          />
        ) : null}
      </Surface>
    </Animated.View>
  );
}
