import { useTranslation } from 'react-i18next';
import { Package, Plus, Archive } from 'lucide-react-native';
import { Text } from '@/ui/primitives/text';
import { HelpSheet, HelpSection, HelpPreview } from '@/ui/help/help-sheet';
import { ServiceRowDemo } from '@/ui/help/previews/service-row-demo';

interface Props {
  visible: boolean;
  onClose: () => void;
}

export function HelpSheetServicesCatalog({ visible, onClose }: Props) {
  const { t } = useTranslation();

  return (
    <HelpSheet visible={visible} onClose={onClose} title={t('help.services_catalog.title')}>
      <HelpSection icon={Package} title={t('help.services_catalog.what_is_title')}>
        <Text>{t('help.services_catalog.what_is_body')}</Text>
      </HelpSection>

      <HelpPreview caption={t('help.services_catalog.caption_main')}>
        <ServiceRowDemo />
      </HelpPreview>

      <HelpSection icon={Plus} title={t('help.services_catalog.create_title')}>
        <Text>{t('help.services_catalog.create_body')}</Text>
      </HelpSection>

      <HelpSection icon={Archive} title={t('help.services_catalog.archive_title')}>
        <Text>{t('help.services_catalog.archive_body')}</Text>
      </HelpSection>
    </HelpSheet>
  );
}
