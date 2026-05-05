import { useEffect } from 'react';
import { View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import Animated, { FadeInUp, FadeOutUp, LinearTransition } from 'react-native-reanimated';
import { AlertCircle, CheckCircle2, X } from 'lucide-react-native';
import { create } from 'zustand';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { PressScale } from '@/ui/motion/press-scale';
import { motion } from '@/ui/motion/motion-tokens';
import { newId } from '@/lib/id';
import { useOnContrastColor } from '@/ui/theme/colors';

const AUTO_DISMISS_MS = 4000;

export type ToastVariant = 'error' | 'success';

export interface ToastEntry {
  id: string;
  title: string;
  message?: string;
  variant: ToastVariant;
}

interface ToastState {
  entries: ToastEntry[];
  push: (entry: Omit<ToastEntry, 'id'>) => string;
  dismiss: (id: string) => void;
}

export const useToastStore = create<ToastState>((set) => ({
  entries: [],
  push: (entry) => {
    const id = newId();
    set((s) => ({ entries: [...s.entries, { ...entry, id }] }));
    return id;
  },
  dismiss: (id) =>
    set((s) => ({ entries: s.entries.filter((e) => e.id !== id) })),
}));

export function ToastContainer() {
  const entries = useToastStore((s) => s.entries);
  const insets = useSafeAreaInsets();

  return (
    <View
      pointerEvents="box-none"
      style={{
        position: 'absolute',
        top: insets.top + 8,
        left: 16,
        right: 16,
      }}
    >
      {entries.map((entry) => (
        <ToastCard key={entry.id} entry={entry} />
      ))}
    </View>
  );
}

function ToastCard({ entry }: { entry: ToastEntry }) {
  const dismiss = useToastStore((s) => s.dismiss);
  const onContrast = useOnContrastColor();

  useEffect(() => {
    const handle = setTimeout(() => dismiss(entry.id), AUTO_DISMISS_MS);
    return () => clearTimeout(handle);
  }, [entry.id, dismiss]);

  return (
    <Animated.View
      entering={FadeInUp.duration(motion.duration.fast)}
      exiting={FadeOutUp.duration(motion.duration.fast)}
      layout={LinearTransition.duration(motion.duration.normal)}
      style={{ marginBottom: 8 }}
    >
      <PressScale onPress={() => dismiss(entry.id)}>
        <Surface
          variant={entry.variant === 'success' ? 'success' : 'danger'}
          className="flex-row items-start gap-2 rounded-2xl px-3 py-3"
          style={{
            shadowColor: '#000',
            shadowOpacity: 0.2,
            shadowRadius: 6,
            shadowOffset: { width: 0, height: 2 },
            elevation: 6,
          }}
        >
          {entry.variant === 'success' ? (
            <CheckCircle2 size={18} color={onContrast} style={{ marginTop: 1 }} />
          ) : (
            <AlertCircle size={18} color={onContrast} style={{ marginTop: 1 }} />
          )}
          <View className="flex-1">
            <Text variant={entry.variant === 'success' ? 'onSuccess' : 'onDanger'} className="text-sm font-semibold">
              {entry.title}
            </Text>
            {entry.message ? (
              <Text variant={entry.variant === 'success' ? 'onSuccess' : 'onDanger'} className="text-sm opacity-90 mt-0.5">
                {entry.message}
              </Text>
            ) : null}
          </View>
          <X size={16} color={onContrast} style={{ marginTop: 2, opacity: 0.8 }} />
        </Surface>
      </PressScale>
    </Animated.View>
  );
}
