import { View } from 'react-native';
import { useTranslation } from 'react-i18next';
import { useClientStatusMap } from '@/state/queries/clients';
import { clientStatusColor } from '@/lib/client-status-color';
import { useAllSettings } from '@/state/queries/settings';
import { Text } from '@/ui/primitives/text';
import { cn } from '@/lib/cn';

interface Props {
  clientId: string;
}

export function ClientStatusBadge({ clientId }: Props) {
  const { t } = useTranslation();
  const { data: statusMap } = useClientStatusMap();
  const { data: settings } = useAllSettings();
  const status = statusMap?.get(clientId) ?? 'default';
  const colors = clientStatusColor(status, settings as Record<string, string | null>);

  if (colors.bgHex) {
    return (
      <View
        style={{
          paddingHorizontal: 12,
          paddingVertical: 4,
          borderRadius: 16,
          alignSelf: 'flex-start',
          backgroundColor: colors.bgHex,
        }}
      >
        <Text className="text-sm font-semibold" style={{ color: '#FFFFFF' }}>
          {t(`clients.filter_status_${status === 'noAnimals' ? 'no_animals' : status}`)}
        </Text>
      </View>
    );
  }

  return (
    <View className={cn('self-start px-3 py-1 rounded-full', colors.bgClass)}>
      <Text className={cn('text-sm font-semibold', colors.textClass)}>
        {t(`clients.filter_status_${status === 'noAnimals' ? 'no_animals' : status}`)}
      </Text>
    </View>
  );
}
