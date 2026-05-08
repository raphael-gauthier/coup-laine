import { create } from 'zustand';

interface ClientFiltersState {
  enabledStatusIds: Set<string>;
  /** When true, no filter has been applied yet — UI should show all clients regardless of the set. */
  uninitialized: boolean;
  initWithAll: (ids: string[]) => void;
  setAll: (ids: string[]) => void;
  setNone: () => void;
  toggle: (id: string) => void;
}

export const useClientFiltersStore = create<ClientFiltersState>((set) => ({
  enabledStatusIds: new Set(),
  uninitialized: true,
  initWithAll: (ids) => set({ enabledStatusIds: new Set(ids), uninitialized: false }),
  setAll: (ids) => set({ enabledStatusIds: new Set(ids), uninitialized: false }),
  setNone: () => set({ enabledStatusIds: new Set(), uninitialized: false }),
  toggle: (id) =>
    set((state) => {
      const next = new Set(state.enabledStatusIds);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return { enabledStatusIds: next, uninitialized: false };
    }),
}));
