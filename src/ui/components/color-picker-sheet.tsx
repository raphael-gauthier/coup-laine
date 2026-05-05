import { useState } from 'react';
import { Modal, View, TouchableOpacity } from 'react-native';
import { X } from 'lucide-react-native';
import { useTranslation } from 'react-i18next';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { Input } from '@/ui/primitives/input';
import { Button } from '@/ui/primitives/button';
import { PressScale } from '@/ui/motion/press-scale';

// Warm earth palette — 8 quick-pick swatches
const QUICK_PICKS = [
  '#A1602F', '#C88226', '#5C7548', '#B23832',
  '#5C4E40', '#8B6F47', '#4A7C59', '#7A3B3B',
];

interface Props {
  visible: boolean;
  currentHex: string | null;
  defaultHex: string; // theme token resolved hex
  onSelect: (hex: string | null) => void;
  onClose: () => void;
}

const HEX_RE = /^#[0-9a-fA-F]{6}$/;

export function ColorPickerSheet({ visible, currentHex, defaultHex, onSelect, onClose }: Props) {
  const { t } = useTranslation();
  const [custom, setCustom] = useState(currentHex ?? '');
  const customValid = custom === '' || HEX_RE.test(custom);

  const handleQuickPick = (hex: string) => {
    onSelect(hex);
    onClose();
  };

  const handleCustomApply = () => {
    if (!customValid || custom === '') return;
    onSelect(custom.toLowerCase());
    onClose();
  };

  const handleReset = () => {
    onSelect(null);
    onClose();
  };

  return (
    <Modal visible={visible} animationType="slide" transparent presentationStyle="overFullScreen">
      <TouchableOpacity style={{ flex: 1, backgroundColor: 'rgba(0,0,0,0.4)' }} onPress={onClose} activeOpacity={1}>
        <View style={{ flex: 1 }} />
      </TouchableOpacity>
      <Surface className="rounded-t-3xl px-4 pb-8 pt-4">
        <View className="flex-row items-center justify-between mb-4">
          <Text className="text-lg font-semibold">{t('settings.marker_colors.picker_title')}</Text>
          <PressScale onPress={onClose} accessibilityLabel={t('common.close')}>
            <X size={22} color="#5C4E40" />
          </PressScale>
        </View>

        {/* Current / default preview */}
        <View className="flex-row items-center gap-3 mb-4">
          <View
            style={{ width: 32, height: 32, borderRadius: 16, backgroundColor: currentHex ?? defaultHex, borderWidth: 2, borderColor: '#DCD0C0' }}
          />
          <Text variant="muted" className="text-sm">{t('settings.marker_colors.current_color')}</Text>
        </View>

        {/* Quick-pick swatches */}
        <Text className="text-sm font-medium mb-2">{t('settings.marker_colors.quick_pick')}</Text>
        <View className="flex-row flex-wrap gap-3 mb-4">
          {QUICK_PICKS.map((hex) => (
            <PressScale
              key={hex}
              onPress={() => handleQuickPick(hex)}
              accessibilityLabel={`${t('common.select')} ${hex}`}
            >
              <View
                style={{
                  width: 36,
                  height: 36,
                  borderRadius: 18,
                  backgroundColor: hex,
                  borderWidth: currentHex === hex ? 3 : 1,
                  borderColor: currentHex === hex ? '#1C1612' : '#DCD0C0',
                }}
              />
            </PressScale>
          ))}
        </View>

        {/* Custom hex */}
        <Text className="text-sm font-medium mb-2">{t('settings.marker_colors.custom_hex')}</Text>
        <Input
          value={custom}
          onChangeText={setCustom}
          autoCapitalize="none"
          autoCorrect={false}
          placeholder="#A1602F"
          maxLength={7}
          accessibilityLabel={t('settings.marker_colors.custom_hex')}
        />
        {custom !== '' && !customValid ? (
          <Text className="text-sm text-danger dark:text-danger-dark mt-1">
            {t('settings.marker_colors.hex_invalid')}
          </Text>
        ) : null}
        <Button
          className="mt-2"
          onPress={handleCustomApply}
          disabled={!customValid || custom === ''}
          variant="secondary"
        >
          {t('settings.marker_colors.apply_custom')}
        </Button>

        {/* Reset */}
        <Button className="mt-3" variant="ghost" onPress={handleReset}>
          {t('settings.marker_colors.reset')}
        </Button>
      </Surface>
    </Modal>
  );
}
