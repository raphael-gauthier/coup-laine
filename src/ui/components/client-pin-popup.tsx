import { View, Linking } from 'react-native';
import { useRouter } from 'expo-router';
import { useTranslation } from 'react-i18next';
import { X, MapPin, Navigation } from 'lucide-react-native';
import Animated, { FadeInDown, FadeOutDown } from 'react-native-reanimated';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { Button } from '@/ui/primitives/button';
import { PressScale } from '@/ui/motion/press-scale';
import { clientStatusColor } from '@/lib/client-status-color';
import { animalsTotal } from '@/lib/animals-total';
import { useClientStatusMap } from '@/state/queries/clients';
import { useAllSettings } from '@/state/queries/settings';
import type { Client } from '@/domain/models/client';
import { cn } from '@/lib/cn';

// Simple species emoji mapping
const SPECIES_EMOJI: Record<string, string> = {
  sheep: '🐑',
  goat: '🐐',
  cattle: '🐄',
  poultry: '🐔',
};

interface Props {
  client: Client & { latitude: number; longitude: number };
  onClose: () => void;
}

export function ClientPinPopup({ client, onClose }: Props) {
  const { t } = useTranslation();
  const router = useRouter();
  const { data: statusMap } = useClientStatusMap();
  const { data: settings } = useAllSettings();
  const status = statusMap?.get(client.id) ?? 'default';
  const colors = clientStatusColor(status, settings as Record<string, string | null>);
  const total = animalsTotal(client.animalCounts);

  const openMaps = () => {
    const url = `https://www.google.com/maps/dir/?api=1&destination=${client.latitude},${client.longitude}`;
    void Linking.openURL(url);
  };

  return (
    <Animated.View
      entering={FadeInDown.duration(250)}
      exiting={FadeOutDown.duration(200)}
      style={{ position: 'absolute', bottom: 0, left: 0, right: 0 }}
    >
      <Surface className="rounded-t-3xl px-4 pt-4 pb-8">
        {/* Close button */}
        <View className="flex-row items-start justify-between mb-3">
          <View className="flex-1">
            <Text className="text-xl font-bold">{client.displayName}</Text>
            {client.addressCity ? (
              <View className="flex-row items-center gap-1 mt-0.5">
                <MapPin size={13} color="#5C4E40" />
                <Text variant="muted" className="text-sm">{client.addressCity}</Text>
              </View>
            ) : null}
          </View>
          <PressScale onPress={onClose}>
            <X size={22} color="#5C4E40" />
          </PressScale>
        </View>

        {/* Animal counts */}
        {client.animalCounts.length > 0 ? (
          <View className="flex-row flex-wrap gap-2 mb-3">
            {client.animalCounts.map((ac, i) => (
              <Surface key={i} variant="muted" className="flex-row items-center gap-1 rounded-full px-2 py-0.5">
                <Text className="text-xs">{total > 0 ? '🐑' : ''}</Text>
                <Text variant="muted" className="text-xs">{ac.count}</Text>
              </Surface>
            ))}
          </View>
        ) : null}

        {/* Status badge */}
        <View className="mb-3">
          {colors.bgHex ? (
            <View
              style={{ paddingHorizontal: 10, paddingVertical: 3, borderRadius: 12, alignSelf: 'flex-start', backgroundColor: colors.bgHex }}
            >
              <Text className="text-xs font-semibold" style={{ color: '#FFFFFF' }}>
                {t(`map.status_${status}`)}
              </Text>
            </View>
          ) : (
            <View className={cn('self-start px-2.5 py-1 rounded-full', colors.bgClass)}>
              <Text className={cn('text-xs font-semibold', colors.textClass)}>
                {t(`map.status_${status}`)}
              </Text>
            </View>
          )}
        </View>

        {/* Action buttons */}
        <View className="flex-row gap-2">
          <Button
            className="flex-1"
            variant="primary"
            onPress={() => {
              onClose();
              router.push(`/(tabs)/clients/${client.id}`);
            }}
          >
            {t('map.view_client')}
          </Button>
          <Button
            className="flex-1"
            variant="secondary"
            onPress={openMaps}
          >
            <Navigation size={16} color="#5C4E40" />
            <Text className="font-semibold">{t('map.start_trip')}</Text>
          </Button>
        </View>
      </Surface>
    </Animated.View>
  );
}
