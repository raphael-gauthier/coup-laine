import { useTranslation } from 'react-i18next';
import { CircleDot, Pencil, User } from 'lucide-react-native';
import { Text } from '@/ui/primitives/text';
import { HelpSheet, HelpSection, HelpPreview } from '@/ui/help/help-sheet';
import { StatusRowDemo } from '@/ui/help/previews/status-row-demo';

interface Props {
  visible: boolean;
  onClose: () => void;
}

export function HelpSheetStatuses({ visible, onClose }: Props) {
  const { t } = useTranslation();

  return (
    <HelpSheet visible={visible} onClose={onClose} title={t('help.statuses.title')}>
      <HelpSection icon={CircleDot} title={t('help.statuses.what_is_title')}>
        <Text>{t('help.statuses.what_is_body')}</Text>
      </HelpSection>

      <HelpPreview caption={t('help.statuses.caption_main')}>
        <StatusRowDemo />
      </HelpPreview>

      <HelpSection icon={Pencil} title={t('help.statuses.rename_title')}>
        <Text>{t('help.statuses.rename_body')}</Text>
      </HelpSection>

      <HelpSection icon={User} title={t('help.statuses.manual_title')}>
        <Text>{t('help.statuses.manual_body')}</Text>
      </HelpSection>
    </HelpSheet>
  );
}
