import { useTranslation } from 'react-i18next';
import { MapPin, Pencil, ClipboardCheck, Trash2 } from 'lucide-react-native';
import { Text } from '@/ui/primitives/text';
import { HelpSheet, HelpSection, HelpPreview } from '@/ui/help/help-sheet';
import { TourStopListDemo } from '@/ui/help/previews/tour-stop-list-demo';

interface Props {
  visible: boolean;
  onClose: () => void;
}

export function HelpSheetTourDetail({ visible, onClose }: Props) {
  const { t } = useTranslation();

  return (
    <HelpSheet visible={visible} onClose={onClose} title={t('help.tour_detail.title')}>
      <HelpSection icon={MapPin} title={t('help.tour_detail.what_is_title')}>
        <Text>{t('help.tour_detail.what_is_body')}</Text>
      </HelpSection>

      <HelpPreview caption={t('help.tour_detail.caption_main')}>
        <TourStopListDemo />
      </HelpPreview>

      <HelpSection icon={Pencil} title={t('help.tour_detail.edit_title')}>
        <Text>{t('help.tour_detail.edit_body')}</Text>
      </HelpSection>

      <HelpSection icon={ClipboardCheck} title={t('help.tour_detail.complete_title')}>
        <Text>{t('help.tour_detail.complete_body')}</Text>
      </HelpSection>

      <HelpSection icon={Trash2} title={t('help.tour_detail.delete_title')}>
        <Text>{t('help.tour_detail.delete_body')}</Text>
      </HelpSection>
    </HelpSheet>
  );
}
