// src/ui/help/help-sheet.tsx
import type { ReactNode } from 'react';
import { Modal, View, ScrollView, TouchableOpacity } from 'react-native';
import { X, type LucideIcon } from 'lucide-react-native';
import { useTranslation } from 'react-i18next';
import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { Button } from '@/ui/primitives/button';
import { PressScale } from '@/ui/motion/press-scale';

interface HelpSheetProps {
  visible: boolean;
  onClose: () => void;
  title: string;
  children: ReactNode;
}

export function HelpSheet({ visible, onClose, title, children }: HelpSheetProps) {
  const { t } = useTranslation();

  return (
    <Modal
      visible={visible}
      animationType="slide"
      transparent
      presentationStyle="overFullScreen"
      onRequestClose={onClose}
    >
      <TouchableOpacity
        style={{ flex: 1, backgroundColor: 'rgba(0,0,0,0.4)' }}
        onPress={onClose}
        activeOpacity={1}
      />
      <Surface className="rounded-t-3xl px-4 pb-8 pt-4" style={{ maxHeight: '85%' }}>
        <View className="flex-row items-center justify-between mb-4">
          <Text className="text-xl font-bold flex-1" numberOfLines={2}>
            {title}
          </Text>
          <PressScale onPress={onClose} accessibilityLabel={t('common.close')}>
            <X size={22} color="#5C4E40" />
          </PressScale>
        </View>

        <ScrollView contentContainerStyle={{ gap: 16, paddingBottom: 16 }}>
          {children}
        </ScrollView>

        <Button onPress={onClose} className="mt-2">
          {t('help.dismiss_cta')}
        </Button>
      </Surface>
    </Modal>
  );
}

interface HelpSectionProps {
  icon: LucideIcon;
  title: string;
  children: ReactNode;
}

export function HelpSection({ icon: Icon, title, children }: HelpSectionProps) {
  return (
    <View className="flex-row gap-3">
      <View className="pt-1">
        <Icon size={20} color="#5C4E40" />
      </View>
      <View className="flex-1 gap-1">
        <Text className="font-semibold">{title}</Text>
        {children}
      </View>
    </View>
  );
}

interface HelpPreviewProps {
  caption?: string;
  children: ReactNode;
}

export function HelpPreview({ caption, children }: HelpPreviewProps) {
  return (
    <Surface variant="muted" className="rounded-2xl p-3 gap-2 items-stretch">
      <View className="items-center">{children}</View>
      {caption ? (
        <Text variant="muted" className="text-xs text-center">
          {caption}
        </Text>
      ) : null}
    </Surface>
  );
}
