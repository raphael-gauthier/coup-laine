import { create } from 'zustand';

interface TourDraftState {
  pickedClientIds: string[];
  reset: () => void;
  toggle: (id: string) => void;
  setOrder: (ids: string[]) => void;
}

export const useTourDraftStore = create<TourDraftState>((set) => ({
  pickedClientIds: [],
  reset: () => set({ pickedClientIds: [] }),
  toggle: (id) =>
    set((s) => ({
      pickedClientIds: s.pickedClientIds.includes(id)
        ? s.pickedClientIds.filter((x) => x !== id)
        : [...s.pickedClientIds, id],
    })),
  setOrder: (pickedClientIds) => set({ pickedClientIds }),
}));
