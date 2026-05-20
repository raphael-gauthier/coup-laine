# Saisie en série de clients — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fluidifier la saisie en série de clients (onboarding) en supprimant les retours-liste : atterrissage direct sur la fiche après création, bannière « nouveau client » contextuelle, et bouton « enregistrer et ajouter une autre » sur le formulaire d'intervention.

**Architecture:** Approche A (recâblage de la navigation existante, aucun parcours parallèle). On modifie 3 écrans Expo Router et 1 composant de formulaire, on ajoute 3 clés i18n. Aucun changement de modèle de données, de schéma DB, ni de couche domaine/data.

**Tech Stack:** Expo Router, React Native, react-hook-form + zod, TanStack Query (`useMutation` / `mutateAsync`), i18next, NativeWind.

**Spec:** `docs/superpowers/specs/2026-05-20-batch-client-entry-design.md`

**Verification note:** Il n'existe pas de harnais de test de composants pour `app/` ou `src/ui` (seul `tests/infra/use-delete-account.test.tsx` teste un hook). Ces changements sont purement UI/navigation. La vérification de chaque tâche se fait via `pnpm typecheck` + `pnpm lint`, puis une vérification manuelle finale sur le dev client (Task 5) contre les critères de la spec. Commits fréquents par tâche.

---

### Task 1: Clés i18n

**Files:**
- Modify: `src/i18n/locales/fr.json` (section `clients` autour de la ligne 52 ; section `history.manual` autour de la ligne 387)

- [ ] **Step 1: Ajouter les 2 clés de bannière dans la section `clients`**

Dans `src/i18n/locales/fr.json`, juste après la ligne `"detail_title": "Client",` (ligne ~52), ajouter :

```json
    "just_created_banner_title": "Client enregistré",
    "just_created_banner_cta": "Ajouter un autre client",
```

- [ ] **Step 2: Ajouter la clé du bouton dans la section `history.manual`**

Dans la section `"manual": { ... }` (objet commençant ligne ~373), après `"edit_services": "Modifier les prestations",` (ligne ~387), ajouter :

```json
      "save_and_add_another": "Enregistrer et ajouter une autre",
```

- [ ] **Step 3: Vérifier que le JSON est valide**

Run: `pnpm typecheck`
Expected: PASS (le JSON est importé en TS ; une virgule manquante ou un JSON cassé fait échouer le typecheck/parsing). Si une erreur de parsing JSON apparaît, corriger les virgules.

- [ ] **Step 4: Commit**

```bash
git add src/i18n/locales/fr.json
git commit -m "i18n(clients): add batch-entry banner and save-and-add-another keys"
```

---

### Task 2: Redirection vers la fiche après création d'un client

**Files:**
- Modify: `app/(tabs)/clients/new.tsx`

- [ ] **Step 1: Rediriger vers la fiche au lieu de revenir à la liste**

Dans `app/(tabs)/clients/new.tsx`, remplacer le `onSuccess` actuel (qui fait `router.back()`) par une redirection vers la fiche du client créé avec le flag `justCreated`. Le contenu complet du fichier devient :

```tsx
import { Stack, useRouter } from 'expo-router';
import { useTranslation } from 'react-i18next';
import { Surface } from '@/ui/primitives/surface';
import { ScreenHeader } from '@/ui/components/screen-header';
import { ClientForm } from '@/ui/components/client-form';
import { useUpsertClient } from '@/state/queries/clients';
import { haptics } from '@/ui/motion/haptics';
import { mutationErrorToast } from '@/ui/components/error-toast';

export default function NewClientScreen() {
  const { t } = useTranslation();
  const router = useRouter();
  const upsert = useUpsertClient();

  return (
    <Surface className="flex-1">
      <Stack.Screen options={{ presentation: 'modal' }} />
      <ScreenHeader title={t('clients.new_title')} />

      <ClientForm
        saving={upsert.isPending}
        onCancel={() => router.back()}
        onSubmit={(input) =>
          upsert.mutate(input, {
            onSuccess: (client) => {
              void haptics.success();
              router.replace({
                pathname: '/(tabs)/clients/[id]',
                params: { id: client.id, justCreated: '1' },
              });
            },
            onError: (err) => {
              mutationErrorToast(t('clients.save_failed_title'), err);
            },
          })
        }
      />
    </Surface>
  );
}
```

