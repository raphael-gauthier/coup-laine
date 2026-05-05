import { useMemo } from 'react';
import { View, Linking, Platform } from 'react-native';
import { useRouter } from 'expo-router';
import { useTranslation } from 'react-i18next';
import { format, parseISO } from 'date-fns';
import { fr } from 'date-fns/locale';
import { X, ChevronRight, Compass, Route as RouteIcon, Phone, MessageSquare } from 'lucide-react-native';
import Animated, { FadeInDown, FadeOutDown } from 'react-native-reanimated';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { Button } from '@/ui/primitives/button';
import { PressScale } from '@/ui/motion/press-scale';
import { clientStatusColor } from '@/lib/client-status-color';
import { haversineDistanceKm } from '@/lib/haversine-distance';
import { normalizePhone } from '@/lib/phone-normalizer';
import { pluralizeFr } from '@/lib/text-pluralization';
import { useClientStatusMap } from '@/state/queries/clients';
import { useAllSettings, useBaseAddress } from '@/state/queries/settings';
import { useClientKpis } from '@/state/queries/kpis';
import { useSpecies, useAnimalCategories } from '@/state/queries/species';
import { useProximityStore } from '@/state/stores/proximity-store';
import type { Client } from '@/domain/models/client';
import { cn } from '@/lib/cn';

interface Props {
  client: Client & { latitude: number; longitude: number };
  onClose: () => void;
}

