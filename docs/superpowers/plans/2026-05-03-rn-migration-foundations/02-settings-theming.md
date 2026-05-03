# Phase 2 — Settings + theming

**Goal:** Functional Settings tab with: (a) theme switch (Système / Clair / Sombre) persisted in DB, (b) Domicile/Base form with BAN address autocomplete that saves the user's home base. Theme persistence is wired through the existing ThemeProvider so the app respects the saved preference on cold start.

**Verification at end of phase:**
- Settings tab opens with two clickable rows: "Apparence" and "Domicile / Base"
- Tapping "Apparence" opens a screen with three radio options; selecting one applies the theme immediately AND persists across app reload
- Tapping "Domicile / Base" opens a form; typing in the address field shows BAN suggestions; selecting one stores the base; on reload, the form is pre-filled
- All interactions feel responsive (PressScale on rows, smooth transitions, haptic selection feedback on radio)

---

## Task 2.1: BAN geocoding service

**Files:**
- Create: `src/infra/services/ban-geocoding.ts`
- Create: `tests/infra/ban-geocoding.test.ts`
- Create: `tests/infra/_fixtures/ban-search.json`

> The BAN API is `https://api-adresse.data.gouv.fr/search?q=...`. We mock with msw. Public, no auth, no key.

- [ ] **Step 1: Install msw**

```powershell
pnpm add -D msw
```

- [ ] **Step 2: Create the BAN response fixture**

```json
// tests/infra/_fixtures/ban-search.json
{
  "type": "FeatureCollection",
  "version": "draft",
  "features": [
    {
      "type": "Feature",
      "geometry": { "type": "Point", "coordinates": [-4.0975, 48.0019] },
      "properties": {
        "label": "1 Rue de la Tonte 29000 Quimper",
        "score": 0.9,
        "id": "29232_1234",
        "type": "housenumber",
        "name": "1 Rue de la Tonte",
        "postcode": "29000",
        "citycode": "29232",
        "city": "Quimper",
        "context": "29, Finistère, Bretagne",
        "importance": 0.5,
        "street": "Rue de la Tonte"
      }
    },
    {
      "type": "Feature",
      "geometry": { "type": "Point", "coordinates": [-4.4861, 48.3905] },
      "properties": {
        "label": "10 Rue des Moutons 29200 Brest",
        "postcode": "29200",
        "citycode": "29019",
        "city": "Brest",
        "context": "29, Finistère, Bretagne"
      }
    }
  ],
  "attribution": "BAN",
  "licence": "ETALAB-2.0",
  "query": "tonte",
  "limit": 5
}
```

- [ ] **Step 3: Write the failing test**

```ts
// tests/infra/ban-geocoding.test.ts
import { setupServer } from 'msw/node';
import { http, HttpResponse } from 'msw';
import { searchAddresses } from '@/infra/services/ban-geocoding';
import banFixture from './_fixtures/ban-search.json';

const server = setupServer(
  http.get('https://api-adresse.data.gouv.fr/search', () => HttpResponse.json(banFixture))
);

beforeAll(() => server.listen());
afterEach(() => server.resetHandlers());
afterAll(() => server.close());

describe('searchAddresses', () => {
  it('returns parsed BAN results', async () => {
    const r = await searchAddresses('tonte');
    expect(r).toHaveLength(2);
    expect(r[0]).toMatchObject({
      label: '1 Rue de la Tonte 29000 Quimper',
      city: 'Quimper',
      postcode: '29000',
      lat: 48.0019,
      lon: -4.0975,
    });
  });

  it('returns empty array for empty query', async () => {
    expect(await searchAddresses('')).toEqual([]);
  });

  it('returns empty array on network error', async () => {
    server.use(http.get('https://api-adresse.data.gouv.fr/search', () => HttpResponse.error()));
    expect(await searchAddresses('foo')).toEqual([]);
  });
});
```

- [ ] **Step 4: Run, expect FAIL**

```powershell
pnpm jest tests/infra/ban-geocoding.test.ts
```

- [ ] **Step 5: Implement**

