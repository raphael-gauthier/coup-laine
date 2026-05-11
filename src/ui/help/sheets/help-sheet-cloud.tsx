import { useTranslation } from 'react-i18next';
import { Cloud, Mail, RefreshCw, Download } from 'lucide-react-native';
import { Text } from '@/ui/primitives/text';
import { HelpSheet, HelpSection } from '@/ui/help/help-sheet';

interface Props {
  visible: boolean;
  onClose: () => void;
}

export function HelpSheetCloud({ visible, onClose }: Props) {
  const { t } = useTranslation();

  return (
    <HelpSheet visible={visible} onClose={onClose} title={t('help.cloud.title')}>
      <HelpSection icon={Cloud} title={t('help.cloud.what_is_title')}>
        <Text>{t('help.cloud.what_is_body')}</Text>
      </HelpSection>

      <HelpSection icon={Mail} title={t('help.cloud.login_title')}>
        <Text>{t('help.cloud.login_body')}</Text>
      </HelpSection>

      <HelpSection icon={RefreshCw} title={t('help.cloud.auto_title')}>
        <Text>{t('help.cloud.auto_body')}</Text>
      </HelpSection>

      <HelpSection icon={Download} title={t('help.cloud.restore_title')}>
        <Text>{t('help.cloud.restore_body')}</Text>
      </HelpSection>
    </HelpSheet>
  );
}
