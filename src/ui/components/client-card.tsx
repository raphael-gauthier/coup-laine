import { View } from 'react-native';
import { ChevronRight, Hourglass, MapPin, TriangleAlert } from 'lucide-react-native';
import { useTranslation } from 'react-i18next';
import { PressScale } from '@/ui/motion/press-scale';
import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { haptics } from '@/ui/motion/haptics';
import type { Client } from '@/domain/models/client';
import { useClientStatusMap } from '@/state/queries/clients';
import { useSpecies, useAnimalCategories } from '@/state/queries/species';
import { useAllSettings } from '@/state/queries/settings';
import { clientStatusColor } from '@/lib/client-status-color';
import { formatAnimalCountsBySpecies } from '@/lib/animal-counts-summary';
import { cn } from '@/lib/cn';

interface Props {
  client: Client;
  onPress: () => void;
  onToggleWaiting: () => void;
}

export function ClientCard({ client, onPress, onToggleWaiting }: Props) {
  const { t } = useTranslation();
  const { data: statusMap } = useClientStatusMap();
  const { data: settings } = useAllSettings();
  const { data: species = [] } = useSpecies();
  const { data: categories = [] } = useAnimalCategories();
  const status = statusMap?.get(client.id) ?? 'default';
  const colors = clientStatusColor(status, settings as Record<string, string | null>);
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
        {colors.bgHex ? (
          <View style={{ width: 4, height: 56, borderRadius: 2, backgroundColor: colors.bgHex }} />
        ) : (
          <View className={cn('w-1 h-14 rounded-full', colors.bgClass)} />
        )}
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
        ) : (
          <ChevronRight size={18} color="#5C4E40" />
        )}
      </Surface>
    </PressScale>
  );
}