```ts
// src/infra/services/ban-geocoding.ts
export interface BanResult {
  label: string;
  city: string | null;
  postcode: string | null;
  lat: number;
  lon: number;
}

const BASE_URL = 'https://api-adresse.data.gouv.fr/search';

export async function searchAddresses(
  query: string,
  options: { limit?: number; signal?: AbortSignal } = {}
): Promise<BanResult[]> {
  const trimmed = query.trim();
  if (trimmed.length === 0) return [];

  const params = new URLSearchParams({
    q: trimmed,
    autocomplete: '1',
    limit: String(options.limit ?? 5),
  });

  try {
    const response = await fetch(`${BASE_URL}?${params}`, { signal: options.signal });
    if (!response.ok) return [];
    const json = (await response.json()) as {
      features?: {
        geometry: { coordinates: [number, number] };
        properties: { label: string; city?: string; postcode?: string };
      }[];
    };
    return (json.features ?? []).map((f) => ({
      label: f.properties.label,
      city: f.properties.city ?? null,
      postcode: f.properties.postcode ?? null,
      lat: f.geometry.coordinates[1],
      lon: f.geometry.coordinates[0],
    }));
  } catch {
    return [];
  }
}
```

- [ ] **Step 6: Run, expect PASS**

- [ ] **Step 7: Commit**

```powershell
git add -A
git commit -m "feat(infra): ban geocoding service with msw-mocked tests"
```

---

## Task 2.2: AddressAutocompleteInput component

**Files:**
- Create: `src/ui/primitives/input.tsx`
- Create: `src/ui/components/address-autocomplete-input.tsx`

- [ ] **Step 1: Create the Input primitive**

```tsx
// src/ui/primitives/input.tsx
import { TextInput, type TextInputProps } from 'react-native';
import { cn } from '@/lib/cn';

interface Props extends TextInputProps {
  className?: string;
}

export function Input({ className, ...rest }: Props) {
  return (
    <TextInput
      placeholderTextColor="rgb(var(--color-muted-foreground))"
      className={cn(
        'rounded-2xl border border-border bg-input px-4 py-3 text-base text-foreground',
        className
      )}
      {...rest}
    />
  );
}
```

- [ ] **Step 2: Create the AddressAutocompleteInput**

```tsx
// src/ui/components/address-autocomplete-input.tsx
import { useEffect, useRef, useState } from 'react';
import { View, FlatList, ActivityIndicator } from 'react-native';
import { searchAddresses, type BanResult } from '@/infra/services/ban-geocoding';
import { Input } from '@/ui/primitives/input';
import { Text } from '@/ui/primitives/text';
import { PressScale } from '@/ui/motion/press-scale';
import { haptics } from '@/ui/motion/haptics';

interface Props {
  initialValue?: string;
  placeholder?: string;
  onSelect: (result: BanResult) => void;
}

export function AddressAutocompleteInput({ initialValue = '', placeholder, onSelect }: Props) {
  const [query, setQuery] = useState(initialValue);
  const [results, setResults] = useState<BanResult[]>([]);
  const [loading, setLoading] = useState(false);
  const debounceRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const abortRef = useRef<AbortController | null>(null);

  useEffect(() => {
    if (debounceRef.current) clearTimeout(debounceRef.current);

    if (query.trim().length < 3) {
      setResults([]);
      setLoading(false);
      return;
    }

    setLoading(true);
    debounceRef.current = setTimeout(() => {
      abortRef.current?.abort();
      const controller = new AbortController();
      abortRef.current = controller;
      void searchAddresses(query, { signal: controller.signal })
        .then((r) => setResults(r))
        .finally(() => setLoading(false));
    }, 300);

    return () => {
      if (debounceRef.current) clearTimeout(debounceRef.current);
    };
  }, [query]);

  const handleSelect = (r: BanResult) => {
    void haptics.selection();
    setQuery(r.label);
    setResults([]);
    onSelect(r);
  };

  return (
    <View className="gap-2">
      <Input
        value={query}
        onChangeText={setQuery}
        placeholder={placeholder}
        autoCapitalize="none"
        autoCorrect={false}
      />
      {loading && (
        <View className="flex-row items-center gap-2 px-2">
          <ActivityIndicator size="small" />
          <Text className="text-muted-foreground text-sm">Recherche…</Text>
        </View>
      )}
      {results.length > 0 && (
        <View className="rounded-2xl border border-border bg-background overflow-hidden">
          <FlatList
            data={results}
            keyExtractor={(_, i) => String(i)}
            renderItem={({ item, index }) => (
              <PressScale
                onPress={() => handleSelect(item)}
                className={index === 0 ? '' : 'border-t border-border'}
              >
                <View className="px-4 py-3">
                  <Text className="text-foreground">{item.label}</Text>
                </View>
              </PressScale>
            )}
          />
        </View>
      )}
    </View>
  );
}
```

