import { useLocalSearchParams, useRouter } from 'expo-router';
import { Trash2 } from 'lucide-react-native';
import { useTranslation } from 'react-i18next';

import { Surface } from '@/ui/primitives/surface';
import { Button } from '@/ui/primitives/button';
import { ScreenHeader } from '@/ui/components/screen-header';
import { confirm } from '@/ui/components/confirm-dialog';
import { mutationErrorToast } from '@/ui/components/error-toast';
import { StatusForm, type StatusFormValues } from '@/ui/components/status-form';
import {
  useStatusRegistry,
  useRenameStatus,
  useRecolorStatus,
  useDeleteManualStatus,
  useCountClientsUsingStatus,
} from '@/state/queries/statuses';
import { haptics } from '@/ui/motion/haptics';
import { useOnContrastColor } from '@/ui/theme/colors';

export default function EditStatusScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const router = useRouter();
  const { t } = useTranslation();
  const onContrast = useOnContrastColor();
  const { data: registry } = useStatusRegistry();
  const renameMut = useRenameStatus();
  const recolorMut = useRecolorStatus();
  const deleteMut = useDeleteManualStatus();

  const item = registry?.byId(id) ?? null;
  const { data: usingCount } = useCountClientsUsingStatus(
    item?.kind === 'manual' ? item.id : null,
  );

  if (!item) return <Surface className="flex-1" />;

  const saving = renameMut.isPending || recolorMut.isPending;

  const onSubmit = (values: StatusFormValues) => {
    const labelChanged = values.label !== item.label;
    const colorChanged =
      values.colorLight !== item.colorLight || values.colorDark !== item.colorDark;
    const work: Promise<unknown>[] = [];
    if (labelChanged) work.push(renameMut.mutateAsync({ id: item.id, label: values.label }));
    if (colorChanged) {
      work.push(
        recolorMut.mutateAsync({
          id: item.id,
          colorLight: values.colorLight,
          colorDark: values.colorDark,
        }),
      );
    }
    Promise.all(work).then(
      () => { void haptics.success(); router.back(); },
      (err) => mutationErrorToast(t('statuses.save_failed'), err),
    );
  };

  const onDelete = async () => {
    if (item.kind !== 'manual') return;
    const count = usingCount ?? 0;
    const message =
      count === 0
        ? t('statuses.delete_confirm_body_zero')
        : count === 1
          ? t('statuses.delete_confirm_body_one')
          : t('statuses.delete_confirm_body_other', { count });
    const ok = await confirm({
      title: t('statuses.delete_confirm_title'),
      message,
      confirmLabel: t('statuses.delete_confirm_continue'),
      cancelLabel: t('common.cancel'),
      destructive: true,
    });
    if (!ok) return;
    deleteMut.mutate(item.id, {
      onSuccess: () => { void haptics.success(); router.back(); },
      onError: (err) => mutationErrorToast(t('statuses.save_failed'), err),
    });
  };

  return (
    <Surface className="flex-1">
      <ScreenHeader
        title={t('statuses.edit_title')}
        rightSlot={
          item.kind === 'manual' ? (
            <Button size="sm" variant="danger" onPress={onDelete} accessibilityLabel={t('statuses.delete')}>
              <Trash2 size={16} color={onContrast} />
            </Button>
          ) : undefined
        }
      />
      <StatusForm
        initial={item}
        saving={saving}
        onCancel={() => router.back()}
        onSubmit={onSubmit}
      />
    </Surface>
  );
}
