import { View } from 'react-native';
import { ChevronRight, MapPin } from 'lucide-react-native';
import { useTranslation } from 'react-i18next';
import { PressScale } from '@/ui/motion/press-scale';
import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { Button } from '@/ui/primitives/button';
import { haptics } from '@/ui/motion/haptics';
import type { Client } from '@/domain/models/client';
import { useClientStatusMap } from '@/state/queries/clients';
import { clientStatusColor } from '@/lib/client-status-color';
import { animalsTotal } from '@/lib/animals-total';
import { useAllSettings } from '@/state/queries/settings';
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
  const status = statusMap?.get(client.id) ?? 'default';
  const colors = clientStatusColor(status, settings as Record<string, string | null>);
  const total = animalsTotal(client.animalCounts);

  return (
    <PressScale
      onPress={() => {
        void haptics.selection();
        onPress();
      }}
    >
      <Surface
        variant="muted"
        className="flex-row items-center rounded-2xl px-4 py-3 gap-3"
      >
        {colors.bgHex ? (
          <View style={{ width: 4, height: 48, borderRadius: 2, backgroundColor: colors.bgHex }} />
        ) : (
          <View className={cn('w-1 h-12 rounded-full', colors.bgClass)} />
        )}
        <View className="flex-1">
          <Text className="font-semibold">{client.displayName}</Text>
          {client.addressCity ? (
            <View className="flex-row items-center gap-1 mt-0.5">
              <MapPin size={12} color="#5C4E40" />
              <Text variant="muted" className="text-sm">{client.addressCity}</Text>
            </View>
          ) : null}
        </View>
        {total > 0 ? (
          <Surface variant="muted" className="rounded-full px-2 py-0.5">
            <Text variant="muted" className="text-xs">{total}</Text>
          </Surface>
        ) : null}
        <Button
          variant={client.isWaiting ? 'primary' : 'secondary'}
          size="sm"
          onPress={onToggleWaiting}
          hapticOnPress={false}
        >
          {client.isWaiting ? t('clients.unmark_waiting') : t('clients.mark_waiting')}
        </Button>
        <ChevronRight size={18} color="#5C4E40" />
      </Surface>
    </PressScale>
  );
}