- [ ] **Step 3: Verify typecheck**

```powershell
pnpm typecheck
```

- [ ] **Step 4: Commit**

```powershell
git add -A
git commit -m "feat(ui): input primitive + address autocomplete component"
```

---

## Task 2.3: Persisted theme — wire SettingsRepository through ThemeProvider

**Files:**
- Modify: `src/state/stores/theme-store.ts`
- Modify: `src/infra/db/bootstrap.ts`
- Create: `src/state/queries/settings.ts`

- [ ] **Step 1: Update the theme store to expose persistence helpers**

```ts
// src/state/stores/theme-store.ts
import { create } from 'zustand';

export type ThemeMode = 'system' | 'light' | 'dark';

interface ThemeState {
  mode: ThemeMode;
  setMode: (mode: ThemeMode) => void;
}

export const useThemeStore = create<ThemeState>((set) => ({
  mode: 'system',
  setMode: (mode) => set({ mode }),
}));

export function isThemeMode(value: string): value is ThemeMode {
  return value === 'system' || value === 'light' || value === 'dark';
}
```

- [ ] **Step 2: Hydrate the theme store from settings during DB bootstrap**

Update `src/infra/db/bootstrap.ts`:

```ts
// src/infra/db/bootstrap.ts
import { migrate } from 'drizzle-orm/expo-sqlite/migrator';
import { db } from './client';
import migrations from './migrations/migrations';
import { seedSpeciesIfEmpty } from '@/data/seeds/species-seeds';
import { seedPrestationsIfEmpty } from '@/data/seeds/prestation-seeds';
import { SettingsRepository } from '@/data/repositories/settings-repository';
import { isThemeMode, useThemeStore } from '@/state/stores/theme-store';

let initialized = false;

export async function bootstrapDatabase() {
  if (initialized) return;
  await migrate(db, migrations);
  await seedSpeciesIfEmpty(db);
  await seedPrestationsIfEmpty(db);

  // Hydrate theme store from persisted setting (if any).
  const settingsRepo = new SettingsRepository(db);
  const persistedMode = await settingsRepo.get('theme_mode');
  if (persistedMode && isThemeMode(persistedMode)) {
    useThemeStore.getState().setMode(persistedMode);
  }

  initialized = true;
}
```

- [ ] **Step 3: Create a helper for settings queries/mutations**

```ts
// src/state/queries/settings.ts
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { db } from '@/infra/db/client';
import { SettingsRepository } from '@/data/repositories/settings-repository';
import { isThemeMode, useThemeStore, type ThemeMode } from '@/state/stores/theme-store';

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
```

- [ ] **Step 4: Verify typecheck**

```powershell
pnpm typecheck
```

- [ ] **Step 5: Commit**

```powershell
git add -A
git commit -m "feat(state): persist theme mode in settings; useBaseAddress query/mutation"
```

---

## Task 2.4: Settings root screen

**Files:**
- Modify: `app/(tabs)/settings/index.tsx`
- Create: `app/(tabs)/settings/_layout.tsx`
- Create: `src/ui/components/settings-row.tsx`
- Modify: `src/i18n/locales/fr.json`

- [ ] **Step 1: Update fr.json with the settings strings**

In `src/i18n/locales/fr.json`, add a `settings` section to the JSON object:

```json
"settings": {
  "title": "Réglages",
  "appearance": {
    "row_label": "Apparence",
    "row_hint": "Thème clair, sombre ou système",
    "screen_title": "Apparence",
    "options": {
      "system": "Système",
      "light": "Clair",
      "dark": "Sombre"
    }
  },
  "base": {
    "row_label": "Domicile / Base",
    "row_hint": "Point de départ des tournées",
    "screen_title": "Domicile / Base",
    "address_label": "Adresse",
    "address_placeholder": "Saisir une adresse française…",
    "current_label": "Adresse enregistrée :",
    "save_button": "Enregistrer l'adresse",
    "saved_toast": "Adresse enregistrée"
  }
}
```

- [ ] **Step 2: Create the stack layout for settings**

```tsx
// app/(tabs)/settings/_layout.tsx
import { Stack } from 'expo-router';

export default function SettingsLayout() {
  return (
    <Stack
      screenOptions={{
        headerShown: true,
        headerStyle: { backgroundColor: 'transparent' },
        animation: 'slide_from_right',
      }}
    />
  );
}
```

- [ ] **Step 3: Create a reusable SettingsRow primitive with PressScale + lucide chevron**

