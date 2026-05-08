import { View } from 'react-native';
import { ChevronRight, Hourglass, MapPin, TriangleAlert } from 'lucide-react-native';
import { useTranslation } from 'react-i18next';
import { PressScale } from '@/ui/motion/press-scale';
import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { haptics } from '@/ui/motion/haptics';
import type { Client } from '@/domain/models/client';
import { useDisplayedStatusMap } from '@/state/queries/clients';
import { useSpecies, useAnimalCategories } from '@/state/queries/species';
import { useResolvedColorScheme } from '@/ui/theme/theme-provider';
import { formatAnimalCountsBySpecies } from '@/lib/animal-counts-summary';

interface Props {
  client: Client;
  onPress: () => void;
  onToggleWaiting: () => void;
  distanceKm?: number;
}

export function ClientCard({ client, onPress, onToggleWaiting, distanceKm }: Props) {
  const { t } = useTranslation();
  const { data: statusMap } = useDisplayedStatusMap();
  const scheme = useResolvedColorScheme();
  const { data: species = [] } = useSpecies();
  const { data: categories = [] } = useAnimalCategories();
  const status = statusMap?.get(client.id);
  const hex = status ? (scheme === 'dark' ? status.colorDark : status.colorLight) : '#94A3B8';
  const animalsText = formatAnimalCountsBySpecies(client.animalCounts, species, categories);
  const addressLine = [client.addressPostcode, client.addressCity].filter(Boolean).join(' ');

  return (
    <PressScale
      onPress={() => {
        void haptics.selection();
        onPress();
      }}
      accessibilityLabel={client.displayName}
    >
      <Surface
        variant="muted"
        className="flex-row items-center rounded-2xl px-4 py-3 gap-3"
      >
        <View style={{ width: 4, height: 56, borderRadius: 2, backgroundColor: hex }} />
        <View className="flex-1">
          <Text className="font-semibold" numberOfLines={1}>{client.displayName}</Text>
          {addressLine ? (
            <View className="flex-row items-center gap-1 mt-0.5">
              <MapPin size={12} color="#5C4E40" />
              <Text variant="muted" className="text-sm flex-1" numberOfLines={1}>{addressLine}</Text>
            </View>
          ) : null}
          {animalsText ? (
            <Text className="text-sm mt-0.5" numberOfLines={1}>{animalsText}</Text>
          ) : null}
        </View>
        <PressScale
          onPress={() => {
            void haptics.selection();
            onToggleWaiting();
          }}
          accessibilityLabel={client.isWaiting ? t('clients.unmark_waiting') : t('clients.mark_waiting')}
          accessibilityRole="switch"
          accessibilityState={{ checked: client.isWaiting }}
          className="p-2"
        >
          <Hourglass
            size={20}
            color={client.isWaiting ? '#A1602F' : '#5C4E40'}
            fill={client.isWaiting ? '#A1602F' : 'transparent'}
          />
        </PressScale>
        {client.needsDistanceRecompute ? (
          <Surface
            variant="danger"
            className="flex-row items-center gap-1 rounded-full px-2 py-1"
            accessibilityLabel={t('recompute.card_badge')}
          >
            <TriangleAlert size={12} color="#FFFFFF" />
          </Surface>
        ) : distanceKm != null ? (
          <Text variant="muted" className="font-mono text-sm">
            {distanceKm.toFixed(1)} km
          </Text>
        ) : (
          <ChevronRight size={18} color="#5C4E40" />
        )}
      </Surface>
    </PressScale>
  );
}
