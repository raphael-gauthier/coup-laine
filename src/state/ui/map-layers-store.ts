import { create } from 'zustand';

interface MapLayersState {
  showClientPins: boolean;
  showBasePin: boolean;
  showProximityCircle: boolean;
  setLayer: (key: keyof Omit<MapLayersState, 'setLayer'>, value: boolean) => void;
}

export const useMapLayersStore = create<MapLayersState>((set) => ({
  showClientPins: true,
  showBasePin: true,
  showProximityCircle: false,
  setLayer: (key, value) => set({ [key]: value }),
}));
