# Phase 0 — Bootstrap

**Goal:** Worktree set up, Expo TS project alive, the full stack installed and wired (NativeWind theming, Reanimated/Moti/haptics, Drizzle/expo-sqlite, Supabase, i18n, Zustand, TanStack Query, Expo Router, react-native-reusables primitives, tests, EAS, CI). At the end of this phase, a hello screen renders on **both** iOS and Android dev clients, dark-mode toggle works with smooth transition, haptic feedback fires, and `pnpm test` passes.

**Verification at end of phase:**
- `pnpm typecheck` clean
- `pnpm lint` clean
- `pnpm test` green (sample tests in domain + infra)
- Hello screen renders on iOS simulator and Android emulator with the dev client
- Tapping the theme toggle on the hello screen changes the theme with a transition
- Tapping the test button triggers haptic feedback (on physical device)

---

## Task 0.1: Mark Flutter state and create worktree

**Files:**
- No file changes in main repo working tree (only git operations)

- [ ] **Step 1: From the main repo, create a tag on the current Flutter state**

```powershell
# At C:\Users\rapha\Documents\Development\coupe-laine\
git tag flutter-final-v0.7.0
```

- [ ] **Step 2: Create the `rn-migration` branch from main**

```powershell
git branch rn-migration main
```

- [ ] **Step 3: Create the worktree at the sibling location**

```powershell
git worktree add ..\coupe-laine-rn rn-migration
```

Expected output: `Preparing worktree (new branch 'rn-migration')...` and `HEAD is now at <hash> ...`.

- [ ] **Step 4: Verify the worktree exists**

```powershell
git worktree list
```

Expected: two entries — the main repo at `coupe-laine` (branch `main`), and `coupe-laine-rn` (branch `rn-migration`).

- [ ] **Step 5: Switch to the worktree directory for all subsequent steps**

```powershell
cd C:\Users\rapha\Documents\Development\coupe-laine-rn
```

**All remaining tasks in this plan run in the worktree directory unless noted otherwise.**

---

## Task 0.2: Strip Flutter code from the worktree

**Files:**
- Delete: `lib/`, `android/`, `ios/` (if exists), `build/`, `test/`, `assets/` (will be re-introduced selectively later), `pubspec.yaml`, `pubspec.lock`, `analysis_options.yaml`, `.metadata`, `coupe_laine.iml`, `linux/`, `macos/`, `web/`, `windows/`
- Keep: `docs/`, `CLAUDE.md`, `.git/` (managed by worktree), `.gitignore` (will be replaced)

- [ ] **Step 1: Delete Flutter directories and files**

```powershell
Remove-Item -Recurse -Force lib, android, build, test
Remove-Item -Force pubspec.yaml, pubspec.lock, analysis_options.yaml, .metadata
# Some of these may not exist depending on the platforms previously generated; ignore "not found" errors:
Remove-Item -Recurse -Force ios, linux, macos, web, windows -ErrorAction SilentlyContinue
Remove-Item -Force coupe_laine.iml -ErrorAction SilentlyContinue
# Remove the assets folder for now; if any are needed later we re-import selectively.
Remove-Item -Recurse -Force assets -ErrorAction SilentlyContinue
```

- [ ] **Step 2: Replace the .gitignore with an Expo-friendly version**

Overwrite `.gitignore` at the worktree root:

```gitignore
# Dependencies
node_modules/
.pnp
.pnp.js

# Expo
.expo/
dist/
web-build/
expo-env.d.ts

# Native
ios/
android/
*.orig.*

# Metro
.metro-health-check*

# Build
.tamagui/

# Debug
npm-debug.*
yarn-debug.*
yarn-error.*

# macOS
.DS_Store
*.pem

# Local env
.env
.env.local
.env.*.local

# Editor
.vscode/
.idea/
*.swp

# Testing
coverage/

# Typescript
*.tsbuildinfo

# Drizzle
drizzle/.snapshots
```

- [ ] **Step 3: Commit the stripped state**

```powershell
git add -A
git commit -m "chore: strip Flutter code from rn-migration worktree"
```

---

## Task 0.3: Initialize the Expo TypeScript project

**Files:**
- Create: `package.json`, `tsconfig.json`, `app.json`, `babel.config.js`, `metro.config.js`, `index.ts`, `app/_layout.tsx`, `app/index.tsx`

- [ ] **Step 1: Initialize the Expo project at the worktree root**

```powershell
pnpm create expo-app@latest . --template default --no-install
```

If prompted to overwrite, accept. The current directory will receive the Expo template files alongside the preserved `docs/` and `CLAUDE.md`.

- [ ] **Step 2: Update package.json with the project name and pnpm scripts**

Replace the `name`, `version`, `private` and `scripts` sections of `package.json` to:

```json
{
  "name": "coupe-laine-rn",
  "version": "0.0.1",
  "private": true,
  "main": "expo-router/entry",
  "scripts": {
    "start": "expo start --dev-client",
    "android": "expo run:android",
    "ios": "expo run:ios",
    "lint": "expo lint",
    "typecheck": "tsc --noEmit",
    "test": "vitest run && jest",
    "test:domain": "vitest run",
    "test:integration": "jest",
    "db:generate": "drizzle-kit generate",
    "db:studio": "drizzle-kit studio"
  }
}
```

- [ ] **Step 3: Install dependencies with pnpm**

```powershell
pnpm install
```

Expected: `node_modules/` is created, `pnpm-lock.yaml` is generated.

- [ ] **Step 4: Update `tsconfig.json` for strict mode**

Replace the contents with:

```json
{
  "extends": "expo/tsconfig.base",
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitOverride": true,
    "noFallthroughCasesInSwitch": true,
    "forceConsistentCasingInFileNames": true,
    "paths": {
      "@/*": ["./src/*"],
      "@app/*": ["./app/*"]
    }
  },
  "include": ["**/*.ts", "**/*.tsx", ".expo/types/**/*.ts", "expo-env.d.ts"],
  "exclude": ["node_modules"]
}
```

- [ ] **Step 5: Verify typecheck passes**

```powershell
pnpm typecheck
```

Expected: no output (success).

- [ ] **Step 6: Commit**

