import { create } from 'zustand';

interface ClientFiltersState {
  enabledStatusIds: Set<string>;
  /** Ids the store has been told about. Lets reconcileWith distinguish a brand-new id (auto-enable) from one the user explicitly unchecked (leave alone). */
  knownStatusIds: Set<string>;
  /** When true, no filter has been applied yet — UI should show all clients regardless of the set. */
  uninitialized: boolean;
  initWithAll: (ids: string[]) => void;
  setAll: (ids: string[]) => void;
  setNone: () => void;
  toggle: (id: string) => void;
  /** Auto-enable any id that is in `ids` but not yet in knownStatusIds. Preserves existing checked/unchecked state for known ids. No-op while uninitialized. */
  reconcileWith: (ids: string[]) => void;
}

export const useClientFiltersStore = create<ClientFiltersState>((set) => ({
  enabledStatusIds: new Set(),
  knownStatusIds: new Set(),
  uninitialized: true,
  initWithAll: (ids) =>
    set({ enabledStatusIds: new Set(ids), knownStatusIds: new Set(ids), uninitialized: false }),
  setAll: (ids) =>
    set({ enabledStatusIds: new Set(ids), knownStatusIds: new Set(ids), uninitialized: false }),
  setNone: () =>
    set((state) => ({ enabledStatusIds: new Set(), knownStatusIds: state.knownStatusIds, uninitialized: false })),
  toggle: (id) =>
    set((state) => {
      const enabled = new Set(state.enabledStatusIds);
      if (enabled.has(id)) enabled.delete(id);
      else enabled.add(id);
      const known = state.knownStatusIds.has(id) ? state.knownStatusIds : new Set([...state.knownStatusIds, id]);
      return { enabledStatusIds: enabled, knownStatusIds: known, uninitialized: false };
    }),
  reconcileWith: (ids) =>
    set((state) => {
      if (state.uninitialized) return state;
      const newIds = ids.filter((id) => !state.knownStatusIds.has(id));
      if (newIds.length === 0) return state;
      const enabled = new Set(state.enabledStatusIds);
      const known = new Set(state.knownStatusIds);
      for (const id of newIds) {
        enabled.add(id);
        known.add(id);
      }
      return { enabledStatusIds: enabled, knownStatusIds: known, uninitialized: false };
    }),
}));
