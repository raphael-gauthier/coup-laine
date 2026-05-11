import { useTranslation } from 'react-i18next';
import { MapPin, CalendarPlus, CheckCircle2 } from 'lucide-react-native';
import { Text } from '@/ui/primitives/text';
import { HelpSheet, HelpSection, HelpScreenshot } from '@/ui/help/help-sheet';

interface Props {
  visible: boolean;
  onClose: () => void;
}

export function HelpSheetTours({ visible, onClose }: Props) {
  const { t } = useTranslation();

  return (
    <HelpSheet visible={visible} onClose={onClose} title={t('help.tours.title')}>
      <HelpSection icon={MapPin} title={t('help.tours.what_is_title')}>
        <Text>{t('help.tours.what_is_body')}</Text>
      </HelpSection>

      <HelpScreenshot
        source={require('../../../../assets/help/tours-list-light.webp')}
        darkSource={require('../../../../assets/help/tours-list-dark.webp')}
        caption={t('help.tours.caption_list')}
      />

      <HelpSection icon={CalendarPlus} title={t('help.tours.how_to_create_title')}>
        <Text>{t('help.tours.how_to_create_body')}</Text>
      </HelpSection>

      <HelpScreenshot
        source={require('../../../../assets/help/tours-planning-light.webp')}
        darkSource={require('../../../../assets/help/tours-planning-dark.webp')}
        caption={t('help.tours.caption_planning')}
      />

      <HelpSection icon={CheckCircle2} title={t('help.tours.statuses_title')}>
        <Text>{t('help.tours.statuses_body')}</Text>
      </HelpSection>
    </HelpSheet>
  );
}
