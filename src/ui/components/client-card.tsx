import { View } from 'react-native';
import { ChevronRight, MapPin } from 'lucide-react-native';
import { useTranslation } from 'react-i18next';
import { PressScale } from '@/ui/motion/press-scale';
import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { Button } from '@/ui/primitives/button';
import { haptics } from '@/ui/motion/haptics';
import type { Client } from '@/domain/models/client';
import { computeClientStatus } from '@/domain/use-cases/client-status';
import { clientStatusColor } from '@/lib/client-status-color';
import { cn } from '@/lib/cn';

interface Props {
  client: Client;
  onPress: () => void;
  onToggleWaiting: () => void;
  today?: string;
}

export function ClientCard({ client, onPress, onToggleWaiting, today }: Props) {
  const { t } = useTranslation();
  const status = computeClientStatus({
    isWaiting: client.isWaiting,
    lastShearingDate: client.lastShearingDate,
    today: today ?? new Date().toISOString().slice(0, 10),
  });
  const colors = clientStatusColor(status);

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
        <View className={cn('w-1 h-12 rounded-full', colors.bgClass)} />
        <View className="flex-1">
          <Text className="font-semibold">{client.displayName}</Text>
          {client.addressCity ? (
            <View className="flex-row items-center gap-1 mt-0.5">
              <MapPin size={12} color="#5C4E40" />
              <Text variant="muted" className="text-sm">{client.addressCity}</Text>
            </View>
          ) : null}
        </View>
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
