import { useTranslation } from 'react-i18next';
import { Map, Filter, MapPin, Hash } from 'lucide-react-native';
import { Text } from '@/ui/primitives/text';
import { HelpSheet, HelpSection } from '@/ui/help/help-sheet';

interface Props {
  visible: boolean;
  onClose: () => void;
}

export function HelpSheetMap({ visible, onClose }: Props) {
  const { t } = useTranslation();

  return (
    <HelpSheet visible={visible} onClose={onClose} title={t('help.map.title')}>
      <HelpSection icon={Map} title={t('help.map.what_is_title')}>
        <Text>{t('help.map.what_is_body')}</Text>
      </HelpSection>

      <HelpSection icon={Filter} title={t('help.map.filter_title')}>
        <Text>{t('help.map.filter_body')}</Text>
      </HelpSection>

      <HelpSection icon={MapPin} title={t('help.map.popup_title')}>
        <Text>{t('help.map.popup_body')}</Text>
      </HelpSection>

      <HelpSection icon={Hash} title={t('help.map.kpis_title')}>
        <Text>{t('help.map.kpis_body')}</Text>
      </HelpSection>
    </HelpSheet>
  );
}
