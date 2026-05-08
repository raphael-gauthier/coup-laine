import { useEffect, useState } from 'react';
import { Modal, View, TouchableOpacity, Alert } from 'react-native';
import { X } from 'lucide-react-native';
import { useTranslation } from 'react-i18next';
import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { Input } from '@/ui/primitives/input';
import { Button } from '@/ui/primitives/button';
import { PressScale } from '@/ui/motion/press-scale';
import { ColorPalette } from '@/ui/components/color-palette';
import { mutationErrorToast } from '@/ui/components/error-toast';
import { haptics } from '@/ui/motion/haptics';
import { validateStatusLabel } from '@/domain/use-cases/validate-status';
import {
  useCreateManualStatus,
  useRenameStatus,
  useRecolorStatus,
  useDeleteManualStatus,
  useCountClientsUsingStatus,
} from '@/state/queries/statuses';
import type { Status } from '@/domain/models/status';

interface Props {
  visible: boolean;
  /** When null, the sheet is in 'create' mode (only used for manual creation). */
  status: Status | null;
  onClose: () => void;
}

export function StatusEditSheet({ visible, status, onClose }: Props) {
  const { t } = useTranslation();
  const createMut = useCreateManualStatus();
  const renameMut = useRenameStatus();
  const recolorMut = useRecolorStatus();
  const deleteMut = useDeleteManualStatus();
  const { data: usingCount } = useCountClientsUsingStatus(
    status?.kind === 'manual' ? status.id : null,
  );

  const [label, setLabel] = useState(status?.label ?? '');
  const [colors, setColors] = useState({
    light: status?.colorLight ?? '#A1602F',
    dark: status?.colorDark ?? '#C68A58',
  });

  // Reset local state when status prop changes (e.g. user opens a different row)
  useEffect(() => {
    setLabel(status?.label ?? '');
    setColors({
      light: status?.colorLight ?? '#A1602F',
      dark: status?.colorDark ?? '#C68A58',
    });
  }, [status?.id, status?.label, status?.colorLight, status?.colorDark]);

  const labelV = validateStatusLabel(label);
  const labelError = !labelV.ok
    ? labelV.error === 'empty'
      ? t('statuses.label_empty')
      : t('statuses.label_too_long')
    : null;

  const handleSave = () => {
    if (!labelV.ok) return;
    if (status) {
      // Edit existing: rename + recolor in parallel
      const labelChanged = labelV.value !== status.label;
      const colorChanged =
        colors.light !== status.colorLight || colors.dark !== status.colorDark;
      const work: Promise<unknown>[] = [];
      if (labelChanged) {
        work.push(renameMut.mutateAsync({ id: status.id, label: labelV.value }));
      }
      if (colorChanged) {
        work.push(
          recolorMut.mutateAsync({
            id: status.id,
            colorLight: colors.light,
            colorDark: colors.dark,
          }),
        );
      }
      Promise.all(work).then(
        () => {
          void haptics.success();
          onClose();
        },
        (err) => mutationErrorToast(t('statuses.save_failed'), err),
      );
    } else {
      createMut.mutate(
        { label: labelV.value, colorLight: colors.light, colorDark: colors.dark },
        {
          onSuccess: () => {
            void haptics.success();
            onClose();
          },
          onError: (err) => mutationErrorToast(t('statuses.save_failed'), err),
        },
      );
    }
  };

  const handleDelete = () => {
    if (!status || status.kind !== 'manual') return;
    const count = usingCount ?? 0;
    const body =
      count === 0
        ? t('statuses.delete_confirm_body_zero')
        : count === 1
          ? t('statuses.delete_confirm_body_one')
          : t('statuses.delete_confirm_body_other', { count });
    Alert.alert(t('statuses.delete_confirm_title'), body, [
      { text: t('common.cancel'), style: 'cancel' },
      {
        text: t('statuses.delete_confirm_continue'),
        style: 'destructive',
        onPress: () => {
          deleteMut.mutate(status.id, {
            onSuccess: () => {
              void haptics.success();
              onClose();
            },
            onError: (err) => mutationErrorToast(t('statuses.save_failed'), err),
          });
        },
      },
    ]);
  };

  return (
    <Modal
      visible={visible}
      animationType="slide"
      transparent
      presentationStyle="overFullScreen"
    >
      <TouchableOpacity
        style={{ flex: 1, backgroundColor: 'rgba(0,0,0,0.4)' }}
        onPress={onClose}
        activeOpacity={1}
      />
      <Surface className="rounded-t-3xl px-4 pb-8 pt-4">
        <View className="flex-row items-center justify-between mb-4">
          <Text className="text-lg font-semibold">
            {status ? t('statuses.edit_title') : t('statuses.create_title')}
          </Text>
          <PressScale onPress={onClose} accessibilityLabel={t('common.close')}>
            <X size={22} color="#5C4E40" />
          </PressScale>
        </View>

        <Text className="text-sm font-medium mb-1">{t('statuses.label')}</Text>
        <Input
          value={label}
          onChangeText={setLabel}
          maxLength={30}
          accessibilityLabel={t('statuses.label')}
        />
        {labelError ? (
          <Text className="text-sm text-danger dark:text-danger-dark mt-1">
            {labelError}
          </Text>
        ) : null}

        <Text className="text-sm font-medium mb-2 mt-4">{t('statuses.color')}</Text>
        <ColorPalette value={colors} onChange={setColors} />

        {status?.kind === 'manual' ? (
          <Button className="mt-4" variant="ghost" onPress={handleDelete}>
            {t('statuses.delete')}
          </Button>
        ) : null}

        <View className="flex-row gap-2 mt-4">
          <Button variant="secondary" className="flex-1" onPress={onClose}>
            {t('common.cancel')}
          </Button>
          <Button className="flex-1" onPress={handleSave} disabled={!labelV.ok}>
            {t('statuses.save')}
          </Button>
        </View>
      </Surface>
    </Modal>
  );
}
