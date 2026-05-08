// src/ui/components/client-status-badge.tsx
import { View } from 'react-native';
import { useDisplayedStatusMap } from '@/state/queries/clients';
import { Text } from '@/ui/primitives/text';
import { useResolvedColorScheme } from '@/ui/theme/theme-provider';

interface Props {
  clientId: string;
}

export function ClientStatusBadge({ clientId }: Props) {
  const { data: map } = useDisplayedStatusMap();
  const scheme = useResolvedColorScheme();
  const status = map?.get(clientId);
  if (!status) return null;
  const hex = scheme === 'dark' ? status.colorDark : status.colorLight;

  return (
    <View
      style={{
        paddingHorizontal: 12, paddingVertical: 4, borderRadius: 16,
        alignSelf: 'flex-start', backgroundColor: hex,
      }}
    >
      <Text className="text-sm font-semibold" style={{ color: '#FFFFFF' }}>
        {status.label}
      </Text>
    </View>
  );
}