export function ClientPinPopup({ client, onClose }: Props) {
  const { t } = useTranslation();
  const router = useRouter();
  const { data: statusMap } = useClientStatusMap();
  const { data: settings } = useAllSettings();
  const { data: base } = useBaseAddress();
  const { data: kpis } = useClientKpis(client.id);
  const { data: speciesList = [] } = useSpecies();
  const { data: categories = [] } = useAnimalCategories();
  const setPivotId = useProximityStore((s) => s.setPivotId);

  const status = statusMap?.get(client.id) ?? 'default';
  const colors = clientStatusColor(status, settings as Record<string, string | null>);

  const distanceKm = base
    ? Math.round(haversineDistanceKm({ lat: base.lat, lon: base.lon }, { lat: client.latitude, lon: client.longitude }))
    : 0;

  const addressLine = [
    [client.addressPostcode, client.addressCity].filter(Boolean).join(' '),
    distanceKm > 0 ? `${distanceKm} km` : null,
  ]
    .filter(Boolean)
    .join(' · ');

  const animalsText = useMemo(() => {
    const speciesById = new Map(speciesList.map((s) => [s.id, s]));
    const categoriesById = new Map(categories.map((c) => [c.id, c]));
    const totalsBySpecies = new Map<string, number>();
    for (const ac of client.animalCounts) {
      if (ac.count <= 0) continue;
      const cat = categoriesById.get(ac.categoryId);
      if (!cat) continue;
      const sp = speciesById.get(cat.speciesId);
      if (!sp) continue;
      totalsBySpecies.set(sp.label, (totalsBySpecies.get(sp.label) ?? 0) + ac.count);
    }
    return Array.from(totalsBySpecies.entries())
      .map(([name, total]) => `${total} ${pluralizeFr(name, total)}`)
      .join(', ');
  }, [client.animalCounts, speciesList, categories]);

  const lastInterventionLine = kpis?.lastInterventionDate
    ? t('map.pin_popup_last_intervention', {
        date: format(parseISO(kpis.lastInterventionDate), 'd MMM yyyy', { locale: fr }),
      })
    : t('map.pin_popup_last_intervention', { date: t('map.pin_popup_last_intervention_never') });

  const principalPhone = client.phones[0] ?? null;
  const principalPhoneTel = principalPhone ? normalizePhone(principalPhone) : null;

  const callPhone = () => {
    if (!principalPhoneTel) return;
    void Linking.openURL(`tel:${principalPhoneTel}`);
  };

  const sendSms = () => {
    if (!principalPhoneTel) return;
    void Linking.openURL(`sms:${principalPhoneTel}`);
  };

  const openItinerary = () => {
    const { latitude: lat, longitude: lon } = client;
    const label = encodeURIComponent(client.displayName);
    const url =
      Platform.OS === 'ios'
        ? `maps://?daddr=${lat},${lon}&q=${label}`
        : `geo:${lat},${lon}?q=${lat},${lon}(${label})`;
    void Linking.openURL(url);
  };

  const openPlan = () => {
    setPivotId(client.id);
    onClose();
    router.push('/(tabs)/proximity');
  };

  const openDetail = () => {
    onClose();
    router.push(`/(tabs)/clients/${client.id}`);
  };

  return (
    <Animated.View
      entering={FadeInDown.duration(250)}
      exiting={FadeOutDown.duration(200)}
      style={{ position: 'absolute', bottom: 0, left: 0, right: 0 }}
    >
      <Surface className="rounded-t-3xl px-4 pt-4 pb-8">
        {/* Close button (top-right, outside the tappable card area) */}
        <View className="absolute right-3 top-3 z-10">
          <PressScale
            onPress={onClose}
            className="p-1"
            accessibilityLabel={t('common.close')}
          >
            <View className="w-11 h-11 items-center justify-center">
              <X size={22} color="#5C4E40" />
            </View>
          </PressScale>
        </View>

        {/* Tappable card body — opens client detail */}
        <PressScale onPress={openDetail} accessibilityLabel={client.displayName}>
          {/* Title row: name + status badge + chevron */}
          <View className="flex-row items-center gap-2 pr-8">
            <Text className="flex-1 text-xl font-bold" numberOfLines={1}>
              {client.displayName}
            </Text>
            {colors.bgHex ? (
              <View
                style={{
                  paddingHorizontal: 10,
                  paddingVertical: 3,
                  borderRadius: 12,
                  backgroundColor: colors.bgHex,
                }}
              >
                <Text className="text-xs font-semibold" style={{ color: '#FFFFFF' }}>
                  {t(`map.status_${status}`)}
                </Text>
              </View>
            ) : (
              <View className={cn('px-2.5 py-1 rounded-full', colors.bgClass)}>
                <Text className={cn('text-xs font-semibold', colors.textClass)}>
                  {t(`map.status_${status}`)}
                </Text>
              </View>
            )}
            <ChevronRight size={18} color="#5C4E40" />
          </View>

          {/* Address + distance */}
          {addressLine ? (
            <Text variant="muted" className="text-sm mt-1" numberOfLines={1}>
              {addressLine}
            </Text>
          ) : null}

          {/* Animal counts (aggregated by species) */}
          {animalsText ? (
            <Text className="text-sm mt-1" numberOfLines={1}>
              {animalsText}
            </Text>
          ) : null}

          {/* Last intervention */}
          <Text variant="muted" className="text-sm mt-1" numberOfLines={1}>
            {lastInterventionLine}
          </Text>
        </PressScale>

        {/* Action buttons — row 1: Itinéraire + Planifier */}
        <View className="flex-row gap-2 mt-4">
          <Button
            className="flex-1"
            variant="secondary"
            onPress={openItinerary}
            accessibilityLabel={t('map.pin_popup_itinerary')}
          >
            <Compass size={16} color="#5C4E40" />
            <Text className="font-semibold">{t('map.pin_popup_itinerary')}</Text>
          </Button>
          <Button
            className="flex-1"
            variant="secondary"
            onPress={openPlan}
            accessibilityLabel={t('map.pin_popup_plan')}
          >
            <RouteIcon size={16} color="#5C4E40" />
            <Text className="font-semibold">{t('map.pin_popup_plan')}</Text>
          </Button>
        </View>

        {/* Action buttons — row 2: Appeler + SMS */}
        <View className="flex-row gap-2 mt-2">
          <Button
            className="flex-1"
            variant="secondary"
            onPress={callPhone}
            disabled={!principalPhoneTel}
            accessibilityLabel={t('map.pin_popup_call')}
          >
            <Phone size={16} color="#5C4E40" />
            <Text className="font-semibold">{t('map.pin_popup_call')}</Text>
          </Button>
          <Button
            className="flex-1"
            variant="secondary"
            onPress={sendSms}
            disabled={!principalPhoneTel}
            accessibilityLabel={t('map.pin_popup_sms')}
          >
            <MessageSquare size={16} color="#5C4E40" />
            <Text className="font-semibold">{t('map.pin_popup_sms')}</Text>
          </Button>
        </View>
      </Surface>
    </Animated.View>
  );
}
