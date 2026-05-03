import { create } from 'zustand';

export interface OptimizedConfig {
  targetMinutes: number;
  commune: string | null;
}

interface TourDraftState {
  pickedClientIds: string[];
  optimizedConfig: OptimizedConfig | null;
  reset: () => void;
  toggle: (id: string) => void;
  setOrder: (ids: string[]) => void;
  setOptimizedConfig: (config: OptimizedConfig) => void;
}

export const useTourDraftStore = create<TourDraftState>((set) => ({
  pickedClientIds: [],
  optimizedConfig: null,
  reset: () => set({ pickedClientIds: [], optimizedConfig: null }),
  toggle: (id) =>
    set((s) => ({
      pickedClientIds: s.pickedClientIds.includes(id)
        ? s.pickedClientIds.filter((x) => x !== id)
        : [...s.pickedClientIds, id],
    })),
  setOrder: (pickedClientIds) => set({ pickedClientIds }),
  setOptimizedConfig: (optimizedConfig) => set({ optimizedConfig }),
}));
