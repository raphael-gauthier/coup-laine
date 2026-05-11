// src/ui/help/help-button.tsx
import { View } from 'react-native';
import { HelpCircle } from 'lucide-react-native';
import { useTranslation } from 'react-i18next';
import { PressScale } from '@/ui/motion/press-scale';
import { haptics } from '@/ui/motion/haptics';
import { usePrimaryColor, useMutedForegroundColor } from '@/ui/theme/colors';
import { useHelpSheet } from '@/ui/help/hooks';
import type { TutorialKey } from '@/domain/tutorial/keys';

interface Props {
  tutorialKey: TutorialKey;
  onPress: () => void;
}

/**
 * The `?` icon to drop into a screen's header. Renders an unseen-dot in
 * the top-right corner if the linked help sheet has never been opened.
 *
 * `onPress` is wired by the parent to actually open the sheet (the parent
 * owns the sheet's mounted instance + open/close state via useHelpSheet).
 */
export function HelpButton({ tutorialKey, onPress }: Props) {
  const { t } = useTranslation();
  const muted = useMutedForegroundColor();
  const primary = usePrimaryColor();
  const { hasBeenSeen } = useHelpSheet(tutorialKey);

  const handlePress = () => {
    void haptics.lightTap();
    onPress();
  };

  return (
    <PressScale
      onPress={handlePress}
      accessibilityLabel={t('help.button_label')}
      accessibilityRole="button"
      accessibilityHint={t('help.button_hint')}
      className="p-2"
    >
      <View>
        <HelpCircle size={22} color={muted} />
        {!hasBeenSeen ? (
          <View
            style={{
              position: 'absolute',
              top: -2,
              right: -2,
              width: 8,
              height: 8,
              borderRadius: 4,
              backgroundColor: primary,
            }}
          />
        ) : null}
      </View>
    </PressScale>
  );
}
