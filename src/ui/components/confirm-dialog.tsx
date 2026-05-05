import { useState } from 'react';
import { Alert, Modal, View } from 'react-native';
import { useTranslation } from 'react-i18next';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { Input } from '@/ui/primitives/input';
import { Button } from '@/ui/primitives/button';

interface ConfirmOptions {
  title: string;
  message?: string;
  confirmLabel: string;
  cancelLabel: string;
  destructive?: boolean;
}

export function confirm({ title, message, confirmLabel, cancelLabel, destructive }: ConfirmOptions): Promise<boolean> {
  return new Promise((resolve) => {
    Alert.alert(
      title,
      message,
      [
        { text: cancelLabel, style: 'cancel', onPress: () => resolve(false) },
        {
          text: confirmLabel,
          style: destructive ? 'destructive' : 'default',
          onPress: () => resolve(true),
        },
      ],
      { cancelable: true, onDismiss: () => resolve(false) }
    );
  });
}

interface ConfirmTypedDialogProps {
  visible: boolean;
  title: string;
  message?: string;
  /** The exact string the user must type to enable Confirm */
  typedConfirmation: string;
  confirmLabel: string;
  cancelLabel: string;
  onConfirm: () => void;
  onCancel: () => void;
}

export function ConfirmTypedDialog({
  visible,
  title,
  message,
  typedConfirmation,
  confirmLabel,
  cancelLabel,
  onConfirm,
  onCancel,
}: ConfirmTypedDialogProps) {
  const { t: _t } = useTranslation();
  const [typed, setTyped] = useState('');

  const canConfirm = typed === typedConfirmation;

  const handleCancel = () => {
    setTyped('');
    onCancel();
  };
  const handleConfirm = () => {
    if (!canConfirm) return;
    setTyped('');
    onConfirm();
  };

  return (
    <Modal
      visible={visible}
      animationType="fade"
      transparent
      presentationStyle="overFullScreen"
      onRequestClose={handleCancel}
    >
      <View style={{ flex: 1, backgroundColor: 'rgba(0,0,0,0.5)', alignItems: 'center', justifyContent: 'center', padding: 24 }}>
        <Surface className="rounded-3xl p-6 gap-4 w-full max-w-sm">
          <Text className="text-lg font-bold">{title}</Text>
          {message ? <Text variant="muted" className="text-sm">{message}</Text> : null}
          <View className="gap-1">
            <Text variant="muted" className="text-xs">
              {`Tape « ${typedConfirmation} » pour confirmer`}
            </Text>
            <Input
              value={typed}
              onChangeText={setTyped}
              placeholder={typedConfirmation}
              autoCapitalize="characters"
              accessibilityLabel={typedConfirmation}
            />
          </View>
          <View className="flex-row gap-2">
            <Button variant="secondary" className="flex-1" onPress={handleCancel}>
              {cancelLabel}
            </Button>
            <Button variant="danger" className="flex-1" onPress={handleConfirm} disabled={!canConfirm}>
              {confirmLabel}
            </Button>
          </View>
        </Surface>
      </View>
    </Modal>
  );
}
