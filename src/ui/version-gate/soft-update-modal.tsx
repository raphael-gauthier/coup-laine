import { Linking, Modal, View } from 'react-native';
import * as Sentry from '@sentry/react-native';
import { useTranslation } from 'react-i18next';
import { AlertTriangle } from 'lucide-react-native';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { Button } from '@/ui/primitives/button';

interface Props {
  visible: boolean;
  latestVersion: string;
  releaseNotesFr: string | null;
  security: boolean;
  storeUrl: string;
  onSnooze: () => void;
}

export function SoftUpdateModal({
  visible,
  latestVersion,
  releaseNotesFr,
  security,
  storeUrl,
  onSnooze,
}: Props) {
  const { t } = useTranslation();

  const handleUpdate = () => {
    Sentry.addBreadcrumb({
      category: 'version-gate',
      message: 'version-gate.action',
      data: { kind: 'open-store', latestVersion },
    });
    void Linking.openURL(storeUrl);
  };

  const handleSnooze = () => {
    Sentry.addBreadcrumb({
      category: 'version-gate',
      message: 'version-gate.action',
      data: { kind: 'snooze', latestVersion },
    });
    onSnooze();
  };

  return (
    <Modal
      visible={visible}
      transparent
      animationType="fade"
      onRequestClose={handleSnooze}
    >
      <View className="flex-1 items-center justify-center bg-black/40 px-6">
        <Surface className="w-full rounded-2xl p-6 gap-4">
          <Text className="text-xl font-bold">{t('versionGate.soft.title')}</Text>

          {security && (
            <View className="flex-row items-center gap-2">
              <AlertTriangle size={16} />
              <Text variant="muted" className="text-sm">
                {t('versionGate.soft.securityNote')}
              </Text>
            </View>
          )}

          <Text variant="muted">
            {releaseNotesFr ?? t('versionGate.soft.fallbackNotes')}
          </Text>

          <View className="flex-row gap-3 justify-end mt-2">
            <Button variant="ghost" onPress={handleSnooze}>
              {t('versionGate.soft.cta.later')}
            </Button>
            <Button onPress={handleUpdate}>{t('versionGate.soft.cta.update')}</Button>
          </View>
        </Surface>
      </View>
    </Modal>
  );
}
