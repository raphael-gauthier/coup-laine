// src/ui/help/coach-mark.tsx
import { useEffect, useRef, useState, type RefObject } from 'react';
import { Modal, View, Dimensions, type View as RNView } from 'react-native';
import Animated, { FadeIn, FadeOut } from 'react-native-reanimated';
import { X } from 'lucide-react-native';
import { useTranslation } from 'react-i18next';
import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { PressScale } from '@/ui/motion/press-scale';
import { haptics } from '@/ui/motion/haptics';

interface Props {
  visible: boolean;
  onDismiss: () => void;
  /** Ref to the View we want to point at. Position is measured on layout. */
  anchorRef: RefObject<RNView | null>;
  arrowDirection?: 'up' | 'down';
  title?: string;
  body: string;
}

interface AnchorBox {
  x: number;
  y: number;
  width: number;
  height: number;
}

export function CoachMark({
  visible,
  onDismiss,
  anchorRef,
  arrowDirection = 'up',
  title,
  body,
}: Props) {
  const [box, setBox] = useState<AnchorBox | null>(null);
  const measureScheduled = useRef(false);
  const { t } = useTranslation();
  const screen = Dimensions.get('window');

  // Measure on visibility flip + on next frame (anchors may not have laid out yet).
  useEffect(() => {
    if (!visible) {
      setBox(null);
      return;
    }
    if (measureScheduled.current) return;
    measureScheduled.current = true;
    const raf = requestAnimationFrame(() => {
      measureScheduled.current = false;
      const node = anchorRef.current;
      if (!node) return;
      node.measureInWindow((x, y, width, height) => {
        if (Number.isFinite(x) && Number.isFinite(y) && width > 0 && height > 0) {
          setBox({ x, y, width, height });
        }
      });
    });
    return () => cancelAnimationFrame(raf);
  }, [visible, anchorRef]);

  // Haptic on first appearance.
  useEffect(() => {
    if (visible && box) void haptics.lightTap();
  }, [visible, box]);

  const handleDismiss = () => {
    void haptics.selection();
    onDismiss();
  };

  if (!visible || !box) return null;

  // Bubble width (capped) and horizontal centering relative to the anchor.
  const BUBBLE_WIDTH = Math.min(280, screen.width - 32);
  const anchorCenterX = box.x + box.width / 2;
  let left = anchorCenterX - BUBBLE_WIDTH / 2;
  left = Math.max(16, Math.min(left, screen.width - BUBBLE_WIDTH - 16));

  // Position bubble above (arrow up means bubble is BELOW the anchor) or below.
  // arrowDirection 'up' = bubble below anchor with arrow pointing up to anchor.
  const top = arrowDirection === 'up'
    ? box.y + box.height + 12
    : box.y - 12 - 120; // estimate bubble height ~120px when above

  return (
    <Modal
      visible={visible}
      transparent
      animationType="none"
      presentationStyle="overFullScreen"
      onRequestClose={handleDismiss}
    >
      {/* Tap-anywhere backdrop, fully transparent (non-blocking visually). */}
      <PressScale
        onPress={handleDismiss}
        accessibilityLabel={t('coachmark.dismiss_label')}
        className="flex-1"
      >
        <View style={{ flex: 1 }}>
          <Animated.View
            entering={FadeIn.duration(200)}
            exiting={FadeOut.duration(150)}
            style={{
              position: 'absolute',
              left,
              top,
              width: BUBBLE_WIDTH,
            }}
          >
            <Surface
              className="rounded-2xl px-4 py-3 gap-2"
              style={{
                shadowColor: '#000',
                shadowOpacity: 0.2,
                shadowRadius: 12,
                shadowOffset: { width: 0, height: 4 },
                elevation: 8,
              }}
            >
              <View className="flex-row items-start justify-between gap-3">
                <View className="flex-1 gap-1">
                  {title ? <Text className="font-semibold">{title}</Text> : null}
                  <Text className="text-sm">{body}</Text>
                </View>
                <X size={18} color="#5C4E40" />
              </View>
            </Surface>
          </Animated.View>
        </View>
      </PressScale>
    </Modal>
  );
}
