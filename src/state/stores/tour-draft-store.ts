import { create } from 'zustand';
import type { TourStopService } from '@/domain/models/tour-stop-service';

interface TourDraftState {
  pickedClientIds: string[];
  servicesByClient: Record<string, TourStopService[]>;
  reset: () => void;
  toggle: (id: string) => void;
  setOrder: (ids: string[]) => void;
  setStopServices: (clientId: string, services: TourStopService[]) => void;
  hydrateServices: (entries: { clientId: string; services: TourStopService[] }[]) => void;
}

export const useTourDraftStore = create<TourDraftState>((set) => ({
  pickedClientIds: [],
  servicesByClient: {},
  reset: () => set({ pickedClientIds: [], servicesByClient: {} }),
  toggle: (id) =>
    set((s) => {
      const isPicked = s.pickedClientIds.includes(id);
      if (isPicked) {
        const { [id]: _drop, ...rest } = s.servicesByClient;
        return {
          pickedClientIds: s.pickedClientIds.filter((x) => x !== id),
          servicesByClient: rest,
        };
      }
      return { pickedClientIds: [...s.pickedClientIds, id] };
    }),
  setOrder: (pickedClientIds) => set({ pickedClientIds }),
  setStopServices: (clientId, services) =>
    set((s) => ({ servicesByClient: { ...s.servicesByClient, [clientId]: services } })),
  hydrateServices: (entries) =>
    set(() => ({
      servicesByClient: Object.fromEntries(entries.map((e) => [e.clientId, e.services])),
    })),
}));
