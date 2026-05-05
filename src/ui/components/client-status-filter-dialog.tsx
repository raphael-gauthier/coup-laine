import { useState } from 'react';
import { Modal, View, TouchableOpacity } from 'react-native';
import { ThemedSwitch } from '@/ui/primitives/themed-switch';
import { Filter } from 'lucide-react-native';
import { useTranslation } from 'react-i18next';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { Button } from '@/ui/primitives/button';
import { PressScale } from '@/ui/motion/press-scale';
import { useClientFiltersStore } from '@/state/ui/client-filters-store';
import { haptics } from '@/ui/motion/haptics';
import type { ClientStatus } from '@/domain/use-cases/client-status';

const STATUSES: { status: ClientStatus; labelKey: string }[] = [
  { status: 'default',   labelKey: 'clients.filter_status_default' },
  { status: 'waiting',   labelKey: 'clients.filter_status_waiting' },
  { status: 'scheduled', labelKey: 'clients.filter_status_scheduled' },
  { status: 'done',      labelKey: 'clients.filter_status_done' },
  { status: 'noAnimals', labelKey: 'clients.filter_status_no_animals' },
  { status: 'banned',    labelKey: 'clients.filter_status_banned' },
];

interface Props {
  visible: boolean;
  onClose: () => void;
}

export function ClientStatusFilterDialog({ visible, onClose }: Props) {
  const { t } = useTranslation();
  const { enabledStatuses, toggle } = useClientFiltersStore();
  // Local draft state
  const [draft, setDraft] = useState<Set<ClientStatus>>(new Set(enabledStatuses));

  const handleToggle = (status: ClientStatus) => {
    const next = new Set(draft);
    if (next.has(status)) next.delete(status);
    else next.add(status);
    setDraft(next);
  };

  const handleApply = () => {
    // Apply draft to store
    STATUSES.forEach(({ status }) => {
      const shouldEnable = draft.has(status);
      const isEnabled = enabledStatuses.has(status);
      if (shouldEnable !== isEnabled) toggle(status);
    });
    void haptics.success();
    onClose();
  };

  const handleAll = () => setDraft(new Set(STATUSES.map((s) => s.status)));
  const handleNone = () => setDraft(new Set());

  return (
    <Modal visible={visible} animationType="slide" transparent presentationStyle="overFullScreen">
      <TouchableOpacity
        style={{ flex: 1, backgroundColor: 'rgba(0,0,0,0.4)' }}
        onPress={onClose}
        activeOpacity={1}
      />
      <Surface className="rounded-t-3xl px-4 pb-8 pt-4">
        <View className="flex-row items-center justify-between mb-4">
          <Text className="text-lg font-semibold">{t('clients.filter_dialog_title')}</Text>
          <View className="flex-row gap-2">
            <Button size="sm" variant="ghost" onPress={handleAll}>{t('clients.filter_all_btn')}</Button>
            <Button size="sm" variant="ghost" onPress={handleNone}>{t('clients.filter_none_btn')}</Button>
          </View>
        </View>

        {STATUSES.map(({ status, labelKey }) => (
          <View key={status} className="flex-row items-center justify-between py-3 border-b border-border dark:border-border-dark">
            <Text className="text-sm">{t(labelKey)}</Text>
            <ThemedSwitch
              value={draft.has(status)}
              onValueChange={() => handleToggle(status)}
            />
          </View>
        ))}

        <View className="flex-row gap-2 mt-4">
          <Button variant="secondary" className="flex-1" onPress={onClose}>{t('common.cancel')}</Button>
          <Button className="flex-1" onPress={handleApply}>{t('common.save')}</Button>
        </View>
      </Surface>
    </Modal>
  );
}

export function ClientFilterButton() {
  const { t } = useTranslation();
  const [visible, setVisible] = useState(false);
  return (
    <>
      <PressScale
        onPress={() => setVisible(true)}
        accessibilityLabel={t('clients.filter_dialog_title')}
      >
        <Filter size={20} color="#5C4E40" />
      </PressScale>
      <ClientStatusFilterDialog visible={visible} onClose={() => setVisible(false)} />
    </>
  );
}
