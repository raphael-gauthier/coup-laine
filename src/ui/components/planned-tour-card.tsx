import { View } from 'react-native';
import { useRouter } from 'expo-router';
import { useTranslation } from 'react-i18next';
import { format, parseISO } from 'date-fns';
import { fr } from 'date-fns/locale';
import { Calendar, ChevronRight } from 'lucide-react-native';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { PressScale } from '@/ui/motion/press-scale';
import { useNextPlannedTourForClient } from '@/state/queries/tours';
import { haptics } from '@/ui/motion/haptics';

interface Props {
  clientId: string;
}

export function PlannedTourCard({ clientId }: Props) {
  const { t } = useTranslation();
  const router = useRouter();
  const { data: result } = useNextPlannedTourForClient(clientId);

  if (!result) return null;
  const { tour } = result;
  const dateStr = format(parseISO(`${tour.scheduledDate}T${tour.departureTime}:00`), 'dd/MM/yyyy', { locale: fr });

  return (
    <PressScale
      onPress={() => {
        void haptics.selection();
        router.push(`/(tabs)/tours/${tour.id}`);
      }}
    >
      <Surface variant="muted" className="flex-row items-center rounded-2xl px-4 py-3 gap-3">
        <Calendar size={18} color="#C88226" />
        <View className="flex-1">
          <Text className="text-sm font-medium">
            {t('clients.planned_tour_label', { date: dateStr })}
          </Text>
        </View>
        <ChevronRight size={16} color="#5C4E40" />
      </Surface>
    </PressScale>
  );
}
