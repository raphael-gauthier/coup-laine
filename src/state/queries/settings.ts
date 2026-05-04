import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { db } from '@/infra/db/client';
import { SettingsRepository } from '@/data/repositories/settings-repository';
import { useThemeStore, type ThemeMode } from '@/state/stores/theme-store';
import { DistanceMatrixSync } from '@/data/distance-matrix-sync';

const repo = new SettingsRepository(db);
const sync = new DistanceMatrixSync(db);

export const SETTINGS_KEYS_LIST = [
  'proximity_radius_km', 'tour_bracket_km', 'tour_fee_eur_per_bracket',
  'season_started_at',
  'marker_default_color', 'marker_waiting_color', 'marker_scheduled_color',
  'marker_done_color', 'marker_no_animals_color', 'marker_banned_color',
  'home_lat', 'home_lng', 'home_address',
  'user_professions',
] as const;
export type SettingKey = (typeof SETTINGS_KEYS_LIST)[number];

export const settingsKeys = {
  all: ['settings'] as const,
  byKey: (k: string) => [...settingsKeys.all, k] as const,
  base: () => [...settingsKeys.all, 'base'] as const,
  map: () => [...settingsKeys.all, 'map'] as const,
};

export function useAllSettings() {
  return useQuery({
    queryKey: settingsKeys.map(),
    queryFn: async () => {
      const out: Partial<Record<SettingKey, string>> = {};
      for (const key of SETTINGS_KEYS_LIST) {
        const v = await repo.get(key);
        if (v != null) out[key] = v;
      }
      return out;
    },
  });
}

export function useSetSetting() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async ({ key, value }: { key: SettingKey; value: string | null }) => {
      if (value == null) await repo.remove(key);
      else await repo.set(key, value);
    },
    onSuccess: () => {
      void qc.invalidateQueries({ queryKey: settingsKeys.all });
    },
  });
}

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
      await sync.markAllPending();
    },
    onSuccess: () => {
      void qc.invalidateQueries({ queryKey: settingsKeys.base() });
      void qc.invalidateQueries({ queryKey: ['clients'] });
    },
  });
}

export function useUserProfessions() {
  return useQuery<string[]>({
    queryKey: settingsKeys.byKey('user_professions'),
    queryFn: async () => {
      const v = await repo.get('user_professions');
      if (!v) return [];
      try {
        const parsed = JSON.parse(v);
        return Array.isArray(parsed) ? parsed.filter((x): x is string => typeof x === 'string') : [];
      } catch {
        return [];
      }
    },
  });
}

export function useSetUserProfessions() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (ids: string[]) => repo.set('user_professions', JSON.stringify(ids)),
    onSuccess: () => {
      void qc.invalidateQueries({ queryKey: settingsKeys.byKey('user_professions') });
    },
  });
}

export function useOnboardingComplete() {
  return useQuery({
    queryKey: [...settingsKeys.all, 'onboarding'],
    queryFn: async () => {
      const v = await repo.get('onboarding_complete');
      return v === 'true';
    },
  });
}

export function useMarkOnboardingComplete() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: () => repo.set('onboarding_complete', 'true'),
    onSuccess: () => {
      void qc.invalidateQueries({ queryKey: [...settingsKeys.all, 'onboarding'] });
    },
  });
}