```powershell
git add -A
git commit -m "chore: bootstrap expo typescript project"
```

---

## Task 0.4: Install and configure NativeWind v4 + Tailwind

**Files:**
- Create: `tailwind.config.js`, `global.css`, `nativewind-env.d.ts`
- Modify: `babel.config.js`, `metro.config.js`, `app/_layout.tsx`

- [ ] **Step 1: Install NativeWind, Tailwind, and required peer deps**

```powershell
pnpm add nativewind react-native-reanimated react-native-safe-area-context
pnpm add -D tailwindcss@3.4.17 prettier-plugin-tailwindcss
```

> Note: NativeWind v4 currently requires Tailwind v3.4.x. Don't upgrade to v4 of Tailwind without verifying compatibility.

- [ ] **Step 2: Create `tailwind.config.js`**

```js
/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ['./app/**/*.{js,jsx,ts,tsx}', './src/**/*.{js,jsx,ts,tsx}'],
  presets: [require('nativewind/preset')],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        // Modern Craft palette — tokens defined here, refined in Task 0.6.
        background: 'rgb(var(--color-background) / <alpha-value>)',
        foreground: 'rgb(var(--color-foreground) / <alpha-value>)',
        primary: {
          DEFAULT: 'rgb(var(--color-primary) / <alpha-value>)',
          foreground: 'rgb(var(--color-primary-foreground) / <alpha-value>)',
        },
        muted: {
          DEFAULT: 'rgb(var(--color-muted) / <alpha-value>)',
          foreground: 'rgb(var(--color-muted-foreground) / <alpha-value>)',
        },
        accent: {
          DEFAULT: 'rgb(var(--color-accent) / <alpha-value>)',
          foreground: 'rgb(var(--color-accent-foreground) / <alpha-value>)',
        },
        border: 'rgb(var(--color-border) / <alpha-value>)',
        input: 'rgb(var(--color-input) / <alpha-value>)',
        ring: 'rgb(var(--color-ring) / <alpha-value>)',
        danger: {
          DEFAULT: 'rgb(var(--color-danger) / <alpha-value>)',
          foreground: 'rgb(var(--color-danger-foreground) / <alpha-value>)',
        },
        success: {
          DEFAULT: 'rgb(var(--color-success) / <alpha-value>)',
          foreground: 'rgb(var(--color-success-foreground) / <alpha-value>)',
        },
        // Domain-semantic
        waiting: 'rgb(var(--color-waiting) / <alpha-value>)',
        shorn: 'rgb(var(--color-shorn) / <alpha-value>)',
      },
    },
  },
  plugins: [],
};
```

- [ ] **Step 3: Create `global.css` with the CSS variables for the Modern Craft palette**

```css
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
  :root {
    --color-background: 250 246 240;        /* warm cream */
    --color-foreground: 28 22 18;           /* dark warm brown */
    --color-primary: 161 96 47;             /* burnt sienna */
    --color-primary-foreground: 250 246 240;
    --color-muted: 234 224 211;
    --color-muted-foreground: 92 78 64;
    --color-accent: 116 142 96;             /* sage green */
    --color-accent-foreground: 250 246 240;
    --color-border: 220 208 192;
    --color-input: 234 224 211;
    --color-ring: 161 96 47;
    --color-danger: 178 56 50;
    --color-danger-foreground: 250 246 240;
    --color-success: 84 122 70;
    --color-success-foreground: 250 246 240;
    --color-waiting: 200 130 38;            /* warm orange */
    --color-shorn: 116 142 96;              /* sage green (same as accent) */
  }

  .dark {
    --color-background: 22 18 15;           /* very dark brown, not pure black */
    --color-foreground: 240 232 220;        /* warm cream */
    --color-primary: 198 138 88;            /* lighter sienna for dark */
    --color-primary-foreground: 22 18 15;
    --color-muted: 48 40 32;
    --color-muted-foreground: 180 164 144;
    --color-accent: 152 178 130;            /* lighter sage for dark */
    --color-accent-foreground: 22 18 15;
    --color-border: 60 50 42;
    --color-input: 48 40 32;
    --color-ring: 198 138 88;
    --color-danger: 220 96 90;
    --color-danger-foreground: 22 18 15;
    --color-success: 152 184 130;
    --color-success-foreground: 22 18 15;
    --color-waiting: 220 158 78;
    --color-shorn: 152 178 130;
  }
}
```

> **Palette note:** these values are a starting point matching the "Modern Craft" feel. Refine them visually in Task 0.6 once you can see them on a device.

- [ ] **Step 4: Update `babel.config.js`**

```js
module.exports = function (api) {
  api.cache(true);
  return {
    presets: [
      ['babel-preset-expo', { jsxImportSource: 'nativewind' }],
      'nativewind/babel',
    ],
    plugins: ['react-native-reanimated/plugin'],
  };
};
```

> **Important:** `react-native-reanimated/plugin` MUST be the last plugin in the list.

- [ ] **Step 5: Create `metro.config.js`**

```js
const { getDefaultConfig } = require('expo/metro-config');
const { withNativeWind } = require('nativewind/metro');

const config = getDefaultConfig(__dirname);

module.exports = withNativeWind(config, { input: './global.css' });
```

- [ ] **Step 6: Create `nativewind-env.d.ts`**

```ts
/// <reference types="nativewind/types" />
```

- [ ] **Step 7: Import `global.css` in the root layout**

Replace the contents of `app/_layout.tsx`:

```tsx
import '../global.css';
import { Stack } from 'expo-router';

export default function RootLayout() {
  return <Stack screenOptions={{ headerShown: false }} />;
}
```

- [ ] **Step 8: Verify typecheck still passes**

```powershell
pnpm typecheck
```

- [ ] **Step 9: Commit**

```powershell
git add -A
git commit -m "feat(ui): wire nativewind v4 with modern craft palette tokens"
```

---

## Task 0.5: Theme provider, theme store, and dark mode plumbing

**Files:**
- Create: `src/state/stores/theme-store.ts`
- Create: `src/ui/theme/theme-provider.tsx`
- Modify: `app/_layout.tsx`

- [ ] **Step 1: Install Zustand**

