import { Linking, Platform, Pressable, View } from 'react-native';
import { useTranslation } from 'react-i18next';
import { MapPin, MessageSquare, Navigation, Phone } from 'lucide-react-native';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { PressScale } from '@/ui/motion/press-scale';
import { haptics } from '@/ui/motion/haptics';
import { formatPhone } from '@/lib/phone-formatter';
import { normalizePhone } from '@/lib/phone-normalizer';
import { useMutedForegroundColor, usePrimaryColor } from '@/ui/theme/colors';
import type { Client } from '@/domain/models/client';

interface Props {
  client: Client;
}

function buildItineraryUrl(client: Client): string | null {
  const hasCoords = client.latitude != null && client.longitude != null;
  const query = hasCoords
    ? `${client.latitude},${client.longitude}`
    : client.addressLabel
      ? encodeURIComponent(client.addressLabel)
      : null;
  if (!query) return null;
  return Platform.select({
    ios: `maps://?daddr=${query}`,
    android: `geo:0,0?q=${query}`,
    default: `https://www.google.com/maps/dir/?api=1&destination=${query}`,
  }) ?? null;
}

export function ClientContactCard({ client }: Props) {
  const { t } = useTranslation();
  const mutedFg = useMutedForegroundColor();
  const primary = usePrimaryColor();
  const itineraryUrl = buildItineraryUrl(client);
  const hasAddress = !!client.addressLabel;
  const hasPhones = client.phones.length > 0;

  if (!hasAddress && !hasPhones) return null;

  const onItinerary = () => {
    if (!itineraryUrl) return;
    void haptics.selection();
    void Linking.openURL(itineraryUrl);
  };

  return (
    <Surface variant="muted" className="rounded-2xl px-4 py-3 gap-3">
      {hasAddress ? (
        <View className="flex-row items-center gap-3">
          <MapPin size={18} color={mutedFg} />
          <View className="flex-1">
            <Text>{client.addressLabel}</Text>
          </View>
          {itineraryUrl ? (
            <PressScale
              onPress={onItinerary}
              accessibilityLabel={t('clients.itinerary_cta')}
              className="flex-row items-center gap-1 px-3 py-1.5 rounded-full bg-background dark:bg-background-dark"
            >
              <Navigation size={14} color={primary} />
              <Text variant="primary" className="text-sm font-medium">
                {t('clients.itinerary_cta')}
              </Text>
            </PressScale>
          ) : null}
        </View>
      ) : null}

      {hasAddress && hasPhones ? (
        <View className="h-px bg-foreground/10 dark:bg-foreground-dark/10" />
      ) : null}

      {hasPhones ? (
        <View className="gap-1">
          {client.phones.map((p, i) => {
            const tel = normalizePhone(p);
            return (
              <View key={i} className="flex-row items-center justify-between py-0.5">
                <Text>{formatPhone(p)}</Text>
                <View className="flex-row gap-1">
                  <Pressable
                    onPress={() => tel && void Linking.openURL(`tel:${tel}`)}
                    accessibilityLabel={t('clients.call_phone')}
                    className="p-2"
                  >
                    <Phone size={18} color={mutedFg} />
                  </Pressable>
                  <Pressable
                    onPress={() => tel && void Linking.openURL(`sms:${tel}`)}
                    accessibilityLabel={t('clients.send_sms')}
                    className="p-2"
                  >
                    <MessageSquare size={18} color={mutedFg} />
                  </Pressable>
                </View>
              </View>
            );
          })}
        </View>
      ) : null}
    </Surface>
  );
}