```tsx
// src/ui/components/settings-row.tsx
import { View } from 'react-native';
import { ChevronRight } from 'lucide-react-native';
import { PressScale } from '@/ui/motion/press-scale';
import { Text } from '@/ui/primitives/text';
import { haptics } from '@/ui/motion/haptics';

interface Props {
  label: string;
  hint?: string;
  onPress: () => void;
  testID?: string;
}

export function SettingsRow({ label, hint, onPress, testID }: Props) {
  const handle = () => {
    void haptics.selection();
    onPress();
  };
  return (
    <PressScale onPress={handle} testID={testID}>
      <View className="flex-row items-center justify-between rounded-2xl border border-border bg-background px-4 py-4">
        <View className="flex-1 pr-4">
          <Text className="text-foreground text-base font-medium">{label}</Text>
          {hint ? <Text className="text-muted-foreground text-sm mt-0.5">{hint}</Text> : null}
        </View>
        <ChevronRight size={20} color="rgb(var(--color-muted-foreground))" />
      </View>
    </PressScale>
  );
}
```

- [ ] **Step 4: Replace the settings index screen**

```tsx
// app/(tabs)/settings/index.tsx
import { ScrollView, View } from 'react-native';
import { useRouter, Stack } from 'expo-router';
import { useTranslation } from 'react-i18next';
import { SettingsRow } from '@/ui/components/settings-row';

export default function SettingsScreen() {
  const router = useRouter();
  const { t } = useTranslation();

  return (
    <View className="flex-1 bg-background">
      <Stack.Screen options={{ title: t('settings.title') }} />
      <ScrollView contentContainerClassName="px-4 pt-4 gap-3">
        <SettingsRow
          label={t('settings.appearance.row_label')}
          hint={t('settings.appearance.row_hint')}
          onPress={() => router.push('/(tabs)/settings/appearance')}
        />
        <SettingsRow
          label={t('settings.base.row_label')}
          hint={t('settings.base.row_hint')}
          onPress={() => router.push('/(tabs)/settings/base')}
        />
      </ScrollView>
    </View>
  );
}
```

- [ ] **Step 5: Verify typecheck**

```powershell
pnpm typecheck
```

- [ ] **Step 6: Commit**

```powershell
git add -A
git commit -m "feat(settings): root screen with two rows (appearance, base)"
```

---

## Task 2.5: Appearance screen — theme switch

**Files:**
- Create: `app/(tabs)/settings/appearance.tsx`
- Create: `src/ui/components/radio-row.tsx`

- [ ] **Step 1: Create a RadioRow primitive**

```tsx
// src/ui/components/radio-row.tsx
import { View } from 'react-native';
import { Check } from 'lucide-react-native';
import { PressScale } from '@/ui/motion/press-scale';
import { Text } from '@/ui/primitives/text';
import { haptics } from '@/ui/motion/haptics';

interface Props {
  label: string;
  selected: boolean;
  onPress: () => void;
}

export function RadioRow({ label, selected, onPress }: Props) {
  const handle = () => {
    void haptics.selection();
    onPress();
  };
  return (
    <PressScale onPress={handle}>
      <View className="flex-row items-center justify-between rounded-2xl border border-border bg-background px-4 py-4">
        <Text className="text-foreground text-base">{label}</Text>
        {selected && <Check size={20} color="rgb(var(--color-primary))" />}
      </View>
    </PressScale>
  );
}
```

- [ ] **Step 2: Create the appearance screen**

```tsx
// app/(tabs)/settings/appearance.tsx
import { ScrollView, View } from 'react-native';
import { Stack } from 'expo-router';
import { useTranslation } from 'react-i18next';
import { RadioRow } from '@/ui/components/radio-row';
import { useThemeMode, useSetThemeMode } from '@/state/queries/settings';
import type { ThemeMode } from '@/state/stores/theme-store';

const ORDER: ThemeMode[] = ['system', 'light', 'dark'];

export default function AppearanceScreen() {
  const { t } = useTranslation();
  const mode = useThemeMode();
  const setMode = useSetThemeMode();

  return (
    <View className="flex-1 bg-background">
      <Stack.Screen options={{ title: t('settings.appearance.screen_title') }} />
      <ScrollView contentContainerClassName="px-4 pt-4 gap-3">
        {ORDER.map((option) => (
          <RadioRow
            key={option}
            label={t(`settings.appearance.options.${option}`)}
            selected={mode === option}
            onPress={() => setMode.mutate(option)}
          />
        ))}
      </ScrollView>
    </View>
  );
}
```

