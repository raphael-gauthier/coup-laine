import { useState } from 'react';
import { ScrollView, View } from 'react-native';
import { useTranslation } from 'react-i18next';

import { Text } from '@/ui/primitives/text';
import { Input } from '@/ui/primitives/input';
import { Button } from '@/ui/primitives/button';
import { ColorPalette } from '@/ui/components/color-palette';
import { haptics } from '@/ui/motion/haptics';
import { validateStatusLabel } from '@/domain/use-cases/validate-status';
import type { Status } from '@/domain/models/status';

export interface StatusFormValues {
  label: string;
  colorLight: string;
  colorDark: string;
}

interface Props {
  initial?: Status;
  saving?: boolean;
  onSubmit: (values: StatusFormValues) => void;
  onCancel?: () => void;
}

export function StatusForm({ initial, saving, onSubmit, onCancel }: Props) {
  const { t } = useTranslation();
  const [label, setLabel] = useState(initial?.label ?? '');
  const [colors, setColors] = useState({
    light: initial?.colorLight ?? '#A1602F',
    dark: initial?.colorDark ?? '#C68A58',
  });

  const labelV = validateStatusLabel(label);
  const labelError = !labelV.ok
    ? labelV.error === 'empty'
      ? t('statuses.label_empty')
      : t('statuses.label_too_long')
    : null;

  const handleSave = () => {
    if (!labelV.ok) {
      void haptics.error();
      return;
    }
    onSubmit({ label: labelV.value, colorLight: colors.light, colorDark: colors.dark });
  };

  return (
    <ScrollView contentContainerStyle={{ paddingHorizontal: 16, paddingTop: 16, paddingBottom: 32, gap: 16 }}>
      <View>
        <Text className="text-sm font-medium mb-1">{t('statuses.label')}</Text>
        <Input
          value={label}
          onChangeText={setLabel}
          maxLength={30}
          accessibilityLabel={t('statuses.label')}
        />
        {labelError ? (
          <Text className="text-sm text-danger dark:text-danger-dark mt-1">{labelError}</Text>
        ) : null}
      </View>

      <View>
        <Text className="text-sm font-medium mb-2">{t('statuses.color')}</Text>
        <ColorPalette value={colors} onChange={setColors} />
      </View>

      <View className="flex-row gap-2 mt-4">
        {onCancel ? (
          <Button variant="secondary" className="flex-1" onPress={onCancel} disabled={saving}>
            {t('common.cancel')}
          </Button>
        ) : null}
        <Button className="flex-1" onPress={handleSave} loading={saving} disabled={!labelV.ok}>
          {t('statuses.save')}
        </Button>
      </View>
    </ScrollView>
  );
}
