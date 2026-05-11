import { useTranslation } from 'react-i18next';
import { MapPin, CalendarPlus, CheckCircle2 } from 'lucide-react-native';
import { Text } from '@/ui/primitives/text';
import { HelpSheet, HelpSection, HelpPreview } from '@/ui/help/help-sheet';
import { TourCardDemo } from '@/ui/help/previews/tour-card-demo';
import { TourPlanningDemo } from '@/ui/help/previews/tour-planning-demo';

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

      <HelpPreview caption={t('help.tours.caption_list')}>
        <TourCardDemo />
      </HelpPreview>

      <HelpSection icon={CalendarPlus} title={t('help.tours.how_to_create_title')}>
        <Text>{t('help.tours.how_to_create_body')}</Text>
      </HelpSection>

      <HelpPreview caption={t('help.tours.caption_planning')}>
        <TourPlanningDemo />
      </HelpPreview>

      <HelpSection icon={CheckCircle2} title={t('help.tours.statuses_title')}>
        <Text>{t('help.tours.statuses_body')}</Text>
      </HelpSection>
    </HelpSheet>
  );
}
