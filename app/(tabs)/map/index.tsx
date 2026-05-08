import { useRef, useMemo, useState } from 'react';
import { View, ActivityIndicator } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useTranslation } from 'react-i18next';
import { MapPinOff } from 'lucide-react-native';

import { Surface } from '@/ui/primitives/surface';
import { Map, type MapHandle } from '@/ui/components/map';
import { ClientPin } from '@/ui/components/client-pin';
import { BasePin } from '@/ui/components/base-pin';
import { ClientPinPopup } from '@/ui/components/client-pin-popup';
import { MapStatusChips } from '@/ui/components/map-status-chips';
import { MapSearchOverlay } from '@/ui/components/map-search-overlay';
import { MapLayerDialog } from '@/ui/components/map-layer-dialog';
import { EmptyState } from '@/ui/components/empty-state';
import { ErrorState } from '@/ui/components/error-state';
import { useClients, useDisplayedStatusMap } from '@/state/queries/clients';
import { useBaseAddress } from '@/state/queries/settings';
import { useMapFiltersStore } from '@/state/ui/map-filters-store';
import { useMapLayersStore } from '@/state/ui/map-layers-store';
import { useMutedForegroundColor } from '@/ui/theme/colors';
import type { Client } from '@/domain/models/client';

type GeoClient = Client & { latitude: number; longitude: number };

export default function MapScreen() {
  const { t } = useTranslation();
  const insets = useSafeAreaInsets();
  const mapRef = useRef<MapHandle>(null);
  const { data: clients = [], isError, isLoading, refetch } = useClients('all');
  const { data: base } = useBaseAddress();
  const { data: displayedMap } = useDisplayedStatusMap();
  const { activeFilter } = useMapFiltersStore();
  const { showClientPins, showBasePin } = useMapLayersStore();
  const mutedFg = useMutedForegroundColor();

  const [selectedClient, setSelectedClient] = useState<GeoClient | null>(null);

  const geocoded = useMemo(
    () => clients.filter((c) => c.latitude != null && c.longitude != null) as GeoClient[],
    [clients]
  );

  const visibleClients = useMemo(() => {
    if (activeFilter === null) return geocoded;
    return geocoded.filter((c) => {
      const displayed = displayedMap?.get(c.id);
      return displayed?.id === activeFilter;
    });
  }, [geocoded, activeFilter, displayedMap]);

  const initialCenter = base ? { lat: base.lat, lon: base.lon } : undefined;

  if (isError) return <ErrorState onRetry={() => refetch()} />;

  if (isLoading && clients.length === 0) {
    return (
      <Surface className="flex-1" style={{ paddingTop: insets.top }}>
        <View className="flex-1 items-center justify-center">
          <ActivityIndicator />
        </View>
      </Surface>
    );
  }

  if (clients.length === 0) {
    return (
      <Surface className="flex-1" style={{ paddingTop: insets.top }}>
        <EmptyState
          icon={<MapPinOff size={48} color={mutedFg} />}
          title={t('map.empty_title')}
          message={t('map.empty_message')}
        />
      </Surface>
    );
  }

  return (
    <Surface className="flex-1">
      {/* Safe-area top spacer */}
      <View style={{ height: insets.top }} />

      {/* Status chips row */}
      <MapStatusChips />

      {/* Map fills rest */}
      <View className="flex-1">
        <Map ref={mapRef} initialCenter={initialCenter} initialZoom={10}>
          {showBasePin && base ? (
            <BasePin lat={base.lat} lon={base.lon} />
          ) : null}
          {showClientPins
            ? visibleClients.map((client) => (
                <ClientPin
                  key={client.id}
                  client={client}
                  onPress={() => setSelectedClient(client)}
                />
              ))
            : null}
        </Map>

        {/* Floating controls */}
        <MapSearchOverlay
          clients={clients}
          onFlyTo={(lon, lat) => mapRef.current?.flyTo(lon, lat, 14)}
        />
        <MapLayerDialog />

        {/* Popup */}
        {selectedClient ? (
          <ClientPinPopup
            client={selectedClient}
            onClose={() => setSelectedClient(null)}
          />
        ) : null}
      </View>
    </Surface>
  );
}
