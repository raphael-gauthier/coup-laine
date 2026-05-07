import { useState } from 'react';
import { Linking, ScrollView, View } from 'react-native';
import * as Sentry from '@sentry/react-native';
import { useTranslation } from 'react-i18next';
import { AlertTriangle } from 'lucide-react-native';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { Button } from '@/ui/primitives/button';
import { ConfirmTypedDialog } from '@/ui/components/confirm-dialog';
import { useSession, useDeleteAccount } from '@/state/queries/auth';
import { useExportData } from '@/state/queries/backups';
import { successToast } from '@/ui/components/error-toast';

interface Props {
  storeUrl: string;
  security: boolean;
}

export function ForceUpdateScreen({ storeUrl, security }: Props) {
  const { t } = useTranslation();
  const { data: session } = useSession();
  const exportData = useExportData();
  const deleteAccount = useDeleteAccount();
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);

  const isLoggedIn = !!session && !session.user.is_anonymous;

  const handleUpdate = () => {
    Sentry.addBreadcrumb({
      category: 'version-gate',
      message: 'version-gate.action',
      data: { kind: 'open-store' },
    });
    void Linking.openURL(storeUrl);
  };

  const handleExport = () => {
    Sentry.addBreadcrumb({
      category: 'version-gate',
      message: 'version-gate.action',
      data: { kind: 'export-data' },
    });
    exportData.mutate();
  };

  const handleDeleteConfirmed = () => {
    Sentry.addBreadcrumb({
      category: 'version-gate',
      message: 'version-gate.action',
      data: { kind: 'delete-account' },
    });
    setDeleteDialogOpen(false);
    deleteAccount.mutate(undefined, {
      onSuccess: () => {
        successToast(t('cloud.delete_account.success_toast'));
      },
    });
  };

  return (
    <Surface className="flex-1">
      <ScrollView contentContainerStyle={{ flexGrow: 1, justifyContent: 'center', padding: 24 }}>
        <View className="items-center gap-6">
          {security && (
            <View className="flex-row items-center gap-2">
              <AlertTriangle size={20} />
              <Text variant="muted">{t('versionGate.force.securityNote')}</Text>
            </View>
          )}
          <Text className="text-2xl font-bold text-center">
            {t('versionGate.force.title')}
          </Text>
          <Text variant="muted" className="text-center">
            {t('versionGate.force.subtitle')}
          </Text>

          <Button onPress={handleUpdate} className="w-full">
            {t('versionGate.force.cta.update')}
          </Button>

          {isLoggedIn && (
            <View className="w-full gap-3 mt-8">
              <Text variant="muted" className="text-sm uppercase tracking-wide">
                {t('versionGate.force.yourData')}
              </Text>
              <Button
                variant="secondary"
                onPress={handleExport}
                loading={exportData.isPending}
              >
                {t('versionGate.force.cta.export')}
              </Button>
              <Button
                variant="ghost"
                onPress={() => setDeleteDialogOpen(true)}
                loading={deleteAccount.isPending}
              >
                {t('versionGate.force.cta.deleteAccount')}
              </Button>
            </View>
          )}
        </View>
      </ScrollView>

      <ConfirmTypedDialog
        visible={deleteDialogOpen}
        title={t('cloud.delete_account.confirm_title')}
        message={t('cloud.delete_account.confirm_message')}
        typedConfirmation={t('cloud.delete_account.typed_word')}
        confirmLabel={t('cloud.delete_account.cta_confirm')}
        cancelLabel={t('common.cancel')}
        onConfirm={handleDeleteConfirmed}
        onCancel={() => setDeleteDialogOpen(false)}
      />
    </Surface>
  );
}
