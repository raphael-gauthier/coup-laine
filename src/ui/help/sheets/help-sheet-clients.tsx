import { useTranslation } from 'react-i18next';
import { Users, Plus, CircleDot, Search } from 'lucide-react-native';
import { Text } from '@/ui/primitives/text';
import { HelpSheet, HelpSection, HelpScreenshot } from '@/ui/help/help-sheet';

interface Props {
  visible: boolean;
  onClose: () => void;
}

export function HelpSheetClients({ visible, onClose }: Props) {
  const { t } = useTranslation();

  return (
    <HelpSheet visible={visible} onClose={onClose} title={t('help.clients.title')}>
      <HelpSection icon={Users} title={t('help.clients.what_is_title')}>
        <Text>{t('help.clients.what_is_body')}</Text>
      </HelpSection>

      <HelpScreenshot
        source={require('../../../../assets/help/clients-list-light.webp')}
        darkSource={require('../../../../assets/help/clients-list-dark.webp')}
        caption={t('help.clients.caption_list')}
      />

      <HelpSection icon={Plus} title={t('help.clients.how_to_add_title')}>
        <Text>{t('help.clients.how_to_add_body')}</Text>
      </HelpSection>

      <HelpSection icon={CircleDot} title={t('help.clients.statuses_title')}>
        <Text>{t('help.clients.statuses_body')}</Text>
      </HelpSection>

      <HelpSection icon={Search} title={t('help.clients.filter_title')}>
        <Text>{t('help.clients.filter_body')}</Text>
      </HelpSection>

      <HelpScreenshot
        source={require('../../../../assets/help/clients-filter-light.webp')}
        darkSource={require('../../../../assets/help/clients-filter-dark.webp')}
        caption={t('help.clients.caption_filter')}
      />
    </HelpSheet>
  );
}
