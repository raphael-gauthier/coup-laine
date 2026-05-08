import { useState } from 'react';
import { View } from 'react-native';
import { useTranslation } from 'react-i18next';
import { Text } from '@/ui/primitives/text';
import { Input } from '@/ui/primitives/input';
import { Button } from '@/ui/primitives/button';
import { PressScale } from '@/ui/motion/press-scale';
import { validateColorHex } from '@/domain/use-cases/validate-status';

export const PALETTE_PAIRS: readonly { light: string; dark: string }[] = [
  { light: '#A1602F', dark: '#C68A58' }, { light: '#5C7548', dark: '#98B282' },
  { light: '#C88226', dark: '#DC9E4E' }, { light: '#B23832', dark: '#DC605A' },
  { light: '#7A3B7A', dark: '#A766A7' }, { light: '#3D6A99', dark: '#6E9CC9' },
  { light: '#0F766E', dark: '#5EEAD4' }, { light: '#94A3B8', dark: '#64748B' },
  { light: '#475569', dark: '#94A3B8' }, { light: '#EAB308', dark: '#FACC15' },
  { light: '#DC2626', dark: '#F87171' }, { light: '#EA580C', dark: '#FB923C' },
  { light: '#16A34A', dark: '#4ADE80' }, { light: '#0EA5E9', dark: '#7DD3FC' },
  { light: '#6366F1', dark: '#A5B4FC' }, { light: '#A855F7', dark: '#D8B4FE' },
  { light: '#EC4899', dark: '#F9A8D4' }, { light: '#525252', dark: '#A3A3A3' },
  { light: '#EAE0D3', dark: '#302820' }, { light: '#5C4E40', dark: '#B4A490' },
  { light: '#854D0E', dark: '#FBBF24' }, { light: '#1E40AF', dark: '#60A5FA' },
  { light: '#831843', dark: '#FB7185' }, { light: '#365314', dark: '#A3E635' },
];

interface Props {
  value: { light: string; dark: string };
  onChange: (pair: { light: string; dark: string }) => void;
}

export function ColorPalette({ value, onChange }: Props) {
  const { t } = useTranslation();
  const [showCustom, setShowCustom] = useState(false);
  const [custom, setCustom] = useState('');
  const customValid = validateColorHex(custom);

  const isSelected = (p: { light: string; dark: string }) =>
    p.light === value.light && p.dark === value.dark;

  return (
    <View>
      <View className="flex-row flex-wrap gap-2.5">
        {PALETTE_PAIRS.map((p) => (
          <PressScale
            key={`${p.light}-${p.dark}`}
            onPress={() => onChange(p)}
            accessibilityLabel={`${p.light} / ${p.dark}`}
          >
            <View
              style={{
                width: 40, height: 40, borderRadius: 20,
                borderWidth: isSelected(p) ? 3 : 1,
                borderColor: isSelected(p) ? '#1C1612' : '#DCD0C0',
                overflow: 'hidden',
                position: 'relative',
              }}
            >
              <View style={{ position: 'absolute', left: 0, top: 0, bottom: 0, width: 20, backgroundColor: p.light }} />
              <View style={{ position: 'absolute', right: 0, top: 0, bottom: 0, width: 20, backgroundColor: p.dark }} />
            </View>
          </PressScale>
        ))}
      </View>

      <Button className="mt-3" variant="ghost" onPress={() => setShowCustom((v) => !v)}>
        {t('statuses.custom_color')}
      </Button>

      {showCustom ? (
        <View className="mt-2">
          <Input
            value={custom}
            onChangeText={setCustom}
            autoCapitalize="none"
            autoCorrect={false}
            placeholder="#A1602F"
            maxLength={7}
            accessibilityLabel={t('statuses.custom_color')}
          />
          {custom !== '' && !customValid ? (
            <Text className="text-sm text-danger dark:text-danger-dark mt-1">
              {t('statuses.hex_invalid')}
            </Text>
          ) : null}
          <Text variant="muted" className="text-xs mt-1">
            {t('statuses.custom_color_note')}
          </Text>
          <Button
            className="mt-2"
            variant="secondary"
            onPress={() => {
              if (!customValid) return;
              onChange({ light: custom.toLowerCase(), dark: custom.toLowerCase() });
            }}
            disabled={!customValid}
          >
            {t('statuses.apply_custom')}
          </Button>
        </View>
      ) : null}
    </View>
  );
}
