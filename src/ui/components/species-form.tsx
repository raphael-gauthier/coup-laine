import { useState, useMemo } from 'react';
import { ScrollView, View } from 'react-native';
import { useTranslation } from 'react-i18next';

import { Text } from '@/ui/primitives/text';
import { Input } from '@/ui/primitives/input';
import { Button } from '@/ui/primitives/button';
import type { Species } from '@/domain/models/species';
import type { UpsertSpeciesInput } from '@/state/queries/catalogs';

interface Props {
  initial?: Species;
  saving?: boolean;
  onSubmit: (input: UpsertSpeciesInput) => void;
  onCancel?: () => void;
}

export function SpeciesForm({ initial, saving, onSubmit, onCancel }: Props) {
  const { t } = useTranslation();
  const [label, setLabel] = useState(initial?.label ?? '');
  const [iconKey, setIconKey] = useState(initial?.iconKey ?? '');
  const [labelTouched, setLabelTouched] = useState(false);

  const errors = useMemo(() => {
    const out: { label?: string } = {};
    if (label.trim().length === 0) out.label = t('catalogs.errors.label_required');
    return out;
  }, [label, t]);

  const canSubmit = !errors.label && !saving;

  const handleSubmit = () => {
    setLabelTouched(true);
    if (!canSubmit) return;
    onSubmit({
      id: initial?.id,
      label: label.trim(),
      iconKey: iconKey.trim() || null,
      ordering: initial?.ordering ?? 100,
    });
  };

  return (
    <ScrollView contentContainerStyle={{ paddingHorizontal: 16, paddingTop: 16, paddingBottom: 32, gap: 16 }}>
      <View className="gap-2">
        <Text className="text-sm font-medium">{t('catalogs.species.label')}</Text>
        <Input value={label} onChangeText={setLabel} onBlur={() => setLabelTouched(true)} />
        {labelTouched && errors.label ? (
          <Text className="text-sm text-danger dark:text-danger-dark">{errors.label}</Text>
        ) : null}
      </View>

      <View className="gap-2">
        <Text className="text-sm font-medium">{t('catalogs.species.icon_key')}</Text>
        <Input value={iconKey} onChangeText={setIconKey} placeholder="mouton" autoCapitalize="none" />
      </View>

      <View className="flex-row gap-2 mt-4">
        {onCancel ? (
          <Button variant="secondary" className="flex-1" onPress={onCancel} disabled={saving}>
            {t('common.cancel')}
          </Button>
        ) : null}
        <Button className="flex-1" onPress={handleSubmit} disabled={!canSubmit} loading={saving}>
          {t('common.save')}
        </Button>
      </View>
    </ScrollView>
  );
}
