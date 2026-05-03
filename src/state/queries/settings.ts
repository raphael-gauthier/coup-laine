import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { db } from '@/infra/db/client';
import { SettingsRepository } from '@/data/repositories/settings-repository';
import { useThemeStore, type ThemeMode } from '@/state/stores/theme-store';

const repo = new SettingsRepository(db);

export const settingsKeys = {
  all: ['settings'] as const,
  byKey: (k: string) => [...settingsKeys.all, k] as const,
  base: () => [...settingsKeys.all, 'base'] as const,
};

export function useThemeMode() {
  return useThemeStore((s) => s.mode);
}

export function useSetThemeMode() {
  const setLocal = useThemeStore((s) => s.setMode);
  return useMutation({
    mutationFn: async (mode: ThemeMode) => {
      await repo.set('theme_mode', mode);
      setLocal(mode);
    },
  });
}

export interface BaseAddress {
  label: string;
  city: string | null;
  postcode: string | null;
  lat: number;
  lon: number;
}

export function useBaseAddress() {
  return useQuery<BaseAddress | null>({
    queryKey: settingsKeys.base(),
    queryFn: async () => {
      const all = await repo.getAll();
      const label = all['base_address_label'];
      const lat = all['base_lat'];
      const lon = all['base_lng'];
      if (!label || !lat || !lon) return null;
      return {
        label,
        city: all['base_address_city'] ?? null,
        postcode: all['base_address_postcode'] ?? null,
        lat: parseFloat(lat),
        lon: parseFloat(lon),
      };
    },
  });
}

export function useSetBaseAddress() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (b: BaseAddress) => {
      await repo.set('base_address_label', b.label);
      await repo.set('base_address_city', b.city ?? '');
      await repo.set('base_address_postcode', b.postcode ?? '');
      await repo.set('base_lat', String(b.lat));
      await repo.set('base_lng', String(b.lon));
    },
    onSuccess: () => {
      void qc.invalidateQueries({ queryKey: settingsKeys.base() });
    },
  });
}
