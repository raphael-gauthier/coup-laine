import { View, Modal, TouchableOpacity } from 'react-native';
import { ThemedSwitch } from '@/ui/primitives/themed-switch';
import { Layers, X } from 'lucide-react-native';
import { useState } from 'react';
import { useTranslation } from 'react-i18next';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { PressScale } from '@/ui/motion/press-scale';
import { useMapLayersStore } from '@/state/ui/map-layers-store';

export function MapLayerDialog() {
  const { t } = useTranslation();
  const [visible, setVisible] = useState(false);
  const { showClientPins, showBasePin, showProximityCircle, setLayer } = useMapLayersStore();

  return (
    <>
      <PressScale
        onPress={() => setVisible(true)}
        style={{ position: 'absolute', top: 12, right: 12 }}
      >
        <Surface
          className="rounded-full p-3"
          style={{ shadowColor: '#000', shadowOpacity: 0.15, shadowRadius: 4, shadowOffset: { width: 0, height: 2 }, elevation: 4 }}
        >
          <Layers size={20} color="#5C4E40" />
        </Surface>
      </PressScale>

      <Modal visible={visible} animationType="fade" transparent presentationStyle="overFullScreen">
        <TouchableOpacity
          style={{ flex: 1, backgroundColor: 'rgba(0,0,0,0.4)' }}
          onPress={() => setVisible(false)}
          activeOpacity={1}
        />
        <View style={{ position: 'absolute', top: 60, right: 12, width: 240 }}>
          <Surface
            className="rounded-2xl px-4 py-3"
            style={{ shadowColor: '#000', shadowOpacity: 0.2, shadowRadius: 8, elevation: 8 }}
          >
            <View className="flex-row items-center justify-between mb-3">
              <Text className="font-semibold">{t('map.layers_title')}</Text>
              <PressScale onPress={() => setVisible(false)}>
                <X size={18} color="#5C4E40" />
              </PressScale>
            </View>

            {[
              { key: 'showClientPins' as const,      label: t('map.layer_clients'), value: showClientPins },
              { key: 'showBasePin' as const,          label: t('map.layer_base'),    value: showBasePin },
              { key: 'showProximityCircle' as const,  label: t('map.layer_proximity'), value: showProximityCircle },
            ].map(({ key, label, value }) => (
              <View key={key} className="flex-row items-center justify-between py-2">
                <Text className="text-sm">{label}</Text>
                <ThemedSwitch
                  value={value}
                  onValueChange={(v) => setLayer(key, v)}
                />
              </View>
            ))}
          </Surface>
        </View>
      </Modal>
    </>
  );
}
