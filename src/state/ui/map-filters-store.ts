import { create } from 'zustand';
import type { ClientStatus } from '@/domain/use-cases/client-status';

export type MapFilter = ClientStatus | 'all';

interface MapFiltersState {
  activeFilter: MapFilter;
  setFilter: (f: MapFilter) => void;
}

export const useMapFiltersStore = create<MapFiltersState>((set) => ({
  activeFilter: 'all',
  setFilter: (activeFilter) => set({ activeFilter }),
}));
