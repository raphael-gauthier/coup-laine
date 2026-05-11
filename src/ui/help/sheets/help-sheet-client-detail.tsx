import { useTranslation } from 'react-i18next';
import { User, Pencil, History, CircleDot, Trash2 } from 'lucide-react-native';
import { Text } from '@/ui/primitives/text';
import { HelpSheet, HelpSection } from '@/ui/help/help-sheet';

interface Props {
  visible: boolean;
  onClose: () => void;
}

export function HelpSheetClientDetail({ visible, onClose }: Props) {
  const { t } = useTranslation();

  return (
    <HelpSheet visible={visible} onClose={onClose} title={t('help.client_detail.title')}>
      <HelpSection icon={User} title={t('help.client_detail.what_is_title')}>
        <Text>{t('help.client_detail.what_is_body')}</Text>
      </HelpSection>

      <HelpSection icon={Pencil} title={t('help.client_detail.edit_title')}>
        <Text>{t('help.client_detail.edit_body')}</Text>
      </HelpSection>

      <HelpSection icon={History} title={t('help.client_detail.history_title')}>
        <Text>{t('help.client_detail.history_body')}</Text>
      </HelpSection>

      <HelpSection icon={CircleDot} title={t('help.client_detail.manual_status_title')}>
        <Text>{t('help.client_detail.manual_status_body')}</Text>
      </HelpSection>

      <HelpSection icon={Trash2} title={t('help.client_detail.delete_title')}>
        <Text>{t('help.client_detail.delete_body')}</Text>
      </HelpSection>
    </HelpSheet>
  );
}
