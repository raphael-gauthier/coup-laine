import { useState, useMemo } from 'react';
import { View, Modal, TouchableOpacity } from 'react-native';
import { useTranslation } from 'react-i18next';
import { Plus } from 'lucide-react-native';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { Button } from '@/ui/primitives/button';
import { AnimalCountsEditor } from '@/ui/components/animal-counts-editor';
import type { Client } from '@/domain/models/client';
import { useUpsertClient } from '@/state/queries/clients';
import { useAnimalCategories } from '@/state/queries/species';
import { haptics } from '@/ui/motion/haptics';
import { mutationErrorToast } from '@/ui/components/error-toast';
import { useForegroundColor } from '@/ui/theme/colors';

// Simple species emoji mapping by category label keywords
function emojiForCategory(label: string): string {
  const l = label.toLowerCase();
  if (l.includes('brebis') || l.includes('mouton') || l.includes('agneau')) return '🐑';
  if (l.includes('chèvre') || l.includes('chevre') || l.includes('cabri')) return '🐐';
  if (l.includes('bovin') || l.includes('vache') || l.includes('bœuf')) return '🐄';
  if (l.includes('volaille') || l.includes('poule') || l.includes('poulet')) return '🐔';
  return '🐾';
}

interface Props {
  client: Client;
}

export function ClientAnimalsSection({ client }: Props) {
  const { t } = useTranslation();
  const [editing, setEditing] = useState(false);
  const { data: categories = [] } = useAnimalCategories();
  const upsertClient = useUpsertClient();
  const fg = useForegroundColor();

  const categoriesById = useMemo(
    () => new Map(categories.map((c) => [c.id, c])),
    [categories]
  );

  return (
    <>
      <Surface variant="muted" className="rounded-2xl px-4 py-3 gap-3">
        <View className="flex-row items-center justify-between">
          <Text className="font-semibold">{t('clients.animals_section_title')}</Text>
          <Button
            size="sm"
            variant="ghost"
            onPress={() => setEditing(true)}
            accessibilityLabel={t('common.edit')}
          >
            <Plus size={14} color={fg} />
            <Text className="font-semibold text-sm">{t('common.edit')}</Text>
          </Button>
        </View>

        {client.animalCounts.length === 0 ? (
          <Text variant="muted" className="text-sm">{t('clients.no_animals')}</Text>
        ) : (
          client.animalCounts.map((ac) => {
            const cat = categoriesById.get(ac.categoryId);
            const label = cat?.label ?? ac.categoryId;
            return (
              <View key={ac.categoryId} className="flex-row items-center justify-between">
                <View className="flex-row items-center gap-2">
                  <Text>{emojiForCategory(label)}</Text>
                  <Text className="text-sm">{label}</Text>
                </View>
                <Text className="font-semibold">{ac.count}</Text>
              </View>
            );
          })
        )}
      </Surface>

      <Modal visible={editing} animationType="slide" transparent presentationStyle="overFullScreen">
        <TouchableOpacity
          style={{ flex: 1, backgroundColor: 'rgba(0,0,0,0.4)' }}
          onPress={() => setEditing(false)}
          activeOpacity={1}
        />
        <Surface className="rounded-t-3xl px-4 pb-8 pt-4">
          <Text className="text-lg font-semibold mb-4">{t('clients.animal_counts')}</Text>
          <AnimalCountsEditor
            value={client.animalCounts}
            onChange={(counts) => {
              upsertClient.mutate(
                {
                  id: client.id,
                  displayName: client.displayName,
                  phones: client.phones,
                  addressLabel: client.addressLabel,
                  addressCity: client.addressCity,
                  addressPostcode: client.addressPostcode,
                  latitude: client.latitude,
                  longitude: client.longitude,
                  isWaiting: client.isWaiting,
                  animalCounts: counts,
                },
                {
                  onSuccess: () => {
                    void haptics.success();
                    setEditing(false);
                  },
                  onError: (err) => {
                    mutationErrorToast(t('clients.save_failed_title'), err);
                  },
                }
              );
            }}
          />
          <Button variant="secondary" className="mt-3" onPress={() => setEditing(false)}>
            {t('common.cancel')}
          </Button>
        </Surface>
      </Modal>
    </>
  );
}