```powershell
pnpm add zustand
```

- [ ] **Step 2: Create the theme store**

```ts
// src/state/stores/theme-store.ts
import { create } from 'zustand';

export type ThemeMode = 'system' | 'light' | 'dark';

interface ThemeState {
  mode: ThemeMode;
  setMode: (mode: ThemeMode) => void;
}

/**
 * In-memory only for now. Persistence to the SQLite settings table is wired
 * in Phase 2 once the DB layer exists.
 */
export const useThemeStore = create<ThemeState>((set) => ({
  mode: 'system',
  setMode: (mode) => set({ mode }),
}));
```

- [ ] **Step 3: Create the ThemeProvider**

```tsx
// src/ui/theme/theme-provider.tsx
import { useColorScheme } from 'nativewind';
import { useEffect, type ReactNode } from 'react';
import { View } from 'react-native';
import { useThemeStore } from '@/state/stores/theme-store';

interface Props {
  children: ReactNode;
}

export function ThemeProvider({ children }: Props) {
  const mode = useThemeStore((s) => s.mode);
  const { colorScheme, setColorScheme } = useColorScheme();

  useEffect(() => {
    if (mode === 'system') {
      setColorScheme('system');
    } else {
      setColorScheme(mode);
    }
  }, [mode, setColorScheme]);

  const isDark = colorScheme === 'dark';

  return (
    <View className={isDark ? 'dark flex-1' : 'flex-1'}>
      <View className="flex-1 bg-background">{children}</View>
    </View>
  );
}
```

- [ ] **Step 4: Wrap the root layout with ThemeProvider**

```tsx
// app/_layout.tsx
import '../global.css';
import { Stack } from 'expo-router';
import { GestureHandlerRootView } from 'react-native-gesture-handler';
import { ThemeProvider } from '@/ui/theme/theme-provider';

export default function RootLayout() {
  return (
    <GestureHandlerRootView style={{ flex: 1 }}>
      <ThemeProvider>
        <Stack screenOptions={{ headerShown: false }} />
      </ThemeProvider>
    </GestureHandlerRootView>
  );
}
```

- [ ] **Step 5: Install gesture-handler (already a peer of reanimated, but ensure)**

```powershell
pnpm add react-native-gesture-handler
```

- [ ] **Step 6: Verify typecheck**

```powershell
pnpm typecheck
```

- [ ] **Step 7: Commit**

```powershell
git add -A
git commit -m "feat(theme): theme provider with system/light/dark modes via zustand"
```

---

## Task 0.6: Motion stack — Reanimated, Moti, haptics, motion tokens, primitives

**Files:**
- Create: `src/ui/motion/motion-tokens.ts`
- Create: `src/ui/motion/haptics.ts`
- Create: `src/ui/motion/press-scale.tsx`
- Create: `src/ui/motion/transitions.ts`

- [ ] **Step 1: Install motion deps**

```powershell
pnpm add moti expo-haptics lottie-react-native
```

> `react-native-reanimated` is already installed from Task 0.4. `react-native-gesture-handler` is already installed from Task 0.5.

- [ ] **Step 2: Create `motion-tokens.ts`**

```ts
// src/ui/motion/motion-tokens.ts
import { Easing } from 'react-native-reanimated';

export const motion = {
  duration: {
    instant: 100,
    fast: 200,
    normal: 300,
    slow: 500,
  },
  easing: {
    standard: Easing.bezier(0.4, 0.0, 0.2, 1),
    decelerate: Easing.bezier(0.0, 0.0, 0.2, 1),
    accelerate: Easing.bezier(0.4, 0.0, 1, 1),
  },
  spring: {
    soft: { damping: 18, stiffness: 120, mass: 1 },
    medium: { damping: 15, stiffness: 150, mass: 1 },
    bouncy: { damping: 10, stiffness: 180, mass: 1 },
  },
} as const;
```

- [ ] **Step 3: Create `haptics.ts`**

```ts
// src/ui/motion/haptics.ts
import * as Haptics from 'expo-haptics';

export const haptics = {
  selection: () => Haptics.selectionAsync(),
  lightTap: () => Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light),
  mediumTap: () => Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium),
  heavyTap: () => Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Heavy),
  success: () => Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success),
  warning: () => Haptics.notificationAsync(Haptics.NotificationFeedbackType.Warning),
  error: () => Haptics.notificationAsync(Haptics.NotificationFeedbackType.Error),
};
```

- [ ] **Step 4: Create `press-scale.tsx`**

```tsx
// src/ui/motion/press-scale.tsx
import type { ReactNode } from 'react';
import {
  GestureResponderEvent,
  Pressable,
  PressableProps,
  StyleProp,
  ViewStyle,
} from 'react-native';
import Animated, {
  useAnimatedStyle,
  useSharedValue,
  withSpring,
} from 'react-native-reanimated';
import { motion } from './motion-tokens';

interface Props extends Omit<PressableProps, 'children' | 'style'> {
  children: ReactNode;
  scaleTo?: number;
  style?: StyleProp<ViewStyle>;
}

const AnimatedPressable = Animated.createAnimatedComponent(Pressable);

/**
 * Wraps a pressable with a spring scale-down on press. Use for buttons,
 * cards, list items — any tappable surface.
 */
export function PressScale({
  children,
  scaleTo = 0.97,
  style,
  onPressIn,
  onPressOut,
  ...rest
}: Props) {
  const scale = useSharedValue(1);

  const animatedStyle = useAnimatedStyle(() => ({
    transform: [{ scale: scale.value }],
  }));

  const handlePressIn = (e: GestureResponderEvent) => {
    scale.value = withSpring(scaleTo, motion.spring.medium);
    onPressIn?.(e);
  };
  const handlePressOut = (e: GestureResponderEvent) => {
    scale.value = withSpring(1, motion.spring.medium);
    onPressOut?.(e);
  };

  return (
    <AnimatedPressable
      onPressIn={handlePressIn}
      onPressOut={handlePressOut}
      style={[animatedStyle, style]}
      {...rest}
    >
      {children}
    </AnimatedPressable>
  );
}
```

- [ ] **Step 5: Create `transitions.ts` with Expo Router presets**

