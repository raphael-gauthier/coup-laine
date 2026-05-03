import { create } from 'zustand';

interface ProximityState {
  pivotId: string | null;
  radiusKm: number;
  view: 'list' | 'map';
  setPivotId: (id: string | null) => void;
  setRadiusKm: (km: number) => void;
  setView: (v: 'list' | 'map') => void;
}

export const useProximityStore = create<ProximityState>((set) => ({
  pivotId: null,
  radiusKm: 20,
  view: 'list',
  setPivotId: (pivotId) => set({ pivotId }),
  setRadiusKm: (radiusKm) => set({ radiusKm }),
  setView: (view) => set({ view }),
}));
