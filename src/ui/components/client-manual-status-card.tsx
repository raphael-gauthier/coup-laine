import { useState } from 'react';
import { View } from 'react-native';
import { useTranslation } from 'react-i18next';
import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { Button } from '@/ui/primitives/button';
import { ManualStatusPicker } from '@/ui/components/manual-status-picker';
import { useStatusRegistry, useAssignManualStatus } from '@/state/queries/statuses';
import { useResolvedColorScheme } from '@/ui/theme/theme-provider';
import { mutationErrorToast } from '@/ui/components/error-toast';
import { haptics } from '@/ui/motion/haptics';

interface Props {
  clientId: string;
  manualStatusId: string | null;
}

export function ClientManualStatusCard({ clientId, manualStatusId }: Props) {
  const { t } = useTranslation();
  const { data: registry } = useStatusRegistry();
  const assignMut = useAssignManualStatus();
  const scheme = useResolvedColorScheme();
  const [pickerOpen, setPickerOpen] = useState(false);

  const current = manualStatusId ? registry?.byId(manualStatusId) ?? null : null;

  const handleSelect = (statusId: string | null) => {
    setPickerOpen(false);
    assignMut.mutate(
      { clientId, statusId },
      {
        onSuccess: () => { void haptics.success(); },
        onError: (err) => mutationErrorToast(t('statuses.save_failed'), err),
      },
    );
  };

  return (
    <Surface variant="muted" className="rounded-2xl px-4 py-3">
      <Text className="text-sm font-semibold mb-2">{t('statuses.manual_card_title')}</Text>
      <View className="flex-row items-center gap-3">
        {current ? (
          <View className="flex-row items-center gap-2 flex-1">
            <View
              style={{
                width: 16, height: 16, borderRadius: 8,
                backgroundColor: scheme === 'dark' ? current.colorDark : current.colorLight,
              }}
            />
            <Text>{current.label}</Text>
          </View>
        ) : (
          <Text variant="muted" className="flex-1">{t('statuses.manual_card_none')}</Text>
        )}
        <Button
          size="sm"
          variant={current ? 'ghost' : 'secondary'}
          onPress={() => {
            if (current) handleSelect(null);
            else setPickerOpen(true);
          }}
        >
          {current ? t('statuses.manual_card_clear') : t('statuses.manual_card_pick')}
        </Button>
      </View>
      <Text variant="muted" className="text-xs mt-2">{t('statuses.manual_card_help')}</Text>

      <ManualStatusPicker
        visible={pickerOpen}
        currentManualId={manualStatusId}
        onSelect={handleSelect}
        onClose={() => setPickerOpen(false)}
      />
    </Surface>
  );
}
