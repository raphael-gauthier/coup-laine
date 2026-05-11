import { useTranslation } from 'react-i18next';
import { Settings, List } from 'lucide-react-native';
import { Text } from '@/ui/primitives/text';
import { HelpSheet, HelpSection } from '@/ui/help/help-sheet';

interface Props {
  visible: boolean;
  onClose: () => void;
}

export function HelpSheetSettings({ visible, onClose }: Props) {
  const { t } = useTranslation();

  return (
    <HelpSheet visible={visible} onClose={onClose} title={t('help.settings.title')}>
      <HelpSection icon={Settings} title={t('help.settings.what_is_title')}>
        <Text>{t('help.settings.what_is_body')}</Text>
      </HelpSection>

      <HelpSection icon={List} title={t('help.settings.sections_title')}>
        <Text>{t('help.settings.sections_body')}</Text>
      </HelpSection>
    </HelpSheet>
  );
}