```ts
// src/ui/motion/transitions.ts
import type { NativeStackNavigationOptions } from '@react-navigation/native-stack';

/** Default stack transition: native slide horizontal. */
export const stackSlide: NativeStackNavigationOptions = {
  animation: 'slide_from_right',
  animationDuration: 250,
};

/** Modal-style slide from bottom with fade backdrop. */
export const modalSlide: NativeStackNavigationOptions = {
  presentation: 'modal',
  animation: 'slide_from_bottom',
  animationDuration: 300,
};

/** No animation, used for tab roots. */
export const noAnimation: NativeStackNavigationOptions = {
  animation: 'none',
};
```

- [ ] **Step 6: Verify typecheck**

```powershell
pnpm typecheck
```

- [ ] **Step 7: Commit**

```powershell
git add -A
git commit -m "feat(motion): tokens, haptics wrapper, press-scale primitive, transitions"
```

---

## Task 0.7: Drizzle ORM and expo-sqlite

**Files:**
- Create: `drizzle.config.ts`
- Create: `src/infra/db/schema.ts` (empty placeholder)
- Create: `src/infra/db/client.ts`
- Modify: `app.json` (add expo-sqlite plugin)

- [ ] **Step 1: Install Drizzle and expo-sqlite**

```powershell
pnpm add drizzle-orm expo-sqlite
pnpm add -D drizzle-kit
```

- [ ] **Step 2: Add the expo-sqlite plugin to `app.json`**

In `app.json`, in the `expo.plugins` array, add `"expo-sqlite"`. The relevant section should look like:

```json
"plugins": [
  "expo-router",
  "expo-sqlite"
]
```

> If `expo-router` is already there from the template, leave it; just append `"expo-sqlite"`.

- [ ] **Step 3: Create `drizzle.config.ts`**

```ts
import type { Config } from 'drizzle-kit';

export default {
  schema: './src/infra/db/schema.ts',
  out: './src/infra/db/migrations',
  dialect: 'sqlite',
  driver: 'expo',
} satisfies Config;
```

- [ ] **Step 4: Create empty schema placeholder**

```ts
// src/infra/db/schema.ts
// Tables are defined in Phase 1 (01-persistence-domain.md).
// This placeholder lets drizzle-kit and the app boot cleanly until then.
export {};
```

- [ ] **Step 5: Create the DB client**

```ts
// src/infra/db/client.ts
import { drizzle } from 'drizzle-orm/expo-sqlite';
import { openDatabaseSync } from 'expo-sqlite';

const sqlite = openDatabaseSync('coupe-laine.db');

export const db = drizzle(sqlite);

export type Database = typeof db;
```

- [ ] **Step 6: Verify typecheck**

```powershell
pnpm typecheck
```

- [ ] **Step 7: Commit**

```powershell
git add -A
git commit -m "chore(db): wire drizzle orm with expo-sqlite, empty schema"
```

---

## Task 0.8: Supabase client + secure-store adapter + env config

**Files:**
- Create: `src/infra/services/supabase.ts`
- Create: `src/infra/config/env.ts`
- Create: `.env.example`
- Create: `.env` (gitignored, with empty values)

- [ ] **Step 1: Install Supabase + secure-store**

```powershell
pnpm add @supabase/supabase-js expo-secure-store
```

- [ ] **Step 2: Create `.env.example`**

```
EXPO_PUBLIC_SUPABASE_URL=
EXPO_PUBLIC_SUPABASE_ANON_KEY=
EXPO_PUBLIC_MAPTILER_API_KEY=
EXPO_PUBLIC_ORS_BASE_URL=
```

- [ ] **Step 3: Create local `.env`** (will be gitignored)

```
EXPO_PUBLIC_SUPABASE_URL=https://placeholder.supabase.co
EXPO_PUBLIC_SUPABASE_ANON_KEY=placeholder
EXPO_PUBLIC_MAPTILER_API_KEY=placeholder
EXPO_PUBLIC_ORS_BASE_URL=https://placeholder.supabase.co/functions/v1/ors-proxy
```

> Real values come later. The `EXPO_PUBLIC_` prefix is required for Expo to expose vars to the client bundle. The `.env` file is in `.gitignore`.

- [ ] **Step 4: Create the env accessor**

```ts
// src/infra/config/env.ts
function required(name: string, value: string | undefined): string {
  if (!value || value.length === 0) {
    throw new Error(`Missing env var: ${name}`);
  }
  return value;
}

export const env = {
  supabaseUrl: required('EXPO_PUBLIC_SUPABASE_URL', process.env.EXPO_PUBLIC_SUPABASE_URL),
  supabaseAnonKey: required('EXPO_PUBLIC_SUPABASE_ANON_KEY', process.env.EXPO_PUBLIC_SUPABASE_ANON_KEY),
  maptilerApiKey: required('EXPO_PUBLIC_MAPTILER_API_KEY', process.env.EXPO_PUBLIC_MAPTILER_API_KEY),
  orsBaseUrl: required('EXPO_PUBLIC_ORS_BASE_URL', process.env.EXPO_PUBLIC_ORS_BASE_URL),
};
```

- [ ] **Step 5: Create the Supabase client with secure-store adapter**

```ts
// src/infra/services/supabase.ts
import { createClient } from '@supabase/supabase-js';
import * as SecureStore from 'expo-secure-store';
import { env } from '@/infra/config/env';

const SecureStoreAdapter = {
  getItem: (key: string) => SecureStore.getItemAsync(key),
  setItem: (key: string, value: string) => SecureStore.setItemAsync(key, value),
  removeItem: (key: string) => SecureStore.deleteItemAsync(key),
};

export const supabase = createClient(env.supabaseUrl, env.supabaseAnonKey, {
  auth: {
    storage: SecureStoreAdapter,
    autoRefreshToken: true,
    persistSession: true,
    detectSessionInUrl: false,
  },
});
```

- [ ] **Step 6: Verify typecheck**

```powershell
pnpm typecheck
```

- [ ] **Step 7: Commit**

```powershell
git add -A
git commit -m "chore(supabase): client with secure-store adapter, env config"
```

---

## Task 0.9: TanStack Query setup

