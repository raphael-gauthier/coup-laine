# RGPD MVP — Suppression compte cloud + export portabilité (Section C) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Permettre à l'utilisateur de supprimer définitivement son compte cloud (backups + identité Supabase Auth) en 1 clic depuis Réglages → Cloud, et de télécharger toutes ses données (snapshot JSON) via le share-sheet natif.

**Architecture:** Nouvelle Edge Function Supabase `delete-account` qui vérifie le JWT utilisateur, supprime tous les backups Storage + l'identité Auth (via `auth.admin.deleteUser` avec `service_role` key). Côté app, nouvelle mutation react-query `useDeleteAccount` qui orchestre EF → wipe local → re-bootstrap → nouvelle session anonyme. L'export portabilité utilise les helpers existants (`createBackup` + download Storage) couplés à `expo-file-system` + `expo-sharing` (nouvelles deps).

**Tech Stack:** TypeScript, Deno (Edge Function), Supabase JS SDK (admin + user), `@tanstack/react-query`, `expo-file-system`, `expo-sharing`, jest (`tests/infra`).

---

## Spec reference

Implements Section C de `docs/superpowers/specs/2026-05-06-rgpd-mvp-design.md`. Re-lire la spec si quelque chose ci-dessous est flou.

## Conventions (from CLAUDE.md)

- Package manager : **pnpm**.
- Tous identifiants / chemins / clés i18n en **anglais**. Le français vit uniquement dans `src/i18n/locales/fr.json` (valeurs).
- Tests : `pnpm test:integration` (jest) pour les hooks data/infra, `pnpm test:domain` (vitest) pour la logique pure.
- TS strict, pas de `any`.

## Préalable hors-spec : configurer le secret Supabase

Avant de pouvoir tester l'Edge Function en environnement réel, ajouter le secret **`SUPABASE_SERVICE_ROLE_KEY`** dans le dashboard Supabase :
- Dashboard → Project Settings → Edge Functions → Secrets → Add new secret
- Nom : `SUPABASE_SERVICE_ROLE_KEY`
- Valeur : la clé `service_role` (Project Settings → API → `service_role` key, **secret** — ne jamais committer)

