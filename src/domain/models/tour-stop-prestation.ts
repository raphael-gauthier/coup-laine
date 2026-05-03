import { z } from 'zod';
import { AnimalCountList } from './animal-count';

export const TourStopPrestation = z.object({
  prestationId: z.string(),
  animalCounts: AnimalCountList,
});

export type TourStopPrestation = z.infer<typeof TourStopPrestation>;