**Files:**
- Modify: `app/_layout.tsx`

- [ ] **Step 1: Install TanStack Query**

```powershell
pnpm add @tanstack/react-query
```

- [ ] **Step 2: Wrap the root layout with QueryClientProvider**

Update `app/_layout.tsx`:

```tsx
import '../global.css';
import { Stack } from 'expo-router';
import { GestureHandlerRootView } from 'react-native-gesture-handler';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { ThemeProvider } from '@/ui/theme/theme-provider';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 30_000,
      retry: 1,
    },
  },
});

export default function RootLayout() {
  return (
    <GestureHandlerRootView style={{ flex: 1 }}>
      <QueryClientProvider client={queryClient}>
        <ThemeProvider>
          <Stack screenOptions={{ headerShown: false }} />
        </ThemeProvider>
      </QueryClientProvider>
    </GestureHandlerRootView>
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
git commit -m "chore(state): wire tanstack query at root"
```

---

## Task 0.10: i18next + expo-localization

**Files:**
- Create: `src/i18n/index.ts`
- Create: `src/i18n/locales/fr.json`
- Modify: `app/_layout.tsx`

- [ ] **Step 1: Install i18n deps**

```powershell
pnpm add i18next react-i18next expo-localization
```

- [ ] **Step 2: Create the initial French locale file**

```json
// src/i18n/locales/fr.json
{
  "common": {
    "save": "Enregistrer",
    "cancel": "Annuler",
    "delete": "Supprimer",
    "edit": "Modifier",
    "back": "Retour",
    "loading": "Chargement…",
    "error_generic": "Une erreur est survenue.",
    "retry": "Réessayer"
  },
  "hello": {
    "title": "Coupe-laine",
    "subtitle": "Compagnon quotidien du tondeur de mouton",
    "toggle_theme": "Basculer le thème",
    "test_haptic": "Tester le haptic"
  },
  "tabs": {
    "clients": "Clients",
    "tours": "Tournées",
    "proximity": "Proximité",
    "map": "Carte",
    "settings": "Réglages"
  }
}
```

- [ ] **Step 3: Create the i18n setup module**

```ts
// src/i18n/index.ts
import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';
import { getLocales } from 'expo-localization';
import fr from './locales/fr.json';

const deviceLocale = getLocales()[0]?.languageCode ?? 'fr';

i18n.use(initReactI18next).init({
  resources: { fr: { translation: fr } },
  lng: deviceLocale === 'fr' ? 'fr' : 'fr', // FR-only for v1
  fallbackLng: 'fr',
  interpolation: { escapeValue: false },
  returnNull: false,
});

export default i18n;
```

- [ ] **Step 4: Import the i18n module in the root layout (side-effect init)**

Update `app/_layout.tsx` to add the import at the top, after `global.css`:

```tsx
import '../global.css';
import '@/i18n';
import { Stack } from 'expo-router';
// ... rest unchanged
```

- [ ] **Step 5: Verify typecheck**

```powershell
pnpm typecheck
```

- [ ] **Step 6: Commit**

```powershell
git add -A
git commit -m "chore(i18n): wire i18next with french locale, expo-localization"
```

---

## Task 0.11: Forms (react-hook-form + zod), date-fns, lucide icons

**Files:**
- No file changes, just installs

- [ ] **Step 1: Install forms + utilities**

```powershell
pnpm add react-hook-form zod @hookform/resolvers
pnpm add date-fns lucide-react-native react-native-svg
```

> `react-native-svg` is required by `lucide-react-native`.

- [ ] **Step 2: Verify typecheck still passes** (sanity check after deps changed)

```powershell
pnpm typecheck
```

- [ ] **Step 3: Commit**

```powershell
git add -A
git commit -m "chore(deps): forms, dates, icons (rhf, zod, date-fns, lucide)"
```

---

## Task 0.12: react-native-reusables — minimal Button + Text primitives

**Files:**
- Create: `src/ui/primitives/text.tsx`
- Create: `src/ui/primitives/button.tsx`
- Create: `src/lib/cn.ts`

> We don't run the react-native-reusables CLI here. Those primitives are small; we copy/adapt them inline so you can read the code in this repo. We add more primitives in Phase 2 and beyond as needed.

- [ ] **Step 1: Install class-variance-authority and clsx (used by primitives)**

```powershell
pnpm add class-variance-authority clsx tailwind-merge
```

- [ ] **Step 2: Create the `cn` helper**

```ts
// src/lib/cn.ts
import { type ClassValue, clsx } from 'clsx';
import { twMerge } from 'tailwind-merge';

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}
```

- [ ] **Step 3: Create the Text primitive**

```tsx
// src/ui/primitives/text.tsx
import { Text as RNText, type TextProps as RNTextProps } from 'react-native';
import { cn } from '@/lib/cn';

interface Props extends RNTextProps {
  className?: string;
}

export function Text({ className, ...rest }: Props) {
  return <RNText className={cn('text-foreground', className)} {...rest} />;
}
```

- [ ] **Step 4: Create the Button primitive**