- [ ] **Step 2: Typecheck + lint**

Run: `pnpm typecheck && pnpm lint`
Expected: PASS. (`onSuccess` reçoit bien `client` — `useUpsertClient.mutationFn` retourne le `Client` complet, cf. `src/state/queries/clients.ts:96`.)

- [ ] **Step 3: Commit**

```bash
git add "app/(tabs)/clients/new.tsx"
git commit -m "feat(clients): land on client detail after creation"
```

---

### Task 3: Bannière contextuelle « Nouveau client » sur la fiche

**Files:**
- Modify: `app/(tabs)/clients/[id].tsx`

Le composant lit déjà `id` via `useLocalSearchParams<{ id: string }>()` (ligne 53). On élargit ce type pour lire `justCreated`, et on insère une bannière en tête du `ScrollView`.

- [ ] **Step 1: Lire le paramètre `justCreated`**

Dans `app/(tabs)/clients/[id].tsx`, remplacer la ligne 53 :

```tsx
  const { id } = useLocalSearchParams<{ id: string }>();
```

par :

```tsx
  const { id, justCreated } = useLocalSearchParams<{ id: string; justCreated?: string }>();
```

- [ ] **Step 2: Ajouter l'icône `Plus` à l'import lucide existant**

Dans le bloc d'import depuis `lucide-react-native` (lignes 4-11), ajouter `Plus` à la liste (ordre alphabétique respecté autour de `Pencil`) :

```tsx
import {
  Ban,
  ChevronRight,
  MoreVertical,
  Pencil,
  Plus,
  Search,
  Trash2,
} from 'lucide-react-native';
```

- [ ] **Step 3: Insérer la bannière en tête du ScrollView**

Dans le `ScrollView` (ouvert ligne 186), juste avant `<Text className="text-2xl font-bold">{client.displayName}</Text>` (ligne 187), insérer :

```tsx
        {justCreated === '1' ? (
          <PressScale
            onPress={() => router.push('/(tabs)/clients/new')}
            accessibilityLabel={t('clients.just_created_banner_cta')}
          >
            <Surface variant="muted" className="flex-row items-center rounded-2xl px-4 py-3 gap-3">
              <View className="flex-1">
                <Text className="text-sm font-medium">{t('clients.just_created_banner_title')}</Text>
                <Text variant="muted" className="text-xs mt-0.5">
                  {t('clients.just_created_banner_cta')}
                </Text>
              </View>
              <Plus size={18} color={fg} />
            </Surface>
          </PressScale>
        ) : null}
```

(`PressScale`, `Surface`, `Text`, `View`, `router`, `t` et `fg` sont déjà importés/définis dans ce fichier — cf. lignes 31, 14-16, 56.)

- [ ] **Step 4: Typecheck + lint**

