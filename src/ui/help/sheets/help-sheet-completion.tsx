import { useTranslation } from 'react-i18next';
import { ClipboardCheck, Minus, PlusCircle, Wallet } from 'lucide-react-native';
import { Text } from '@/ui/primitives/text';
import { HelpSheet, HelpSection, HelpScreenshot } from '@/ui/help/help-sheet';

interface Props {
  visible: boolean;
  onClose: () => void;
}

export function HelpSheetCompletion({ visible, onClose }: Props) {
  const { t } = useTranslation();

  return (
    <HelpSheet visible={visible} onClose={onClose} title={t('help.completion.title')}>
      <HelpSection icon={ClipboardCheck} title={t('help.completion.what_is_title')}>
        <Text>{t('help.completion.what_is_body')}</Text>
      </HelpSection>

      <HelpScreenshot
        source={require('../../../../assets/help/completion-main-light.webp')}
        darkSource={require('../../../../assets/help/completion-main-dark.webp')}
        caption={t('help.completion.caption_main')}
      />

      <HelpSection icon={Minus} title={t('help.completion.adjust_title')}>
        <Text>{t('help.completion.adjust_body')}</Text>
      </HelpSection>

      <HelpSection icon={PlusCircle} title={t('help.completion.extra_title')}>
        <Text>{t('help.completion.extra_body')}</Text>
      </HelpSection>

      <HelpSection icon={Wallet} title={t('help.completion.payment_title')}>
        <Text>{t('help.completion.payment_body')}</Text>
      </HelpSection>
    </HelpSheet>
  );
}
