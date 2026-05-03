import { create } from 'zustand';
import type { ClientStatus } from '@/domain/use-cases/client-status';

const ALL_STATUSES: ClientStatus[] = ['default', 'waiting', 'scheduled', 'done', 'noAnimals', 'banned'];

interface ClientFiltersState {
  enabledStatuses: Set<ClientStatus>;
  setAll: () => void;
  setNone: () => void;
  toggle: (status: ClientStatus) => void;
  setStatuses: (statuses: ClientStatus[]) => void;
}

export const useClientFiltersStore = create<ClientFiltersState>((set) => ({
  enabledStatuses: new Set(ALL_STATUSES),
  setAll: () => set({ enabledStatuses: new Set(ALL_STATUSES) }),
  setNone: () => set({ enabledStatuses: new Set() }),
  toggle: (status) =>
    set((state) => {
      const next = new Set(state.enabledStatuses);
      if (next.has(status)) next.delete(status);
      else next.add(status);
      return { enabledStatuses: next };
    }),
  setStatuses: (statuses) => set({ enabledStatuses: new Set(statuses) }),
}));
