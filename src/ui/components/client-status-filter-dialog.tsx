import { useEffect, useState } from 'react';
import { Modal, View, TouchableOpacity } from 'react-native';
import { Filter } from 'lucide-react-native';
import { useTranslation } from 'react-i18next';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { Button } from '@/ui/primitives/button';
import { ThemedSwitch } from '@/ui/primitives/themed-switch';
import { PressScale } from '@/ui/motion/press-scale';
import { useClientFiltersStore } from '@/state/ui/client-filters-store';
import { useStatusRegistry } from '@/state/queries/statuses';
import { haptics } from '@/ui/motion/haptics';

interface Props {
  visible: boolean;
  onClose: () => void;
}

export function ClientStatusFilterDialog({ visible, onClose }: Props) {
  const { t } = useTranslation();
  const { data: registry } = useStatusRegistry();
  const { enabledStatusIds, uninitialized, setAll, setNone, toggle, initWithAll, reconcileWith } = useClientFiltersStore();

  const all = registry?.list ?? [];
  const allIds = all.map((s) => s.id);
  const allIdsKey = allIds.join(',');

  // Initialize the store with all enabled the first time the registry is available.
  // Afterwards, reconcile so newly-created statuses default to enabled — without
  // re-enabling any status the user has explicitly unchecked.
  useEffect(() => {
    if (uninitialized && all.length > 0) initWithAll(allIds);
    else if (!uninitialized) reconcileWith(allIds);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [uninitialized, allIdsKey]);

  const [draft, setDraft] = useState<Set<string>>(new Set(enabledStatusIds));
  useEffect(() => { setDraft(new Set(enabledStatusIds)); }, [enabledStatusIds]);

  const handleToggle = (id: string) => {
    const next = new Set(draft);
    if (next.has(id)) next.delete(id);
    else next.add(id);
    setDraft(next);
  };

  const handleApply = () => {
    if (draft.size === allIds.length) setAll(allIds);
    else if (draft.size === 0) setNone();
    else {
      // diff against current
      for (const id of allIds) {
        const has = draft.has(id);
        const had = enabledStatusIds.has(id);
        if (has !== had) toggle(id);
      }
    }
    void haptics.success();
    onClose();
  };

  const handleAll = () => setDraft(new Set(allIds));
  const handleNone = () => setDraft(new Set());

  return (
    <Modal visible={visible} animationType="slide" transparent presentationStyle="overFullScreen">
      <TouchableOpacity style={{ flex: 1, backgroundColor: 'rgba(0,0,0,0.4)' }} onPress={onClose} activeOpacity={1} />
      <Surface className="rounded-t-3xl px-4 pb-8 pt-4">
        <View className="flex-row items-center justify-between mb-4">
          <Text className="text-lg font-semibold">{t('clients.filter_dialog_title')}</Text>
          <View className="flex-row gap-2">
            <Button size="sm" variant="ghost" onPress={handleAll}>{t('clients.filter_all_btn')}</Button>
            <Button size="sm" variant="ghost" onPress={handleNone}>{t('clients.filter_none_btn')}</Button>
          </View>
        </View>

        {all.map((s) => (
          <View key={s.id} className="flex-row items-center justify-between py-3 border-b border-border dark:border-border-dark">
            <Text className="text-sm">{s.label}</Text>
            <ThemedSwitch value={draft.has(s.id)} onValueChange={() => handleToggle(s.id)} />
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
      <PressScale onPress={() => setVisible(true)} accessibilityLabel={t('clients.filter_dialog_title')}>
        <Filter size={20} color="#5C4E40" />
      </PressScale>
      <ClientStatusFilterDialog visible={visible} onClose={() => setVisible(false)} />
    </>
  );
}