```tsx
// src/ui/primitives/button.tsx
import type { ReactNode } from 'react';
import { ActivityIndicator, View } from 'react-native';
import { cva, type VariantProps } from 'class-variance-authority';
import { PressScale } from '@/ui/motion/press-scale';
import { haptics } from '@/ui/motion/haptics';
import { cn } from '@/lib/cn';
import { Text } from './text';

const buttonVariants = cva(
  'flex-row items-center justify-center rounded-2xl px-5 py-3',
  {
    variants: {
      variant: {
        primary: 'bg-primary',
        secondary: 'bg-muted',
        ghost: 'bg-transparent',
        danger: 'bg-danger',
      },
      size: {
        sm: 'px-3 py-2',
        md: 'px-5 py-3',
        lg: 'px-6 py-4',
      },
    },
    defaultVariants: { variant: 'primary', size: 'md' },
  }
);

const labelVariants = cva('font-semibold', {
  variants: {
    variant: {
      primary: 'text-primary-foreground',
      secondary: 'text-foreground',
      ghost: 'text-foreground',
      danger: 'text-danger-foreground',
    },
    size: {
      sm: 'text-sm',
      md: 'text-base',
      lg: 'text-lg',
    },
  },
  defaultVariants: { variant: 'primary', size: 'md' },
});

interface Props extends VariantProps<typeof buttonVariants> {
  children: ReactNode;
  onPress?: () => void;
  disabled?: boolean;
  loading?: boolean;
  className?: string;
  hapticOnPress?: boolean;
}

export function Button({
  children,
  onPress,
  disabled,
  loading,
  className,
  variant,
  size,
  hapticOnPress = true,
}: Props) {
  const handlePress = () => {
    if (disabled || loading) return;
    if (hapticOnPress) void haptics.selection();
    onPress?.();
  };

  return (
    <PressScale
      onPress={handlePress}
      disabled={disabled || loading}
      className={cn(
        buttonVariants({ variant, size }),
        (disabled || loading) && 'opacity-60',
        className
      )}
    >
      {loading ? (
        <ActivityIndicator />
      ) : typeof children === 'string' ? (
        <Text className={labelVariants({ variant, size })}>{children}</Text>
      ) : (
        <View className="flex-row items-center gap-2">{children}</View>
      )}
    </PressScale>
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
git commit -m "feat(ui): button + text primitives with press-scale and haptics"
```

---

## Task 0.13: Hello screen with theme toggle and haptic test

**Files:**
- Modify: `app/index.tsx`

- [ ] **Step 1: Replace the contents of `app/index.tsx`**

```tsx
// app/index.tsx
import { View } from 'react-native';
import { useTranslation } from 'react-i18next';
import { Sun, Moon, Vibrate } from 'lucide-react-native';
import { Button } from '@/ui/primitives/button';
import { Text } from '@/ui/primitives/text';
import { useThemeStore, type ThemeMode } from '@/state/stores/theme-store';
import { haptics } from '@/ui/motion/haptics';

const NEXT_MODE: Record<ThemeMode, ThemeMode> = {
  system: 'light',
  light: 'dark',
  dark: 'system',
};

export default function Index() {
  const { t } = useTranslation();
  const mode = useThemeStore((s) => s.mode);
  const setMode = useThemeStore((s) => s.setMode);

  return (
    <View className="flex-1 bg-background items-center justify-center px-6">
      <Text className="text-3xl font-bold text-foreground">
        {t('hello.title')}
      </Text>
      <Text className="text-base text-muted-foreground mt-2 text-center">
        {t('hello.subtitle')}
      </Text>

      <View className="mt-12 gap-4 w-full max-w-xs">
        <Button onPress={() => setMode(NEXT_MODE[mode])}>
          {mode === 'dark' ? <Sun size={20} color="white" /> : <Moon size={20} color="white" />}
          <Text className="text-primary-foreground font-semibold">
            {t('hello.toggle_theme')} ({mode})
          </Text>
        </Button>

        <Button variant="secondary" onPress={() => void haptics.success()}>
          <Vibrate size={20} />
          <Text className="font-semibold">{t('hello.test_haptic')}</Text>
        </Button>
      </View>
    </View>
  );
}
```

- [ ] **Step 2: Verify typecheck**

```powershell
pnpm typecheck
```

- [ ] **Step 3: Commit**

```powershell
git add -A
git commit -m "feat(app): hello screen with theme toggle and haptic test"
```

---

## Task 0.14: Tabs structure with placeholder screens

**Files:**
- Create: `app/(tabs)/_layout.tsx`
- Create: `app/(tabs)/clients/index.tsx`
- Create: `app/(tabs)/tours/index.tsx`
- Create: `app/(tabs)/proximity/index.tsx`
- Create: `app/(tabs)/map/index.tsx`
- Create: `app/(tabs)/settings/index.tsx`
- Modify: `app/_layout.tsx` (route entry)

> The hello screen at `app/index.tsx` stays for J0 verification. We add the tabs in parallel; once Phase 2 settings is functional, the entry point will redirect to `/(tabs)/clients` (in J3) but for now we navigate manually.

- [ ] **Step 1: Create the tabs layout**

```tsx
// app/(tabs)/_layout.tsx
import { Tabs } from 'expo-router';
import { useTranslation } from 'react-i18next';
import { Users, Route, Search, Map, Settings } from 'lucide-react-native';

export default function TabsLayout() {
  const { t } = useTranslation();
  return (
    <Tabs screenOptions={{ headerShown: false }}>
      <Tabs.Screen
        name="clients/index"
        options={{
          title: t('tabs.clients'),
          tabBarIcon: ({ color, size }) => <Users color={color} size={size} />,
        }}
      />
      <Tabs.Screen
        name="tours/index"
        options={{
          title: t('tabs.tours'),
          tabBarIcon: ({ color, size }) => <Route color={color} size={size} />,
        }}
      />
      <Tabs.Screen
        name="proximity/index"
        options={{
          title: t('tabs.proximity'),
          tabBarIcon: ({ color, size }) => <Search color={color} size={size} />,
        }}
      />
      <Tabs.Screen
        name="map/index"
        options={{
          title: t('tabs.map'),
          tabBarIcon: ({ color, size }) => <Map color={color} size={size} />,
        }}
      />
      <Tabs.Screen
        name="settings/index"
        options={{
          title: t('tabs.settings'),
          tabBarIcon: ({ color, size }) => <Settings color={color} size={size} />,
        }}
      />
    </Tabs>
  );
}
```

- [ ] **Step 2: Create five placeholder screens**

```tsx
// app/(tabs)/clients/index.tsx
import { View } from 'react-native';
import { Text } from '@/ui/primitives/text';

export default function ClientsScreen() {
  return (
    <View className="flex-1 bg-background items-center justify-center">
      <Text className="text-foreground">Clients (J3)</Text>
    </View>
  );
}
```

Repeat with the obvious adjustments for `tours/index.tsx` (`Tournées (J6)`), `proximity/index.tsx` (`Proximité (J5)`), `map/index.tsx` (`Carte (J4)`), `settings/index.tsx` (`Réglages (J2)`).

- [ ] **Step 3: Verify typecheck**

```powershell
pnpm typecheck
```

- [ ] **Step 4: Commit**

