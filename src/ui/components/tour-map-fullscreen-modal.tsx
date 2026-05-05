import { useMemo, useRef, useState } from 'react';
import { Modal, View, Pressable, StyleSheet } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { X, Maximize2, Home } from 'lucide-react-native';
import { useTranslation } from 'react-i18next';

import { Map, type MapHandle } from '@/ui/components/map';
import { ClientPin } from '@/ui/components/client-pin';
import { BasePin } from '@/ui/components/base-pin';
import { TourRoutePolyline } from '@/ui/components/tour-route-polyline';
import { ClientPinPopup } from '@/ui/components/client-pin-popup';
import { computeBounds } from '@/ui/components/map-bounds';
import { haptics } from '@/ui/motion/haptics';
import type { PreviewStop } from '@/ui/components/tour-map-preview';

interface Props {
  visible: boolean;
  onClose: () => void;
  base: { lat: number; lon: number };
  stops: PreviewStop[];
}

export function TourMapFullscreenModal({ visible, onClose, base, stops }: Props) {
  const { t } = useTranslation();
  const mapRef = useRef<MapHandle>(null);
  const lastPinTapAtRef = useRef(0);
  const [selectedStopId, setSelectedStopId] = useState<string | null>(null);

  const selectStop = (id: string) => {
    lastPinTapAtRef.current = Date.now();
    setSelectedStopId(id);
  };

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

  const handleClose = () => {
    void haptics.lightTap();
    setSelectedStopId(null);
    onClose();
  };

  const handleFitBounds = () => {
    void haptics.selection();
    if (bounds) mapRef.current?.fitBounds(bounds);
  };

  const handleRecenterBase = () => {
    void haptics.selection();
    mapRef.current?.flyTo(base.lon, base.lat, 14);
  };

  const selectedStop = selectedStopId ? stops.find((s) => s.id === selectedStopId) : null;

  if (!bounds) return null;

  return (
    <Modal
      visible={visible}
      animationType="fade"
      presentationStyle="fullScreen"
      onRequestClose={handleClose}
      onShow={() => {
        void haptics.lightTap();
      }}
    >
      <View style={styles.root}>
        <Map
          ref={mapRef}
          interactive
          bounds={bounds}
          onPress={() => {
            if (Date.now() - lastPinTapAtRef.current < 200) return;
            setSelectedStopId(null);
          }}
        >
          <TourRoutePolyline coords={routeCoords} />
          {stops.map((s) => (
            <ClientPin
              key={s.id}
              client={s.client}
              onPress={() => selectStop(s.id)}
            />
          ))}
          <BasePin
            lat={base.lat}
            lon={base.lon}
            onPress={() => {
              lastPinTapAtRef.current = Date.now();
              handleFitBounds();
            }}
          />
        </Map>

        <SafeAreaView style={styles.overlay} pointerEvents="box-none" edges={['top', 'right', 'left']}>
          <View style={styles.topRow} pointerEvents="box-none">
            <Pressable
              style={styles.iconButton}
              onPress={handleClose}
              accessibilityRole="button"
              accessibilityLabel={t('tours.map.close_a11y')}
            >
              <X size={20} color="#FFFFFF" />
            </Pressable>
            <View style={styles.actions} pointerEvents="box-none">
              <Pressable
                style={styles.iconButton}
                onPress={handleFitBounds}
                accessibilityRole="button"
                accessibilityLabel={t('tours.map.fit_bounds_a11y')}
              >
                <Maximize2 size={20} color="#FFFFFF" />
              </Pressable>
              <Pressable
                style={styles.iconButton}
                onPress={handleRecenterBase}
                accessibilityRole="button"
                accessibilityLabel={t('tours.map.recenter_base_a11y')}
              >
                <Home size={20} color="#FFFFFF" />
              </Pressable>
            </View>
          </View>
        </SafeAreaView>

        {selectedStop ? (
          <ClientPinPopup
            client={selectedStop.client}
            arrivalTime={selectedStop.arrivalTime}
            onClose={() => setSelectedStopId(null)}
            onNavigate={handleClose}
          />
        ) : null}
      </View>
    </Modal>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1 },
  overlay: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
  },
  topRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    paddingHorizontal: 12,
    paddingTop: 12,
  },
  actions: {
    gap: 8,
  },
  iconButton: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: 'rgba(0, 0, 0, 0.55)',
    alignItems: 'center',
    justifyContent: 'center',
  },
});