- [ ] **Step 3: Verify typecheck**

```powershell
pnpm typecheck
```

- [ ] **Step 4: Manual verification on device**

- [ ] Open Settings tab
- [ ] Tap "Apparence"
- [ ] Tap "Sombre" → app switches to dark mode immediately
- [ ] Force reload (`r` in the dev client menu) → app stays in dark mode (persistence works)
- [ ] Tap "Système" → app follows OS theme

- [ ] **Step 5: Commit**

```powershell
git add -A
git commit -m "feat(settings): appearance screen with persisted theme switch"
```

---

## Task 2.6: Base/domicile screen with BAN form

**Files:**
- Create: `app/(tabs)/settings/base.tsx`

- [ ] **Step 1: Create the screen**

```tsx
// app/(tabs)/settings/base.tsx
import { useState } from 'react';
import { ScrollView, View } from 'react-native';
import { Stack } from 'expo-router';
import { useTranslation } from 'react-i18next';
import { AddressAutocompleteInput } from '@/ui/components/address-autocomplete-input';
import { Button } from '@/ui/primitives/button';
import { Text } from '@/ui/primitives/text';
import { useBaseAddress, useSetBaseAddress, type BaseAddress } from '@/state/queries/settings';
import { haptics } from '@/ui/motion/haptics';
import type { BanResult } from '@/infra/services/ban-geocoding';

export default function BaseScreen() {
  const { t } = useTranslation();
  const { data: current } = useBaseAddress();
  const setBase = useSetBaseAddress();
  const [pending, setPending] = useState<BaseAddress | null>(null);

  const onSelect = (r: BanResult) => {
    setPending({
      label: r.label,
      city: r.city,
      postcode: r.postcode,
      lat: r.lat,
      lon: r.lon,
    });
  };

  const onSave = () => {
    if (!pending) return;
    setBase.mutate(pending, {
      onSuccess: () => {
        void haptics.success();
        setPending(null);
      },
    });
  };

  return (
    <View className="flex-1 bg-background">
      <Stack.Screen options={{ title: t('settings.base.screen_title') }} />
      <ScrollView contentContainerClassName="px-4 pt-4 gap-4">
        {current && (
          <View className="rounded-2xl border border-border bg-muted px-4 py-3">
            <Text className="text-muted-foreground text-sm">{t('settings.base.current_label')}</Text>
            <Text className="text-foreground mt-1">{current.label}</Text>
          </View>
        )}

        <View className="gap-2">
          <Text className="text-foreground text-sm font-medium">
            {t('settings.base.address_label')}
          </Text>
          <AddressAutocompleteInput
            placeholder={t('settings.base.address_placeholder')}
            onSelect={onSelect}
          />
        </View>

        <Button
          onPress={onSave}
          disabled={!pending || setBase.isPending}
          loading={setBase.isPending}
        >
          {t('settings.base.save_button')}
        </Button>
      </ScrollView>
    </View>
  );
}
```

- [ ] **Step 2: Verify typecheck**

```powershell
pnpm typecheck
```

- [ ] **Step 3: Manual verification on device**

- [ ] Open Settings → "Domicile / Base"
- [ ] Type "rue" in the input — suggestions appear
- [ ] Pick a suggestion — input is filled, suggestions disappear
- [ ] Tap "Enregistrer l'adresse" — haptic success fires, no error
- [ ] Reload the app → screen shows the address under "Adresse enregistrée :"

- [ ] **Step 4: Commit**

```powershell
git add -A
git commit -m "feat(settings): base/domicile form with BAN autocomplete and persistence"
```

---

## Phase 2 — End checklist

- [ ] Settings tab shows two clickable rows
- [ ] Tapping "Apparence" navigates to a screen with three options; selecting one applies + persists
- [ ] App reload retains the selected theme
- [ ] Tapping "Domicile / Base" navigates to a form
- [ ] BAN autocomplete returns suggestions for FR addresses
- [ ] Selecting a suggestion + tapping "Enregistrer" persists the base
- [ ] App reload retains the saved base
- [ ] All interactions feel responsive (PressScale on rows, haptic feedback on selection/save)
- [ ] `pnpm test` green; `pnpm typecheck` clean

**Foundations complete.** The next plan document covers Jalon 3 (Clients). Write that plan when J0+J1+J2 are merged into `rn-migration` and you're ready to build the Clients feature.
