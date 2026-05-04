import { useState } from 'react';
import { ScrollView, View } from 'react-native';
import { useTranslation } from 'react-i18next';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { PressScale } from '@/ui/motion/press-scale';
import { ScreenHeader } from '@/ui/components/screen-header';
import { ColorPickerSheet } from '@/ui/components/color-picker-sheet';
import { errorToast } from '@/ui/components/error-toast';
import { useAllSettings, useSetSetting, type SettingKey } from '@/state/queries/settings';
import { clientStatusColor } from '@/lib/client-status-color';
import { useResolvedColorScheme } from '@/ui/theme/theme-provider';
import type { ClientStatus } from '@/domain/use-cases/client-status';
import { haptics } from '@/ui/motion/haptics';

// Theme hex fallbacks per scheme
const THEME_HEX: Record<ClientStatus, { light: string; dark: string }> = {
  default:    { light: 'transparent', dark: 'transparent' },
  waiting:    { light: '#C88226', dark: '#DC9E4E' },
  scheduled:  { light: '#A1602F', dark: '#C68A58' },
  done:       { light: '#5C7548', dark: '#98B282' },
  noAnimals:  { light: '#EAE0D3', dark: '#302820' },
  banned:     { light: '#B23832', dark: '#DC605A' },
};

const STATUS_ROWS: { status: ClientStatus; labelKey: string }[] = [
  { status: 'default',   labelKey: 'settings.marker_colors.status_default' },
  { status: 'waiting',   labelKey: 'settings.marker_colors.status_waiting' },
  { status: 'scheduled', labelKey: 'settings.marker_colors.status_scheduled' },
  { status: 'done',      labelKey: 'settings.marker_colors.status_done' },
  { status: 'noAnimals', labelKey: 'settings.marker_colors.status_no_animals' },
  { status: 'banned',    labelKey: 'settings.marker_colors.status_banned' },
];

export default function MarkerColorsScreen() {
  const { t } = useTranslation();
  const { data: settings } = useAllSettings();
  const setSettingMutation = useSetSetting();
  const scheme = useResolvedColorScheme();

  const [pickingStatus, setPickingStatus] = useState<ClientStatus | null>(null);

  const getHex = (status: ClientStatus): string | null => {
    const tokens = clientStatusColor(status);
    const key = tokens.settingsKey as SettingKey;
    return settings?.[key] ?? null;
  };

  const getFallbackHex = (status: ClientStatus): string => {
    return THEME_HEX[status][scheme];
  };

  const onSelect = (status: ClientStatus, hex: string | null) => {
    const tokens = clientStatusColor(status);
    const key = tokens.settingsKey as SettingKey;
    setSettingMutation.mutate(
      { key, value: hex },
      {
        onSuccess: () => { void haptics.success(); },
        onError: (err) => {
          errorToast(t('settings.marker_colors.save_failed'), err instanceof Error ? err.message : undefined);
        },
      }
    );
  };

  return (
    <Surface className="flex-1">
      <ScreenHeader title={t('settings.marker_colors.screen_title')} />
      <ScrollView contentContainerStyle={{ paddingHorizontal: 16, paddingTop: 8, paddingBottom: 160, gap: 8 }}>
        {STATUS_ROWS.map(({ status, labelKey }) => {
          const currentHex = getHex(status);
          const fallbackHex = getFallbackHex(status);
          const displayHex = currentHex ?? fallbackHex;

          return (
            <PressScale
              key={status}
              onPress={() => {
                void haptics.selection();
                setPickingStatus(status);
              }}
            >
              <Surface
                variant="muted"
                className="flex-row items-center rounded-2xl px-4 py-3 gap-3"
              >
                <View
                  style={{
                    width: 24,
                    height: 24,
                    borderRadius: 12,
                    backgroundColor: displayHex === 'transparent' ? undefined : displayHex,
                    borderWidth: 2,
                    borderColor: '#DCD0C0',
                  }}
                />
                <View className="flex-1">
                  <Text className="font-medium">{t(labelKey)}</Text>
                  {currentHex ? (
                    <Text variant="muted" className="text-xs">{currentHex}</Text>
                  ) : (
                    <Text variant="muted" className="text-xs">{t('settings.marker_colors.using_theme')}</Text>
                  )}
                </View>
              </Surface>
            </PressScale>
          );
        })}
      </ScrollView>

      {pickingStatus ? (
        <ColorPickerSheet
          visible
          currentHex={getHex(pickingStatus)}
          defaultHex={getFallbackHex(pickingStatus)}
          onSelect={(hex) => onSelect(pickingStatus, hex)}
          onClose={() => setPickingStatus(null)}
        />
      ) : null}
    </Surface>
  );
}