```powershell
git add -A
git commit -m "feat(nav): tabs layout with placeholder screens"
```

---

## Task 0.15: Vitest setup for pure-TS domain tests

**Files:**
- Create: `vitest.config.ts`
- Create: `tests/domain/sample.test.ts`

- [ ] **Step 1: Install vitest**

```powershell
pnpm add -D vitest
```

- [ ] **Step 2: Create `vitest.config.ts`**

```ts
import { defineConfig } from 'vitest/config';
import path from 'node:path';

export default defineConfig({
  test: {
    include: ['tests/domain/**/*.test.ts'],
    environment: 'node',
  },
  resolve: {
    alias: {
      '@': path.resolve(__dirname, 'src'),
    },
  },
});
```

- [ ] **Step 3: Write a sample passing test (will be replaced by real tests in Phase 1)**

```ts
// tests/domain/sample.test.ts
import { describe, it, expect } from 'vitest';

describe('vitest smoke test', () => {
  it('runs', () => {
    expect(1 + 1).toBe(2);
  });
});
```

- [ ] **Step 4: Run vitest**

```powershell
pnpm vitest run
```

Expected: 1 passing test.

- [ ] **Step 5: Commit**

```powershell
git add -A
git commit -m "test(domain): vitest setup with sample passing test"
```

---

## Task 0.16: Jest + React Native Testing Library setup

**Files:**
- Create: `jest.config.js`
- Create: `jest.setup.js`
- Create: `tests/data/sample.test.ts`
- Modify: `package.json`

- [ ] **Step 1: Install jest, jest-expo preset, RNTL, and types**

```powershell
pnpm add -D jest jest-expo @testing-library/react-native @types/jest
```

- [ ] **Step 2: Create `jest.config.js`**

```js
module.exports = {
  preset: 'jest-expo',
  setupFilesAfterEach: ['<rootDir>/jest.setup.js'],
  testMatch: ['<rootDir>/tests/(data|infra|ui)/**/*.test.{ts,tsx}'],
  moduleNameMapper: {
    '^@/(.*)$': '<rootDir>/src/$1',
    '^@app/(.*)$': '<rootDir>/app/$1',
  },
  transformIgnorePatterns: [
    'node_modules/(?!((jest-)?react-native|@react-native(-community)?|expo(nent)?|@expo(nent)?/.*|@expo-google-fonts/.*|react-navigation|@react-navigation/.*|@unimodules/.*|unimodules|sentry-expo|native-base|nativewind|react-native-svg|@maplibre)/?)',
  ],
};
```

- [ ] **Step 3: Create `jest.setup.js`**

```js
// Hooks for jest setup. Empty for now; populated when needed.
```

- [ ] **Step 4: Sample passing test in jest scope**

```ts
// tests/data/sample.test.ts
describe('jest smoke test', () => {
  it('runs', () => {
    expect(1 + 1).toBe(2);
  });
});
```

- [ ] **Step 5: Run jest**

```powershell
pnpm jest
```

Expected: 1 passing test.

- [ ] **Step 6: Run the full test command**

```powershell
pnpm test
```

Expected: vitest passes (1 test) AND jest passes (1 test).

- [ ] **Step 7: Commit**

```powershell
git add -A
git commit -m "test: jest + react native testing library setup"
```

---

## Task 0.17: ESLint + Prettier verification

**Files:**
- May modify: `eslint.config.js` or `.eslintrc.*` (whatever the Expo template generated)
- Create: `.prettierrc.json`

- [ ] **Step 1: Install Prettier**

```powershell
pnpm add -D prettier prettier-plugin-tailwindcss
```

- [ ] **Step 2: Create `.prettierrc.json`**

```json
{
  "semi": true,
  "singleQuote": true,
  "trailingComma": "all",
  "printWidth": 100,
  "plugins": ["prettier-plugin-tailwindcss"]
}
```

- [ ] **Step 3: Run lint to confirm Expo's default config works**

```powershell
pnpm lint
```

