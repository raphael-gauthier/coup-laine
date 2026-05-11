import { useTranslation } from 'react-i18next';
import { ClipboardCheck, Minus, PlusCircle, Wallet } from 'lucide-react-native';
import { Text } from '@/ui/primitives/text';
import { HelpSheet, HelpSection, HelpPreview } from '@/ui/help/help-sheet';
import { CompletionRowDemo } from '@/ui/help/previews/completion-row-demo';

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

      <HelpPreview caption={t('help.completion.caption_main')}>
        <CompletionRowDemo />
      </HelpPreview>

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
