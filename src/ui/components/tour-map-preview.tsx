import { useMemo, useState } from 'react';
import { View, Pressable, StyleSheet } from 'react-native';
import { Maximize2 } from 'lucide-react-native';
import { useTranslation } from 'react-i18next';

import { Map } from '@/ui/components/map';
import { ClientPin } from '@/ui/components/client-pin';
import { BasePin } from '@/ui/components/base-pin';
import { TourRoutePolyline } from '@/ui/components/tour-route-polyline';
import { TourMapFullscreenModal } from '@/ui/components/tour-map-fullscreen-modal';
import { computeBounds } from '@/ui/components/map-bounds';
import { haptics } from '@/ui/motion/haptics';
import type { Client } from '@/domain/models/client';

export interface PreviewStop {
  id: string;
  client: Client & { latitude: number; longitude: number };
  arrivalTime?: string;
}

interface Props {
  base: { lat: number; lon: number };
  stops: PreviewStop[];
  height?: number;
}

const DEFAULT_HEIGHT = 220;

export function TourMapPreview({ base, stops, height = DEFAULT_HEIGHT }: Props) {
  const { t } = useTranslation();
  const [modalVisible, setModalVisible] = useState(false);

  const routeCoords = useMemo(
    () => [
      { id: 'BASE', lat: base.lat, lon: base.lon },
      ...stops.map((s) => ({
        id: s.client.id,
        lat: s.client.latitude,
        lon: s.client.longitude,
      })),
      { id: 'BASE-end', lat: base.lat, lon: base.lon },
    ],
    [base, stops]
  );

  const bounds = useMemo(
    () =>
      computeBounds([
        { lat: base.lat, lon: base.lon },
        ...stops.map((s) => ({ lat: s.client.latitude, lon: s.client.longitude })),
      ]),
    [base, stops]
  );

  if (!bounds) return null;

  const open = () => {
    void haptics.lightTap();
    setModalVisible(true);
  };

  return (
    <>
      <View style={[styles.container, { height }]}>
        <Map interactive={false} bounds={bounds}>
          <TourRoutePolyline coords={routeCoords} />
          {stops.map((s) => (
            <ClientPin key={s.id} client={s.client} onPress={() => {}} />
          ))}
          <BasePin lat={base.lat} lon={base.lon} />
        </Map>
        <Pressable
          style={StyleSheet.absoluteFill}
          onPress={open}
          accessibilityRole="button"
          accessibilityLabel={t('tours.map.expand_a11y')}
        >
          <View style={styles.expandIcon}>
            <Maximize2 size={16} color="#FFFFFF" />
          </View>
        </Pressable>
      </View>
      <TourMapFullscreenModal
        visible={modalVisible}
        onClose={() => setModalVisible(false)}
        base={base}
        stops={stops}
      />
    </>
  );
}

const styles = StyleSheet.create({
  container: {
    borderRadius: 16,
    overflow: 'hidden',
  },
  expandIcon: {
    position: 'absolute',
    top: 8,
    right: 8,
    width: 32,
    height: 32,
    borderRadius: 8,
    backgroundColor: 'rgba(0, 0, 0, 0.55)',
    alignItems: 'center',
    justifyContent: 'center',
  },
});
