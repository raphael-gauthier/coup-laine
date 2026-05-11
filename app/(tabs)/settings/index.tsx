import { ScrollView } from 'react-native';
import { useRouter } from 'expo-router';
import { useTranslation } from 'react-i18next';
import { Surface } from '@/ui/primitives/surface';
import { SectionHeader } from '@/ui/primitives/section-header';
import { ScreenHeader } from '@/ui/components/screen-header';
import { SettingsRow } from '@/ui/components/settings-row';
import { useSession } from '@/state/queries/auth';
import { TUTORIAL_KEYS } from '@/domain/tutorial/keys';
import { HelpButton } from '@/ui/help/help-button';
import { HelpSheetSettings } from '@/ui/help/sheets/help-sheet-settings';
import { useHelpSheet } from '@/ui/help/hooks';

export default function SettingsScreen() {
  const router = useRouter();
  const { t } = useTranslation();
  const { data: session } = useSession();
  const helpSheet = useHelpSheet(TUTORIAL_KEYS.sheetSettings);

  return (
    <Surface className="flex-1">
      <ScreenHeader
        variant="root"
        title={t('settings.title')}
        rightSlot={<HelpButton tutorialKey={TUTORIAL_KEYS.sheetSettings} onPress={helpSheet.open} />}
      />
      <ScrollView contentContainerClassName="px-4 pb-8">

        <SectionHeader title={t('settings.section_app')} />
        <SettingsRow
          label={t('settings.appearance.row_label')}
          hint={t('settings.appearance.row_hint')}
          onPress={() => router.push('/(tabs)/settings/appearance')}
        />
        <SettingsRow
          label={t('settings.language.row_label')}
          hint={t('settings.language.row_hint')}
          onPress={() => {}}
        />

        <SectionHeader title={t('settings.section_home_tour')} />
        <SettingsRow
          label={t('settings.base.row_label')}
          hint={t('settings.base.row_hint')}
          onPress={() => router.push('/(tabs)/settings/base')}
        />
        <SettingsRow
          label={t('settings.tour_rate.row_label')}
          hint={t('settings.tour_rate.row_hint')}
          onPress={() => router.push('/(tabs)/settings/tour-rate' as never)}
        />
        <SettingsRow
          label={t('settings.proximity.row_label')}
          hint={t('settings.proximity.row_hint')}
          onPress={() => router.push('/(tabs)/settings/proximity' as never)}
        />
        <SettingsRow
          label={t('settings.season.row_label')}
          hint={t('settings.season.row_hint')}
          onPress={() => router.push('/(tabs)/settings/season' as never)}
        />

        <SectionHeader title={t('settings.section_map')} />
        <SettingsRow
          label={t('statuses.screen_title')}
          hint={t('statuses.row_hint')}
          onPress={() => router.push('/(tabs)/settings/statuses' as never)}
        />

        <SectionHeader title={t('settings.section_catalog')} />
        <SettingsRow
          label={t('catalogs.species.row_label')}
          hint={t('catalogs.species.row_hint')}
          onPress={() => router.push('/(tabs)/settings/species' as never)}
        />
        <SettingsRow
          label={t('catalogs.services.row_label')}
          hint={t('catalogs.services.row_hint')}
          onPress={() => router.push('/(tabs)/settings/services' as never)}
        />
        <SettingsRow
          label={t('catalogs.payment_methods.row_label')}
          hint={t('catalogs.payment_methods.row_hint')}
          onPress={() => router.push('/(tabs)/settings/payment-methods' as never)}
        />

        <SectionHeader title={t('settings.section_cloud')} />
        <SettingsRow
          label={t('cloud.row_label')}
          hint={session && !session.user.is_anonymous ? t('cloud.row_hint_logged_in') : t('cloud.row_hint_logged_out')}
          onPress={() => router.push('/(tabs)/settings/cloud' as never)}
        />

        <SectionHeader title={t('settings.section_legal')} />
        <SettingsRow
          label={t('settings.legal.row_label')}
          hint={t('settings.legal.row_hint')}
          onPress={() => router.push('/(tabs)/settings/legal' as never)}
        />

        <SectionHeader title={t('settings.section_help')} />
        <SettingsRow
          label={t('settings.help.row_label')}
          hint={t('settings.help.row_hint')}
          onPress={() => router.push('/(tabs)/settings/help' as never)}
        />
      </ScrollView>

      <HelpSheetSettings visible={helpSheet.isOpen} onClose={helpSheet.close} />
    </Surface>
  );
}
