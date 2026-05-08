import { create } from 'zustand';

/** null means "all". Otherwise, a Status row id. */
interface MapFiltersState {
  activeFilter: string | null;
  setFilter: (f: string | null) => void;
}

export const useMapFiltersStore = create<MapFiltersState>((set) => ({
  activeFilter: null,
  setFilter: (activeFilter) => set({ activeFilter }),
}));