Expected: no errors. If errors are reported on generated/template files, fix by removing the offending unused files (the Expo template sometimes ships demo files we don't keep).

- [ ] **Step 4: Commit**

```powershell
git add -A
git commit -m "chore: prettier config with tailwindcss plugin"
```

---

## Task 0.18: app.json — scheme, bundle IDs, plugins for native modules

**Files:**
- Modify: `app.json`

- [ ] **Step 1: Replace the `expo` block of `app.json` with**

```json
{
  "expo": {
    "name": "Coupe-laine",
    "slug": "coupe-laine",
    "version": "0.0.1",
    "orientation": "portrait",
    "icon": "./assets/icon.png",
    "scheme": "coupelaine",
    "userInterfaceStyle": "automatic",
    "newArchEnabled": true,
    "splash": {
      "image": "./assets/splash.png",
      "resizeMode": "contain",
      "backgroundColor": "#FAF6F0"
    },
    "assetBundlePatterns": ["**/*"],
    "ios": {
      "supportsTablet": true,
      "bundleIdentifier": "fr.coupelaine.app",
      "infoPlist": {
        "NSLocationWhenInUseUsageDescription": "Pour centrer la carte sur votre position."
      }
    },
    "android": {
      "package": "fr.coupelaine.app",
      "adaptiveIcon": {
        "foregroundImage": "./assets/adaptive-icon.png",
        "backgroundColor": "#FAF6F0"
      },
      "permissions": ["ACCESS_COARSE_LOCATION", "ACCESS_FINE_LOCATION"]
    },
    "plugins": ["expo-router", "expo-sqlite", "expo-secure-store"],
    "experiments": {
      "typedRoutes": true
    }
  }
}
```

> The `assets/icon.png`, `assets/splash.png`, `assets/adaptive-icon.png` references come from the Expo template — they exist as placeholders. Real branding assets are produced in J12.

- [ ] **Step 2: Verify typecheck**

```powershell
pnpm typecheck
```

- [ ] **Step 3: Commit**

```powershell
git add -A
git commit -m "chore(expo): app.json with scheme, bundle ids, native plugins"
```

---

## Task 0.19: EAS profiles

**Files:**
- Create: `eas.json`

- [ ] **Step 1: Install EAS CLI globally if not present**

```powershell
pnpm add -g eas-cli
```

> If you've never used EAS, run `eas login` (will prompt for browser auth). You don't need to run it now if you only want to develop locally with the Expo dev client built once.

- [ ] **Step 2: Create `eas.json`**

```json
{
  "cli": {
    "version": ">= 7.0.0"
  },
  "build": {
    "development": {
      "developmentClient": true,
      "distribution": "internal",
      "ios": { "simulator": true },
      "android": { "gradleCommand": ":app:assembleDebug" }
    },
    "preview": {
      "distribution": "internal",
      "ios": { "simulator": false },
      "android": { "buildType": "apk" }
    },
    "production": {
      "autoIncrement": true
    }
  },
  "submit": {
    "production": {}
  }
}
```

- [ ] **Step 3: Commit**

```powershell
git add -A
git commit -m "chore(eas): build profiles for dev / preview / production"
```

---

## Task 0.20: Minimal CI (GitHub Actions)

**Files:**
- Create: `.github/workflows/ci.yml`

- [ ] **Step 1: Create the workflow**

```yaml
name: CI

on:
  push:
    branches: [main, rn-migration]
  pull_request:
    branches: [main]

jobs:
  ci:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
        with:
          version: 9
      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: pnpm
      - run: pnpm install --frozen-lockfile
      - run: pnpm typecheck
      - run: pnpm lint
      - run: pnpm test
        env:
          EXPO_PUBLIC_SUPABASE_URL: https://placeholder.supabase.co
          EXPO_PUBLIC_SUPABASE_ANON_KEY: placeholder
          EXPO_PUBLIC_MAPTILER_API_KEY: placeholder
          EXPO_PUBLIC_ORS_BASE_URL: https://placeholder.supabase.co/functions/v1/ors-proxy
```

- [ ] **Step 2: Commit**

```powershell
git add -A
git commit -m "ci: minimal github actions workflow (typecheck + lint + test)"
```

---

## Task 0.21: Build dev client and verify on iOS + Android

**Files:**
- No file changes; just running the dev client and verifying.

- [ ] **Step 1: Generate native projects (Expo prebuild)**

```powershell
pnpm expo prebuild --clean
```

> This generates `ios/` and `android/` folders. They are gitignored (cf. Task 0.2 .gitignore) — they're treated as build artifacts.

- [ ] **Step 2: Build and run on iOS simulator** (macOS only — if you're on Windows, skip to Step 3 and rely on EAS Build for iOS)

```bash
pnpm ios
```

Expected: iOS Simulator boots, app installs, hello screen renders.

- [ ] **Step 3: Build and run on Android emulator**

Make sure an Android emulator is running (Android Studio → Device Manager → start a device).

```powershell
pnpm android
```

Expected: app builds, installs, hello screen renders on the emulator.

- [ ] **Step 4: Manual verification checklist on emulator/device**

For both platforms (or whichever you have access to):

- [ ] Hello screen shows title "Coupe-laine" and subtitle in French
- [ ] Theme toggle button cycles `system → light → dark → system` (label updates)
- [ ] Visual: when in dark mode, background turns warm dark brown (not pure black)
- [ ] Theme transition is smooth (no flash)
- [ ] Tapping the button shows a brief scale-down on press (PressScale working)
- [ ] "Tester le haptic" button: on physical device, fires a success haptic. On simulator/emulator, no error
- [ ] Tabs at the bottom are visible with French labels and lucide icons (Clients / Tournées / Proximité / Carte / Réglages)
- [ ] Tapping a tab navigates to the placeholder screen for that tab

- [ ] **Step 5: Commit any small fixes from verification**

If you needed to tweak anything (broken import, palette feels too saturated, label clipping), commit the fixes:

```powershell
git add -A
git commit -m "fix: post-bootstrap visual fixes from device verification"
```

If nothing to fix, skip this step.

---

## Task 0.22: Update CLAUDE.md with the new stack

**Files:**
- Modify: `CLAUDE.md`

- [ ] **Step 1: Append a new section to `CLAUDE.md`** documenting the RN stack

Append at the end of the existing `CLAUDE.md`:

```markdown

## 5. RN Stack (post-migration)

This worktree (`rn-migration` branch) targets **iOS + Android** via Expo + React Native, replacing the Flutter app on `main`. See [`docs/superpowers/specs/2026-05-03-migration-expo-rn-design/`](docs/superpowers/specs/2026-05-03-migration-expo-rn-design/README.md) for the full design.

**Quick reference:**
- Package manager: **pnpm** (never npm or yarn)
- Tests: `pnpm test` (vitest for `tests/domain/`, jest for `tests/data/` and `tests/infra/`)
- Typecheck: `pnpm typecheck`
- Lint: `pnpm lint`
- Dev: `pnpm start` (with `--dev-client`)
- DB migrations: `pnpm db:generate` (Drizzle)

**Conventions:**
- All durations and easings via `motion-tokens.ts`. No `ms: 250` literals in components.
- All pressables use `<PressScale>`. All critical actions trigger haptics from `@/ui/motion/haptics`.
- All strings via `t('...')` (i18next). No FR strings in JSX.
- TS strict mode is enforced. No `any`. Use `unknown` + narrowing or proper types.
```

- [ ] **Step 2: Commit**

```powershell
git add CLAUDE.md
git commit -m "docs(claude): document rn stack and conventions"
```

---

## Phase 0 — End checklist

- [ ] Worktree at `C:\Users\rapha\Documents\Development\coupe-laine-rn` on branch `rn-migration`
- [ ] Tag `flutter-final-v0.7.0` on the last Flutter commit of `main`
- [ ] `pnpm typecheck` clean
- [ ] `pnpm lint` clean
- [ ] `pnpm test` green (vitest + jest sample tests pass)
- [ ] Hello screen renders on Android emulator (and iOS sim if on macOS)
- [ ] Theme toggle works with smooth transition
- [ ] Haptic test fires on physical device
- [ ] Tabs render with French labels and lucide icons
- [ ] CLAUDE.md updated with the new stack reference

**You're ready for Phase 1.** Move to [`01-persistence-domain.md`](./01-persistence-domain.md).