Le secret `SUPABASE_URL` est auto-injecté par Supabase Edge Functions (pas besoin de l'ajouter manuellement).

## File structure

### Created

- `supabase/functions/delete-account/index.ts`
- `tests/infra/use-delete-account.test.ts`

### Modified

- `package.json` (ajout deps `expo-file-system` + `expo-sharing`)
- `pnpm-lock.yaml` (auto)
- `src/state/queries/auth.ts` (ajout `useDeleteAccount`)
- `src/state/queries/backups.ts` (ajout `useExportData`)
- `app/(tabs)/settings/cloud.tsx` (ajout 2 boutons + dialog)
- `src/i18n/locales/fr.json` (~10 nouvelles clés)

### Deleted

Aucun.

---

## Task 1 — Installer les dépendances Expo

**Files:**
- Modify: `package.json`, `pnpm-lock.yaml`

- [ ] **Step 1 : Installer `expo-file-system` et `expo-sharing` via Expo CLI**

Run :
```bash
pnpm exec expo install expo-file-system expo-sharing
```

(Le `expo install` choisit la version SDK-compatible automatiquement, contrairement à `pnpm add`.)

- [ ] **Step 2 : Vérifier `package.json`**

Vérifier que `package.json` contient maintenant `"expo-file-system"` et `"expo-sharing"` dans `dependencies`. Versions exactes à laisser telles que choisies par Expo.

- [ ] **Step 3 : Build / typecheck rapide**

Run : `pnpm typecheck`
Expected : OK.

- [ ] **Step 4 : Commit**

```bash
git add package.json pnpm-lock.yaml
git commit -m "feat(rgpd): add expo-file-system and expo-sharing deps"
```

---

## Task 2 — Créer l'Edge Function `delete-account`

**Files:**
- Create: `supabase/functions/delete-account/index.ts`

L'EF reçoit le JWT utilisateur, vérifie l'identité (refus si anonymous), puis exécute 3 étapes idempotentes : remove Storage objects → delete table row → `auth.admin.deleteUser`.

- [ ] **Step 1 : Créer le fichier**

```ts
// supabase/functions/delete-account/index.ts
import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL');
const SERVICE_ROLE = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
const BUCKET = 'backups';

const corsHeaders: HeadersInit = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'authorization, content-type',
};

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }
  if (req.method !== 'POST') {
    return jsonResponse({ error: 'Method not allowed' }, 405);
  }
  if (!SUPABASE_URL || !SERVICE_ROLE) {
    return jsonResponse({ error: 'Server not configured' }, 500);
  }

  const auth = req.headers.get('Authorization');
  if (!auth) {
    return jsonResponse({ error: 'Missing Authorization header' }, 401);
  }

  // 1. Identifier l'utilisateur via son JWT.
  const userClient = createClient(SUPABASE_URL, SERVICE_ROLE, {
    global: { headers: { Authorization: auth } },
    auth: { persistSession: false },
  });
  const { data: userData, error: userErr } = await userClient.auth.getUser();
  if (userErr || !userData.user) {
    return jsonResponse({ error: 'Invalid session' }, 401);
  }
  const user = userData.user;
  if (user.is_anonymous) {
    return jsonResponse({ error: 'Cannot delete anonymous session' }, 403);
  }
  const uid = user.id;

  // 2. Client admin pour les opérations privilégiées.
  const admin = createClient(SUPABASE_URL, SERVICE_ROLE, {
    auth: { persistSession: false },
  });

  // 3. Lister + supprimer tous les objets Storage du dossier {uid}/.
  const { data: files, error: listErr } = await admin.storage.from(BUCKET).list(uid);
  if (listErr) {
    return jsonResponse({ error: `Storage list failed: ${listErr.message}` }, 500);
  }
  if (files && files.length > 0) {
    const paths = files.map((f) => `${uid}/${f.name}`);
    const { error: removeErr } = await admin.storage.from(BUCKET).remove(paths);
    if (removeErr) {
      return jsonResponse({ error: `Storage remove failed: ${removeErr.message}` }, 500);
    }
  }

  // 4. Supprimer la row d'index dans la table `backups` (best-effort).
  // (La table n'existe peut-être pas dans tous les environnements — on ignore les erreurs.)
  await admin.from('backups').delete().eq('user_id', uid).then(() => {}, () => {});

  // 5. Supprimer l'identité Auth.
  const { error: delErr } = await admin.auth.admin.deleteUser(uid);
  if (delErr) {
    return jsonResponse({ error: `Auth delete failed: ${delErr.message}` }, 500);
  }

  return jsonResponse({ ok: true });
});
```

- [ ] **Step 2 : Déployer l'EF**

Run :
```bash
pnpm exec supabase functions deploy delete-account
```

(Si la CLI `supabase` n'est pas installée localement : `pnpm add -D -w supabase` ou installation système.)

Expected : déploiement OK, URL imprimée.

- [ ] **Step 3 : Test manuel via curl**

Récupérer un JWT utilisateur valide depuis la session de l'app (Réglages → Cloud → DevTools / log la session, ou via Supabase dashboard → Auth → Users → impersonate). Sur un utilisateur de test :

```bash
curl -X POST https://<project>.supabase.co/functions/v1/delete-account \
  -H "Authorization: Bearer <user-jwt>" \
  -H "Content-Type: application/json"
```

Expected : `{"ok":true}` + 200. Vérifier dans le dashboard que :
- Le dossier Storage `backups/{uid}/` est vide.
- L'utilisateur n'apparaît plus dans Auth → Users.

Test négatif avec un JWT anonyme : 403 + `Cannot delete anonymous session`.

- [ ] **Step 4 : Commit**

```bash
git add supabase/functions/delete-account/index.ts
git commit -m "feat(rgpd): add delete-account Edge Function (storage + auth purge)"
```

---

## Task 3 — Ajouter `useDeleteAccount` dans `auth.ts`

**Files:**
- Modify: `src/state/queries/auth.ts`

La mutation orchestre : invoke EF → wipe local → re-bootstrap → nouvelle session anonyme.

- [ ] **Step 1 : Ajouter les imports nécessaires**

En tête de `src/state/queries/auth.ts`, ajouter :

```ts
import { ensureAnonymousSession } from '@/infra/services/ensure-session';
```

- [ ] **Step 2 : Ajouter la mutation à la fin du fichier**

Ajouter (après `useSignOut`) :

```ts
export function useDeleteAccount() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async () => {
      const { error } = await supabase.functions.invoke('delete-account', {
        method: 'POST',
      });
      if (error) throw error;

      // L'EF a déjà invalidé l'utilisateur côté Supabase. On nettoie le local.
      await wipeLocalDatabase();
      await bootstrapDatabase();

      // Le sign-out côté SDK est best-effort (le JWT est déjà mort).
      await supabase.auth.signOut().catch(() => {});

      // Repartir sur une session anonyme pour garder ORS proxy fonctionnel.
      await ensureAnonymousSession();
    },
    onSuccess: () => {
      qc.clear();
      qc.setQueryData(authKeys.session, null);
    },
    onError: (err) => {
      mutationErrorToast(i18n.t('cloud.delete_account.error_toast'), err);
    },
  });
}
```

- [ ] **Step 3 : Typecheck**

Run : `pnpm typecheck`
Expected : OK.

- [ ] **Step 4 : Commit**

```bash
git add src/state/queries/auth.ts
git commit -m "feat(rgpd): add useDeleteAccount mutation"
```

---

## Task 4 — Tests pour `useDeleteAccount`

**Files:**
- Create: `tests/infra/use-delete-account.test.ts`

Le hook orchestre 4 appels SDK. On mocke chacun et on vérifie l'enchaînement + la résilience.

- [ ] **Step 1 : Vérifier la convention de tests existante**

Run : `ls tests/infra/`
Expected : voir le pattern jest existant (mocks Supabase, etc.). Si vide, suivre le pattern de `tests/data/`.

Si aucun test infra n'existe, créer le dossier et le fichier directement.

- [ ] **Step 2 : Écrire le test**

Créer `tests/infra/use-delete-account.test.ts` :

```ts
import { renderHook, waitFor } from '@testing-library/react-native';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import React from 'react';

const mockInvoke = jest.fn();
const mockSignOut = jest.fn();
const mockSetSession = jest.fn();
const mockWipe = jest.fn();
const mockBootstrap = jest.fn();
const mockEnsureAnon = jest.fn();

jest.mock('@/infra/services/supabase', () => ({
  supabase: {
    functions: { invoke: (...args: unknown[]) => mockInvoke(...args) },
    auth: {
      signOut: () => mockSignOut(),
      onAuthStateChange: () => ({ data: { subscription: { unsubscribe: () => {} } } }),
      getSession: () => Promise.resolve({ data: { session: null } }),
    },
  },
}));
jest.mock('@/infra/db/wipe', () => ({ wipeLocalDatabase: () => mockWipe() }));
jest.mock('@/infra/db/bootstrap', () => ({ bootstrapDatabase: () => mockBootstrap() }));
jest.mock('@/infra/services/ensure-session', () => ({
  ensureAnonymousSession: () => mockEnsureAnon(),
}));
jest.mock('@/ui/components/error-toast', () => ({
  mutationErrorToast: jest.fn(),
  errorToast: jest.fn(),
  successToast: jest.fn(),
}));
jest.mock('@/i18n', () => ({ default: { t: (k: string) => k } }));

import { useDeleteAccount } from '@/state/queries/auth';

function wrapper({ children }: { children: React.ReactNode }) {
  const qc = new QueryClient({ defaultOptions: { mutations: { retry: false } } });
  return <QueryClientProvider client={qc}>{children}</QueryClientProvider>;
}

beforeEach(() => {
  mockInvoke.mockReset();
  mockSignOut.mockReset();
  mockSetSession.mockReset();
  mockWipe.mockReset();
  mockBootstrap.mockReset();
  mockEnsureAnon.mockReset();
});

describe('useDeleteAccount', () => {
  it('happy path: invokes EF, wipes, bootstraps, ensures anon session', async () => {
    mockInvoke.mockResolvedValue({ data: { ok: true }, error: null });
    mockSignOut.mockResolvedValue({ error: null });
    mockWipe.mockResolvedValue(undefined);
    mockBootstrap.mockResolvedValue(undefined);
    mockEnsureAnon.mockResolvedValue(undefined);

    const { result } = renderHook(() => useDeleteAccount(), { wrapper });
    result.current.mutate();
    await waitFor(() => expect(result.current.isSuccess).toBe(true));

    expect(mockInvoke).toHaveBeenCalledWith('delete-account', { method: 'POST' });
    expect(mockWipe).toHaveBeenCalledTimes(1);
    expect(mockBootstrap).toHaveBeenCalledTimes(1);
    expect(mockEnsureAnon).toHaveBeenCalledTimes(1);
  });

  it('does not wipe local when Edge Function fails', async () => {
    mockInvoke.mockResolvedValue({ data: null, error: new Error('boom') });

    const { result } = renderHook(() => useDeleteAccount(), { wrapper });
    result.current.mutate();
    await waitFor(() => expect(result.current.isError).toBe(true));

    expect(mockWipe).not.toHaveBeenCalled();
    expect(mockBootstrap).not.toHaveBeenCalled();
  });

  it('signOut failure is swallowed (best-effort)', async () => {
    mockInvoke.mockResolvedValue({ data: { ok: true }, error: null });
    mockSignOut.mockRejectedValue(new Error('jwt invalid'));
    mockWipe.mockResolvedValue(undefined);
    mockBootstrap.mockResolvedValue(undefined);
    mockEnsureAnon.mockResolvedValue(undefined);

    const { result } = renderHook(() => useDeleteAccount(), { wrapper });
    result.current.mutate();
    await waitFor(() => expect(result.current.isSuccess).toBe(true));

    expect(mockEnsureAnon).toHaveBeenCalledTimes(1);
  });
});
```

- [ ] **Step 3 : Lancer les tests**

Run : `pnpm test:integration use-delete-account`
Expected : 3 tests verts.

Si jest se plaint de la résolution `@/...`, vérifier `jest.config.js` : il devrait avoir un `moduleNameMapper`. Si manquant, le pattern dans les autres tests `tests/data/*.test.ts` indique le bon mapping à copier.

- [ ] **Step 4 : Commit**

```bash
git add tests/infra/use-delete-account.test.ts
git commit -m "test(rgpd): add tests for useDeleteAccount mutation"
```

---

## Task 5 — Ajouter `useExportData` dans `backups.ts`

**Files:**
- Modify: `src/state/queries/backups.ts`

Crée un backup à la volée (réutilise la mécanique existante), télécharge le JSON depuis Storage, écrit dans un fichier temporaire, ouvre le share-sheet natif.

- [ ] **Step 1 : Lire l'état actuel du fichier**

Run : `pnpm exec cat src/state/queries/backups.ts | head -40` (ou Read tool) pour voir les imports et le pattern.

- [ ] **Step 2 : Ajouter les imports en tête**

```ts
import * as FileSystem from 'expo-file-system';
import * as Sharing from 'expo-sharing';
import { supabase } from '@/infra/services/supabase';
```

(Le client `supabase` est probablement déjà importé — ne pas dupliquer.)

- [ ] **Step 3 : Ajouter la mutation**

À la fin du fichier (après les autres `useXxx` exports) :

```ts
const BUCKET = 'backups';

export function useExportData() {
  return useMutation({
    mutationFn: async () => {
      const { data: { session } } = await supabase.auth.getSession();
      if (!session?.user.id || session.user.is_anonymous) {
        throw new Error('Not signed in');
      }
      const uid = session.user.id;

      // 1. Crée un backup frais (réutilise createBackup déjà exporté par cloud/backups.ts).
      const path = await createBackup();

      // 2. Télécharge le snapshot JSON depuis Storage.
      const { data, error } = await supabase.storage.from(BUCKET).download(path);
      if (error) throw error;
      const jsonText = await data.text();

      // 3. Écrit dans un fichier temporaire.
      const filename = `coup-laine-export-${new Date().toISOString().replace(/[:.]/g, '-')}.json`;
      const fileUri = `${FileSystem.cacheDirectory}${filename}`;
      await FileSystem.writeAsStringAsync(fileUri, jsonText, {
        encoding: FileSystem.EncodingType.UTF8,
      });

      // 4. Ouvre le share-sheet natif.
      const available = await Sharing.isAvailableAsync();
      if (!available) {
        throw new Error('Sharing not available on this platform');
      }
      await Sharing.shareAsync(fileUri, {
        mimeType: 'application/json',
        dialogTitle: 'Exporter mes données',
        UTI: 'public.json',
      });
    },
    onError: (err) => {
      mutationErrorToast(i18n.t('cloud.export_data.error_toast'), err);
    },
  });
}
```

(Si `createBackup` n'est pas déjà exporté du module local : ajouter l'import en tête : `import { createBackup } from '@/infra/cloud/backups';`. `mutationErrorToast` et `i18n` doivent aussi être importés s'ils ne le sont pas déjà.)

- [ ] **Step 4 : Typecheck**

Run : `pnpm typecheck`
Expected : OK.

- [ ] **Step 5 : Commit**

```bash
git add src/state/queries/backups.ts
git commit -m "feat(rgpd): add useExportData hook (download + share JSON snapshot)"
```

---

## Task 6 — Ajouter les clés i18n

**Files:**
- Modify: `src/i18n/locales/fr.json`

- [ ] **Step 1 : Ajouter les clés sous `cloud.*`**

Dans `src/i18n/locales/fr.json`, à l'intérieur de l'objet `cloud` (à côté de `row_label`, `row_hint_logged_out`, etc.), ajouter :

```json
"export_data": {
  "cta": "Télécharger mes données",
  "loading": "Préparation de l'export…",
  "error_toast": "Export impossible"
},
"danger_section_title": "Zone de danger",
"delete_account": {
  "cta": "Supprimer mon compte cloud",
  "confirm_title": "Supprimer définitivement votre compte ?",
  "confirm_message": "Cette action est irréversible. Tous vos backups cloud seront supprimés (vos données locales sur cet appareil aussi). Vous pourrez recréer un compte plus tard, mais sans pouvoir restaurer ce qui aura été effacé.",
  "typed_word": "SUPPRIMER",
  "cta_confirm": "Supprimer mon compte",
  "success_toast": "Votre compte cloud a été supprimé.",
  "error_toast": "Suppression impossible"
}
```

- [ ] **Step 2 : Vérifier le JSON**

Run : `node -e "JSON.parse(require('fs').readFileSync('src/i18n/locales/fr.json','utf-8'))"`
Expected : aucune sortie (parse OK).

- [ ] **Step 3 : Commit**

```bash
git add src/i18n/locales/fr.json
git commit -m "feat(rgpd): add i18n keys for cloud delete account + export"
```

---

## Task 7 — Brancher les boutons dans `cloud.tsx`

**Files:**
- Modify: `app/(tabs)/settings/cloud.tsx`

Deux ajouts : bouton « Télécharger mes données » au-dessus de la zone de danger, et zone de danger avec bouton « Supprimer mon compte cloud » + dialog typé.

- [ ] **Step 1 : Ajouter les imports**

En tête de `app/(tabs)/settings/cloud.tsx`, ajouter :

```tsx
import { Download, AlertTriangle } from 'lucide-react-native';
import { SectionHeader } from '@/ui/primitives/section-header';
import { useDeleteAccount } from '@/state/queries/auth';
import { useExportData } from '@/state/queries/backups';
```

(Les imports déjà présents — `Surface`, `Button`, `ConfirmTypedDialog`, `useSession`, `useSignOut`, etc. — restent inchangés.)

- [ ] **Step 2 : Ajouter les hooks en haut du composant**

À l'intérieur de `CloudScreen()`, après les hooks existants (`signOut`, `create`, etc.) :

```tsx
const exportData = useExportData();
const deleteAccount = useDeleteAccount();
const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
```

- [ ] **Step 3 : Ajouter les handlers**

Toujours dans le composant, après les handlers existants :

```tsx
const onExport = () => {
  exportData.mutate(undefined, {
    onSuccess: () => {
      successToast(t('cloud.export_data.cta'));
    },
  });
};

const handleDeleteConfirmed = () => {
  setDeleteDialogOpen(false);
  deleteAccount.mutate(undefined, {
    onSuccess: () => {
      successToast(t('cloud.delete_account.success_toast'));
      router.replace('/onboarding/welcome' as never);
    },
  });
};
```

- [ ] **Step 4 : Insérer le ConfirmTypedDialog pour la suppression**

À côté du `<ConfirmTypedDialog>` existant pour le restore, ajouter :

```tsx
<ConfirmTypedDialog
  visible={deleteDialogOpen}
  title={t('cloud.delete_account.confirm_title')}
  message={t('cloud.delete_account.confirm_message')}
  typedConfirmation={t('cloud.delete_account.typed_word')}
  confirmLabel={t('cloud.delete_account.cta_confirm')}
  cancelLabel={t('common.cancel')}
  onConfirm={handleDeleteConfirmed}
  onCancel={() => setDeleteDialogOpen(false)}
/>
```

- [ ] **Step 5 : Insérer les boutons dans le ScrollView**

Juste **avant** le bouton « Se déconnecter du cloud » existant (autour de `app/(tabs)/settings/cloud.tsx:170-186`), insérer :

```tsx
<Button
  variant="secondary"
  onPress={onExport}
  loading={exportData.isPending}
  className="mt-4"
>
  <Download size={16} color={fg} />
  <Text className="font-semibold">{t('cloud.export_data.cta')}</Text>
</Button>
```

Puis, **après** le bouton « Se déconnecter du cloud » existant, ajouter la zone de danger :

```tsx
<View className="mt-8">
  <SectionHeader title={t('cloud.danger_section_title')} />
  <Button
    variant="danger"
    onPress={() => setDeleteDialogOpen(true)}
    loading={deleteAccount.isPending}
  >
    <AlertTriangle size={16} color={onContrast} />
    <Text variant="onPrimary" className="font-semibold">
      {t('cloud.delete_account.cta')}
    </Text>
  </Button>
</View>
```

- [ ] **Step 6 : Typecheck + lint**

Run : `pnpm typecheck && pnpm lint`
Expected : OK.

- [ ] **Step 7 : Commit**

```bash
git add app/(tabs)/settings/cloud.tsx
git commit -m "feat(rgpd): add export data + delete account buttons in Cloud settings"
```

---

## Task 8 — Smoke test parcours complet

- [ ] **Step 1 : Tests automatisés**

Run : `pnpm test`
Expected : tous verts.

- [ ] **Step 2 : Typecheck + lint**

Run : `pnpm typecheck && pnpm lint`
Expected : OK.

- [ ] **Step 3 : Test manuel — export portabilité**

Sur device, avec un compte cloud connecté :
1. Réglages → Cloud → bouton « Télécharger mes données »
2. Spinner pendant la création + download
3. Share-sheet natif s'ouvre → save dans Files / envoyer par mail
4. Vérifier que le JSON ouvert contient bien les tables attendues

- [ ] **Step 4 : Test manuel — suppression compte**

Sur device, avec un compte cloud de test (≠ ton compte principal !) :
1. Réglages → Cloud → faire défiler jusqu'à « Zone de danger »
2. Bouton « Supprimer mon compte cloud » → dialog
3. Taper `SUPPRIMER` → bouton actif
4. Confirmer
5. Vérifier : redirigé vers `/onboarding/welcome`, app revient à l'état fresh
6. Dashboard Supabase : utilisateur disparu de Auth → Users, dossier `backups/{uid}/` vide
7. Tenter de re-login avec le même email → fonctionne (création nouvelle identité)

- [ ] **Step 5 : Test manuel — résilience**

1. Avec un mauvais secret `SUPABASE_SERVICE_ROLE_KEY` (volontairement) : retenter la suppression → toast d'erreur, le user reste connecté avec ses backups intacts.
2. Restaurer le bon secret → la suppression fonctionne au retry.

---

## Open questions (pour mémoire — pas bloquantes pour ce plan)

- **Configuration secret `SUPABASE_SERVICE_ROLE_KEY`** : à faire dans le dashboard Supabase **avant** de tester l'EF en réel.
- **Compte de test dédié** pour les tests manuels — éviter de tester sur le compte principal du dev.
- **Téléchargement direct sans backup intermédiaire** (optimisation) : ce plan crée un nouveau backup à chaque export. Si la perf devient un sujet, on pourrait dump localement la DB sans round-trip cloud. Hors scope MVP.