Run: `pnpm typecheck && pnpm lint`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add "app/(tabs)/clients/[id].tsx"
git commit -m "feat(clients): show add-another-client banner after creation"
```

---

### Task 4: « Enregistrer et ajouter une autre » sur le formulaire d'intervention

**Files:**
- Modify: `src/ui/components/manual-history-form.tsx`
- Modify: `app/(tabs)/clients/[id]/history/new.tsx`

Le formulaire gagne une prop `allowAddAnother`, sa signature `onSubmit` reçoit `{ addAnother }`, et il se réinitialise après une soumission réussie en mode « ajouter une autre ». L'écran de création câble `mutateAsync` et ne ferme le modal que si `addAnother` est faux. L'écran d'édition (`[entryId].tsx`) n'est **pas** modifié (il ne passe pas `allowAddAnother`, et sa lambda `onSubmit` à un seul argument reste compatible avec la nouvelle signature optionnelle).

- [ ] **Step 1: Modifier l'interface `Props` et la signature `onSubmit` du formulaire**

Dans `src/ui/components/manual-history-form.tsx`, remplacer l'interface `Props` (lignes 28-34) par :

```tsx
interface Props {
  initial?: ManualHistoryEntry;
  clientId: string;
  saving?: boolean;
  allowAddAnother?: boolean;
  onSubmit: (input: UpsertManualHistoryInput, opts: { addAnother: boolean }) => void | Promise<void>;
  onCancel?: () => void;
}
```

- [ ] **Step 2: Récupérer `reset` du form et destructurer la nouvelle prop**

Remplacer la signature de la fonction (ligne 46) et la destructuration de `useForm` (ligne 48) :

```tsx
export function ManualHistoryForm({ initial, clientId, saving, allowAddAnother, onSubmit, onCancel }: Props) {
  const { t } = useTranslation();
  const { control, handleSubmit, reset } = useForm<FormValues>({
```

- [ ] **Step 3: Rendre `onValid` capable de réinitialiser, et factoriser la construction de l'input**

Remplacer la fonction `onValid` (lignes 73-91) par une version qui prend l'option `addAnother`, `await` la soumission, et réinitialise tous les états en cas de succès :

```tsx
  const buildInput = (values: FormValues): UpsertManualHistoryInput => ({
    id: initial?.id,
    clientId,
    date: format(values.date, 'yyyy-MM-dd'),
    notes: values.notes.trim() || null,
    services,
    travelFeeCents: travelFeeCents > 0 ? travelFeeCents : null,
    payment,
  });

  const submit = (addAnother: boolean) =>
    handleSubmit(async (values) => {
      // Method always required for manual history (per spec asymmetry)
      if (!payment.methodId) {
        setMethodError(t('payments.method_required'));
        void haptics.error();
        return;
      }
      setMethodError(null);

      try {
        await onSubmit(buildInput(values), { addAnother });
      } catch {
        // Mutation failed (handled upstream via toast); keep the form intact.
        return;
      }

      if (addAnother) {
        reset({ date: new Date(), notes: '' });
        setServices([]);
        setTravelFeeCents(0);
        setPayment({ ...EMPTY_PAYMENT, isPaid: true });
        setMethodError(null);
      }
    }, onInvalid);
```

- [ ] **Step 4: Brancher les boutons sur `submit(...)`**

Remplacer le bloc de boutons (lignes 196-205) par :

```tsx
      <View className="flex-row gap-2 mt-4">
        {onCancel ? (
          <Button variant="secondary" className="flex-1" onPress={onCancel} disabled={saving}>
            {t('common.cancel')}
          </Button>
        ) : null}
        <Button className="flex-1" onPress={submit(false)} loading={saving}>
          {t('common.save')}
        </Button>
      </View>

      {allowAddAnother ? (
        <Button variant="secondary" onPress={submit(true)} disabled={saving}>
          {t('history.manual.save_and_add_another')}
        </Button>
      ) : null}
```

- [ ] **Step 5: Câbler l'écran de création sur `mutateAsync` + `allowAddAnother`**

Remplacer le contenu de `app/(tabs)/clients/[id]/history/new.tsx` par :

```tsx
import { Stack, useLocalSearchParams, useRouter } from 'expo-router';
import { useTranslation } from 'react-i18next';
import { Surface } from '@/ui/primitives/surface';
import { ScreenHeader } from '@/ui/components/screen-header';
import { ManualHistoryForm } from '@/ui/components/manual-history-form';
import { useUpsertManualHistoryEntry } from '@/state/queries/history';
import { haptics } from '@/ui/motion/haptics';
import { mutationErrorToast } from '@/ui/components/error-toast';

export default function NewManualHistoryScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const router = useRouter();
  const { t } = useTranslation();
  const upsert = useUpsertManualHistoryEntry();
  return (
    <Surface className="flex-1">
      <Stack.Screen options={{ presentation: 'modal' }} />
      <ScreenHeader title={t('history.manual.new_title')} />
      <ManualHistoryForm
        clientId={id}
        saving={upsert.isPending}
        allowAddAnother
        onCancel={() => router.back()}
        onSubmit={async (input, { addAnother }) => {
          try {
            await upsert.mutateAsync(input);
          } catch (err) {
            mutationErrorToast(t('history.errors.save_failed_title'), err);
            throw err;
          }
          void haptics.success();
          if (!addAnother) router.back();
        }}
      />
    </Surface>
  );
}
```

(La clé `history.errors.save_failed_title` existe déjà — cf. `src/i18n/locales/fr.json:394`.)

- [ ] **Step 6: Typecheck + lint**

Run: `pnpm typecheck && pnpm lint`
Expected: PASS. Vérifier en particulier qu'aucun import n'est devenu inutilisé dans `manual-history-form.tsx` (`EMPTY_PAYMENT`, `format` et `UpsertManualHistoryInput` restent utilisés).

- [ ] **Step 7: Commit**

```bash
git add "src/ui/components/manual-history-form.tsx" "app/(tabs)/clients/[id]/history/new.tsx"
git commit -m "feat(history): add save-and-add-another to manual intervention form"
```

---

### Task 5: Vérification manuelle sur le dev client

**Files:** aucun (vérification comportementale contre la spec).

- [ ] **Step 1: Lancer le dev client**

Run: `pnpm start` (avec `--dev-client`), ouvrir l'app sur une DB peuplée.

- [ ] **Step 2: Boucle externe — atterrissage + bannière**

- Liste clients → FAB « + » → remplir → « Enregistrer ».
- Attendu : on atterrit **directement sur la fiche** du client créé (et **pas** en présentation modal — si la fiche apparaît en modal, appliquer le repli : remplacer `router.replace(...)` de Task 2 par `router.dismiss(); router.push({ pathname: '/(tabs)/clients/[id]', params: { id: client.id, justCreated: '1' } });`).
- Attendu : la bannière « Client enregistré — Ajouter un autre client » est visible en haut de la fiche.

- [ ] **Step 3: Boucle externe — enchaînement**

- Depuis la bannière, taper « Ajouter un autre client » → modal de création → enregistrer → nouvelle fiche **avec bannière**. Vérifier sur ≥ 2 itérations.

- [ ] **Step 4: Boucle interne — ajouter une autre intervention**

- Sur une fiche, ajouter une intervention → renseigner date/prestations/**mode de paiement** → « Enregistrer et ajouter une autre ».
- Attendu : le formulaire redevient **vierge** (date = aujourd'hui), le modal **reste ouvert**, et l'intervention précédente est **persistée** (visible dans la liste des interventions après fermeture du modal).
- Refaire avec le bouton « Enregistrer » → attendu : **retour à la fiche**.

- [ ] **Step 5: Non-régressions**

- Éditer un client existant (`✎`) → enregistrer → **pas** de bannière, retour habituel.
- Éditer une intervention existante → **pas** de bouton « ajouter une autre », comportement inchangé.
- Forcer une erreur de mutation d'intervention (ex. couper le réseau si la mutation peut échouer) pendant « ajouter une autre » → attendu : le formulaire **ne se réinitialise pas** et un toast d'erreur s'affiche.

- [ ] **Step 6: Si le repli de Step 2 a été nécessaire, committer le correctif**

```bash
git add "app/(tabs)/clients/new.tsx"
git commit -m "fix(clients): use dismiss+push for post-create navigation"
```
