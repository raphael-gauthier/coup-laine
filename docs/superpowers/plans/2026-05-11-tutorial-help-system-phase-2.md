# Tutorial & Help System Phase 2 — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task.

**Goal:** Ship Phase 2 of the tutorial & help system: extend the catalog with 7 new sheets + 5 discovery coach-marks, introduce the essential/discovery categorization and the at-most-1-discovery-per-session policy, and integrate everything into the existing screens.

**Architecture:** Pure additive extension on Phase 1 infra. Three small new internals (catalog extension with `isEssentialCoachmark`, module-level `session-store`, modified `useCoachMark`) + 7 sheet content components + 3 new demos + 7 `<HelpButton>` integrations + 5 `<CoachMark>` integrations.

**Tech Stack:** Inherited from Phase 1 (React Query, NativeWind, expo-router, lucide icons, i18next FR-only, Reanimated). No new dependency.

**Spec reference:** `docs/superpowers/specs/2026-05-11-tutorial-help-system-phase-2-design.md`
**Phase 1 reference:** `docs/superpowers/specs/2026-05-11-tutorial-help-system-design.md`

---

## File Structure

**New files:**
- `src/ui/help/session-store.ts` — module-level `discoveryFiredThisSession` flag + setters
- `src/ui/help/sheets/help-sheet-map.tsx`
- `src/ui/help/sheets/help-sheet-client-detail.tsx`
- `src/ui/help/sheets/help-sheet-tour-detail.tsx`
- `src/ui/help/sheets/help-sheet-services-catalog.tsx`
- `src/ui/help/sheets/help-sheet-statuses.tsx`
- `src/ui/help/sheets/help-sheet-cloud.tsx`
- `src/ui/help/sheets/help-sheet-settings.tsx`
- `src/ui/help/previews/service-row-demo.tsx`
- `src/ui/help/previews/status-row-demo.tsx`
- `src/ui/help/previews/tour-stop-list-demo.tsx`
- `tests/domain/tutorial/essential.test.ts` — `isEssentialCoachmark` tests
- `tests/domain/tutorial/session-store.test.ts` — session store tests

**Modified files:**
- `src/domain/tutorial/keys.ts` — add 12 new keys + `ESSENTIAL_COACHMARKS` + `isEssentialCoachmark`
- `src/ui/help/hooks.ts` — `useCoachMark` consults `isEssentialCoachmark` + session store
- `src/state/queries/tutorial.ts` — `useResetTutorials.onSuccess` calls `resetSessionDiscoveryFlag()`
- `src/state/queries/tours.ts` (or new `src/state/queries/tour-stops.ts` if cleaner) — add `useHasAnyPaidStop()` hook
- `src/i18n/locales/fr.json` — ~85 new keys
- `app/(tabs)/map/...` — add `<HelpButton>` (path TBD on read)
- `app/(tabs)/clients/[id].tsx` — add `<HelpButton>` for `sheet.client_detail`
- `app/(tabs)/clients/index.tsx` — wire 2 new coach-marks (cloud_backup + manual_statuses) with priority chain
- `app/(tabs)/tours/[id].tsx` — add `<HelpButton>` for `sheet.tour_detail`
- `app/(tabs)/tours/index.tsx` — wire `coachmark.discover_catalog`
- `app/(tabs)/tours/[id]/complete.tsx` — wire `coachmark.payment_methods`
- `app/(tabs)/settings/services/index.tsx` — add `<HelpButton>` for `sheet.services_catalog`
- `app/(tabs)/settings/statuses.tsx` — add `<HelpButton>` for `sheet.statuses`
- `app/(tabs)/settings/cloud.tsx` — add `<HelpButton>` for `sheet.cloud`
- `app/(tabs)/settings/index.tsx` — add `<HelpButton>` for `sheet.settings`
- TourDraft screen (path TBD on read — likely `app/(tabs)/tours/new.tsx` or similar) — wire `coachmark.proximity_suggestions`

---

## Conventions reminder (inherited from Phase 1)

- Test split: vitest for `tests/domain/`, jest for `tests/data/` and `tests/infra/`.
- Modal-based sheets (NOT `@gorhom/bottom-sheet`). Reference: `src/ui/help/help-sheet.tsx`.
- Pressables: `<PressScale>`. Haptics from `@/ui/motion/haptics`. Motion durations from `motion-tokens.ts`.
- Identifiers in English, i18n values in French.
- Single commit per task. Always include `Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>` trailer.

---

## Task 1: Extend catalog with essential vs discovery

**Files:**
- Modify: `src/domain/tutorial/keys.ts`
- Test: `tests/domain/tutorial/essential.test.ts`

- [ ] **Step 1: Write the failing test**

```ts
// tests/domain/tutorial/essential.test.ts
import { describe, it, expect } from 'vitest';
import { TUTORIAL_KEYS, isEssentialCoachmark } from '@/domain/tutorial/keys';

describe('isEssentialCoachmark', () => {
  it('returns true for the 2 essential Phase 1 coach-marks', () => {
    expect(isEssentialCoachmark(TUTORIAL_KEYS.coachmarkFirstClient)).toBe(true);
    expect(isEssentialCoachmark(TUTORIAL_KEYS.coachmarkFirstTour)).toBe(true);
  });

  it('returns false for the 5 Phase 2 discovery coach-marks', () => {
    expect(isEssentialCoachmark(TUTORIAL_KEYS.coachmarkCloudBackup)).toBe(false);
    expect(isEssentialCoachmark(TUTORIAL_KEYS.coachmarkDiscoverCatalog)).toBe(false);
    expect(isEssentialCoachmark(TUTORIAL_KEYS.coachmarkManualStatuses)).toBe(false);
    expect(isEssentialCoachmark(TUTORIAL_KEYS.coachmarkProximitySuggestions)).toBe(false);
    expect(isEssentialCoachmark(TUTORIAL_KEYS.coachmarkPaymentMethods)).toBe(false);
  });

  it('returns false for sheet keys (sanity — sheets are never coach-marks)', () => {
    expect(isEssentialCoachmark(TUTORIAL_KEYS.sheetClients)).toBe(false);
    expect(isEssentialCoachmark(TUTORIAL_KEYS.sheetMap)).toBe(false);
  });
});
```

- [ ] **Step 2: Run to verify failure**

```
pnpm test:domain -- tests/domain/tutorial/essential.test.ts
```

Expected: FAIL — `coachmarkCloudBackup` etc. not yet exported.

- [ ] **Step 3: Replace `src/domain/tutorial/keys.ts`**

```ts
// src/domain/tutorial/keys.ts
export const TUTORIAL_KEYS = {
  // Phase 1 — sheets
  sheetClients:        'sheet.clients',
  sheetTours:          'sheet.tours',
  sheetCompletion:     'sheet.completion',
  // Phase 1 — coach-marks (essential)
  coachmarkFirstClient: 'coachmark.first_client',
  coachmarkFirstTour:   'coachmark.first_tour',

  // Phase 2 — sheets
  sheetMap:                'sheet.map',
  sheetClientDetail:       'sheet.client_detail',
  sheetTourDetail:         'sheet.tour_detail',
  sheetServicesCatalog:    'sheet.services_catalog',
  sheetStatuses:           'sheet.statuses',
  sheetCloud:              'sheet.cloud',
  sheetSettings:           'sheet.settings',
  // Phase 2 — coach-marks (discovery)
  coachmarkCloudBackup:           'coachmark.cloud_backup',
  coachmarkDiscoverCatalog:       'coachmark.discover_catalog',
  coachmarkManualStatuses:        'coachmark.manual_statuses',
  coachmarkProximitySuggestions:  'coachmark.proximity_suggestions',
  coachmarkPaymentMethods:        'coachmark.payment_methods',
} as const;

export type TutorialKey = typeof TUTORIAL_KEYS[keyof typeof TUTORIAL_KEYS];

const KNOWN_KEYS = new Set<string>(Object.values(TUTORIAL_KEYS));

export function validateTutorialKey(key: string): boolean {
  return KNOWN_KEYS.has(key);
}

const ESSENTIAL_COACHMARKS = new Set<TutorialKey>([
  TUTORIAL_KEYS.coachmarkFirstClient,
  TUTORIAL_KEYS.coachmarkFirstTour,
]);

export function isEssentialCoachmark(key: TutorialKey): boolean {
  return ESSENTIAL_COACHMARKS.has(key);
}
```

- [ ] **Step 4: Run to verify pass + Phase 1 tests still green**

```
pnpm test:domain
```

Expected: 188+ tests pass (185 from Phase 1 + 3 new).

- [ ] **Step 5: Commit**

```
git add src/domain/tutorial/keys.ts tests/domain/tutorial/essential.test.ts
git commit -m "$(cat <<'EOF'
feat(tutorial): extend catalog with Phase 2 keys + essential/discovery split

12 new keys (7 sheets + 5 coach-marks) added to TUTORIAL_KEYS.
isEssentialCoachmark() distinguishes the 2 Phase 1 essentials
(first_client, first_tour) from the 5 Phase 2 discovery coach-marks
— used by useCoachMark to gate discovery behind the at-most-1-per-
session policy.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: Session store

**Files:**
- Create: `src/ui/help/session-store.ts`
- Test: `tests/domain/tutorial/session-store.test.ts`

- [ ] **Step 1: Write the failing test**

```ts
// tests/domain/tutorial/session-store.test.ts
import { describe, it, expect, beforeEach } from 'vitest';
import {
  hasDiscoveryFiredThisSession,
  markDiscoveryFired,
  resetSessionDiscoveryFlag,
} from '@/ui/help/session-store';

describe('session-store', () => {
  beforeEach(() => {
    resetSessionDiscoveryFlag();
  });

  it('starts at false', () => {
    expect(hasDiscoveryFiredThisSession()).toBe(false);
  });

  it('flips to true after markDiscoveryFired', () => {
    markDiscoveryFired();
    expect(hasDiscoveryFiredThisSession()).toBe(true);
  });

  it('resets back to false on resetSessionDiscoveryFlag', () => {
    markDiscoveryFired();
    expect(hasDiscoveryFiredThisSession()).toBe(true);
    resetSessionDiscoveryFlag();
    expect(hasDiscoveryFiredThisSession()).toBe(false);
  });
});
```

- [ ] **Step 2: Run to verify failure**

```
pnpm test:domain -- tests/domain/tutorial/session-store.test.ts
```

Expected: FAIL.

- [ ] **Step 3: Create the module**

```ts
// src/ui/help/session-store.ts
//
// Module-level mutable flag tracking whether ANY discovery coach-mark has
// already fired in the current process lifetime. Reset implicit at cold
// start (module re-evaluated). Resume after backgrounding preserves the
// flag. Used by useCoachMark to enforce the "at most 1 discovery per
// session" policy described in the Phase 2 spec.

let discoveryFiredThisSession = false;

export function hasDiscoveryFiredThisSession(): boolean {
  return discoveryFiredThisSession;
}

export function markDiscoveryFired(): void {
  discoveryFiredThisSession = true;
}

export function resetSessionDiscoveryFlag(): void {
  discoveryFiredThisSession = false;
}
```

- [ ] **Step 4: Run to verify pass**

```
pnpm test:domain -- tests/domain/tutorial/session-store.test.ts
```

Expected: PASS, 3 tests.

- [ ] **Step 5: Commit**

```
git add src/ui/help/session-store.ts tests/domain/tutorial/session-store.test.ts
git commit -m "$(cat <<'EOF'
feat(help): session-store for at-most-1-discovery-per-session policy

Module-level mutable boolean flag, no Zustand/Context — a single check
in useCoachMark consults it. Reset implicitly at cold start, preserved
across background/foreground. Exposes mark/reset helpers for explicit
control (the Réglages > Aide reset button calls resetSessionDiscoveryFlag).

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: Modify `useCoachMark` to apply the policy + wire reset

**Files:**
- Modify: `src/ui/help/hooks.ts`
- Modify: `src/state/queries/tutorial.ts`

- [ ] **Step 1: Update `src/ui/help/hooks.ts`**

Replace the existing `useCoachMark` implementation. Add imports at the top:

```ts
import { useCallback, useEffect, useState } from 'react';
import type { TutorialKey } from '@/domain/tutorial/keys';
import { isEssentialCoachmark } from '@/domain/tutorial/keys';
import {
  useIsTutorialSeen,
  useMarkTutorialSeen,
} from '@/state/queries/tutorial';
import {
  hasDiscoveryFiredThisSession,
  markDiscoveryFired,
} from '@/ui/help/session-store';
```

Then replace the `useCoachMark` function with:

```ts
export function useCoachMark(
  key: TutorialKey,
  shouldShow: boolean,
): CoachMarkController {
  const [locallyDismissed, setLocallyDismissed] = useState(false);
  const hasBeenSeen = useIsTutorialSeen(key);
  const markSeen = useMarkTutorialSeen();

  const isEssential = isEssentialCoachmark(key);
  const sessionGate = isEssential || !hasDiscoveryFiredThisSession();

  const dismiss = useCallback(() => {
    setLocallyDismissed(true);
    if (!hasBeenSeen) markSeen.mutate(key);
  }, [hasBeenSeen, key, markSeen]);

  const isVisible = shouldShow && !hasBeenSeen && !locallyDismissed && sessionGate;

  // Side-effect: when a discovery coach-mark first becomes visible this
  // session, burn the session token so no other discovery coach-mark fires
  // until the next cold start.
  useEffect(() => {
    if (isVisible && !isEssential) {
      markDiscoveryFired();
    }
  }, [isVisible, isEssential]);

  return { isVisible, dismiss };
}
```

(Leave `useHelpSheet` and `HelpSheetController`/`CoachMarkController` interfaces unchanged.)

- [ ] **Step 2: Update `src/state/queries/tutorial.ts`**

Find `useResetTutorials` and modify its `onSuccess` to also reset the session flag.

Add an import at the top:

```ts
import { resetSessionDiscoveryFlag } from '@/ui/help/session-store';
```

Then update:

```ts
export function useResetTutorials() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async () => {
      await repo.resetAll();
    },
    onSuccess: () => {
      resetSessionDiscoveryFlag();
      qc.invalidateQueries({ queryKey: tutorialKeys.list });
    },
  });
}
```

- [ ] **Step 3: Verify**

```
pnpm typecheck
pnpm test
```

Expected: PASS, all tests still green.

- [ ] **Step 4: Commit**

```
git add src/ui/help/hooks.ts src/state/queries/tutorial.ts
git commit -m "$(cat <<'EOF'
feat(help): useCoachMark applies discovery session policy + reset wires it

Discovery coach-marks (anything not in ESSENTIAL_COACHMARKS) are gated
behind hasDiscoveryFiredThisSession(). The first one to become visible
in a session burns the session token via markDiscoveryFired(). Essential
coach-marks (first_client, first_tour) ignore the gate.

useResetTutorials.onSuccess now also calls resetSessionDiscoveryFlag()
so 'Rejouer les tutoriels' immediately re-arms discovery firing in the
current session.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 4: i18n keys for Phase 2

**Files:**
- Modify: `src/i18n/locales/fr.json`

This task adds ~85 new FR keys structured under `help.*` (7 sub-blocks for the 7 sheets) and `coachmark.*` (5 sub-blocks for the 5 coach-marks).

- [ ] **Step 1: Read the current `fr.json`**

Locate the existing `help` and `coachmark` blocks. We extend both.

- [ ] **Step 2: Extend `help.*` with 7 new sub-blocks**

Inside the existing `help` object, after the existing `clients`, `tours`, `completion` sub-blocks, add:

```json
"map": {
  "title": "La carte",
  "what_is_title": "Vue d'ensemble géographique",
  "what_is_body": "La carte affiche tous tes clients géolocalisés. Chaque pin est coloré selon le statut du client. La maison représente ton point de départ.",
  "filter_title": "Filtrer par statut",
  "filter_body": "Tape sur les chips en bas (« Tous », « En attente », « Planifié »…) pour n'afficher qu'une catégorie de clients.",
  "popup_title": "Détails au tap",
  "popup_body": "Tape sur un pin pour ouvrir une fiche rapide avec le nom, l'adresse et les actions Appeler / SMS.",
  "kpis_title": "Compteurs en temps réel",
  "kpis_body": "Les chiffres en bas indiquent combien de clients correspondent à chaque statut, en tenant compte du filtre actif."
},
"client_detail": {
  "title": "La fiche client",
  "what_is_title": "Tout sur un client",
  "what_is_body": "La fiche client centralise les coordonnées, les animaux, l'historique des tontes et les actions rapides (appeler, planifier, supprimer).",
  "edit_title": "Modifier les infos",
  "edit_body": "Tape sur le crayon en haut pour éditer le nom, l'adresse, les téléphones, les compteurs d'animaux.",
  "history_title": "L'historique",
  "history_body": "L'historique liste toutes les tontes faites pour ce client, qu'elles viennent d'une tournée ou d'une saisie manuelle. Tape sur une ligne pour la consulter ou la modifier.",
  "manual_status_title": "Le statut manuel",
  "manual_status_body": "Tu peux assigner manuellement un statut à un client (par exemple « VIP » ou « Difficile »). Ça l'override les statuts automatiques.",
  "delete_title": "Supprimer un client",
  "delete_body": "« Supprimer ce client » anonymise sa fiche : son nom devient « Client supprimé », ses coordonnées sont effacées, mais ses tournées passées restent dans l'historique pour ta compta. Tape SUPPRIMER pour confirmer."
},
"tour_detail": {
  "title": "Le détail d'une tournée",
  "what_is_title": "Vue par arrêt",
  "what_is_body": "L'écran liste tes arrêts dans l'ordre, avec l'heure prévue, les prestations à faire et le revenu attendu.",
  "edit_title": "Modifier une tournée planifiée",
  "edit_body": "Tape sur le crayon (en haut à droite) pour ajouter, retirer ou réordonner les clients. Disponible uniquement tant que la tournée n'est pas complétée.",
  "complete_title": "Finir une tournée",
  "complete_body": "Quand tu termines la journée sur le terrain, tape sur « Faire le bilan ». Tu pourras ajuster les prestations réellement faites et enregistrer les paiements.",
  "delete_title": "Supprimer une tournée",
  "delete_body": "Tu peux supprimer une tournée planifiée ou complétée. Pour une tournée complétée, l'historique des clients reste préservé.",
  "caption_main": "L'écran de détail d'une tournée"
},
"services_catalog": {
  "title": "Le catalogue de prestations",
  "what_is_title": "Tes services et tarifs",
  "what_is_body": "Le catalogue contient toutes les prestations que tu factures (« Tonte petit mouton », « Parage », etc.). Chaque prestation a un tarif et une durée.",
  "create_title": "Créer une prestation",
  "create_body": "Tape sur « Nouvelle prestation ». Donne-lui un nom, un prix, une durée. Tu peux la rattacher à une catégorie d'animal pour qu'elle apparaisse au bon moment dans la planification.",
  "archive_title": "Archiver, ne pas supprimer",
  "archive_body": "Tu ne peux pas supprimer une prestation déjà utilisée dans une tournée — tu peux l'archiver. Elle disparaît du picker mais reste lisible dans l'historique.",
  "caption_main": "L'écran du catalogue de prestations"
},
"statuses": {
  "title": "Les statuts client",
  "what_is_title": "Statuts système et personnalisés",
  "what_is_body": "Six statuts système (« En attente », « Planifié », « Fait », etc.) sont calculés automatiquement par l'app. Tu peux aussi créer des statuts personnalisés (« VIP », « Difficile »…) pour qualifier finement.",
  "rename_title": "Renommer & recolorier",
  "rename_body": "Tape sur n'importe quel statut (système ou perso) pour changer son nom et ses couleurs (light + dark thème).",
  "manual_title": "Statut manuel sur un client",
  "manual_body": "Depuis la fiche d'un client, tu peux lui assigner un statut perso. Cet override remplace l'affichage du statut automatique partout (carte, liste, badges).",
  "caption_main": "L'écran de gestion des statuts"
},
"cloud": {
  "title": "La sauvegarde cloud",
  "what_is_title": "Pourquoi sauvegarder",
  "what_is_body": "Sans sauvegarde cloud, tes données ne vivent que sur ce téléphone. Si tu changes d'appareil ou si tu le perds, tout est perdu. La sauvegarde cloud chiffre tes données et les stocke à Paris.",
  "login_title": "Se connecter",
  "login_body": "Tape sur « Se connecter au cloud » et entre ton email. Tu recevras un lien magique : tape dessus depuis ton mobile, et tu es connecté. Pas de mot de passe à retenir.",
  "auto_title": "Sauvegarde automatique",
  "auto_body": "Une fois connecté, l'app sauvegarde automatiquement toutes les 24 h. Tu peux aussi déclencher une sauvegarde manuelle quand tu veux.",
  "restore_title": "Restaurer un backup",
  "restore_body": "Sur un nouvel appareil, connecte-toi avec le même email et choisis une sauvegarde à restaurer. Confirmation typée RESTAURER pour éviter les fausses manip."
},
"settings": {
  "title": "Les Réglages",
  "what_is_title": "Tout configurer ici",
  "what_is_body": "Cet écran est ton centre de contrôle : adresse de départ, séance d'horaires, catalogue, statuts, sauvegarde cloud, paramètres légaux.",
  "sections_title": "Lis les sections",
  "sections_body": "Chaque section regroupe des réglages liés. Survole les hints sous chaque entrée pour comprendre ce que tu vas modifier."
}
```

- [ ] **Step 3: Extend `coachmark.*` with 5 new sub-blocks**

Inside the existing `coachmark` object, after `first_client` and `first_tour`, add:

```json
"cloud_backup": {
  "title": "Pense à sauvegarder",
  "body": "Tu as plusieurs clients enregistrés. Active la sauvegarde cloud pour ne rien perdre si tu changes de téléphone."
},
"discover_catalog": {
  "title": "Personnalise tes prestations",
  "body": "Tu as déjà fait une tournée. Ajuste ton catalogue de prestations dans Réglages pour gagner du temps à la planification."
},
"manual_statuses": {
  "title": "Crée tes propres statuts",
  "body": "Tu commences à avoir pas mal de clients. Tu peux les qualifier avec des statuts personnalisés (VIP, difficile, etc.)."
},
"proximity_suggestions": {
  "title": "Profite des suggestions à proximité",
  "body": "Quand tu planifies, l'app te suggère les clients en attente proches de tes arrêts. Pratique pour grouper les visites."
},
"payment_methods": {
  "title": "Personnalise les modes de paiement",
  "body": "Tu peux ajouter ou renommer les modes de paiement (espèces, virement, chèque, Wero…) dans Réglages."
}
```

- [ ] **Step 4: Validate JSON syntax**

```
node -e "JSON.parse(require('node:fs').readFileSync('src/i18n/locales/fr.json', 'utf8')); console.log('OK')"
```

- [ ] **Step 5: Commit**

```
git add src/i18n/locales/fr.json
git commit -m "$(cat <<'EOF'
feat(i18n): tutorial & help system Phase 2 FR strings

~85 new keys: 7 new sheet sub-blocks (map, client_detail, tour_detail,
services_catalog, statuses, cloud, settings) and 5 new coach-mark
sub-blocks (cloud_backup, discover_catalog, manual_statuses,
proximity_suggestions, payment_methods).

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 5: Three new preview demos

**Files:**
- Create: `src/ui/help/previews/service-row-demo.tsx`
- Create: `src/ui/help/previews/status-row-demo.tsx`
- Create: `src/ui/help/previews/tour-stop-list-demo.tsx`

- [ ] **Step 1: Read the real components for visual reference**

Read these files to understand the visual structure each demo must mimic:
- `src/ui/components/service-card.tsx` (or wherever a single service row is rendered in `app/(tabs)/settings/services/index.tsx`)
- The status row rendering inside `app/(tabs)/settings/statuses.tsx`
- Tour stop row rendering — look at `src/ui/components/tour-stop-row.tsx` if it exists, otherwise inline in tour detail screen

The demos are visually-faithful, data-free copies (cf the existing pattern in `src/ui/help/previews/`). Use realistic French data (sheep farmer context).

- [ ] **Step 2: Create `service-row-demo.tsx`**

Reproduce the visual style of a Catalogue prestations row: name on the left, price + duration on the right.

```tsx
// src/ui/help/previews/service-row-demo.tsx
import { View } from 'react-native';
import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';

export function ServiceRowDemo() {
  return (
    <View className="gap-2 w-full" style={{ maxWidth: 320 }}>
      <Surface variant="muted" className="rounded-2xl px-4 py-3 flex-row items-center justify-between">
        <View className="flex-1 gap-0.5">
          <Text className="font-semibold">Tonte petit mouton</Text>
          <Text variant="muted" className="text-xs">Mouton</Text>
        </View>
        <View className="items-end">
          <Text className="font-semibold">3,50 €</Text>
          <Text variant="muted" className="text-xs">5 min</Text>
        </View>
      </Surface>
      <Surface variant="muted" className="rounded-2xl px-4 py-3 flex-row items-center justify-between">
        <View className="flex-1 gap-0.5">
          <Text className="font-semibold">Parage</Text>
          <Text variant="muted" className="text-xs">Cheval</Text>
        </View>
        <View className="items-end">
          <Text className="font-semibold">25,00 €</Text>
          <Text variant="muted" className="text-xs">15 min</Text>
        </View>
      </Surface>
    </View>
  );
}
```

(Adjust the structure to match the actual ServiceCard / row rendering — read it first.)

- [ ] **Step 3: Create `status-row-demo.tsx`**

```tsx
// src/ui/help/previews/status-row-demo.tsx
import { View } from 'react-native';
import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { useResolvedColorScheme } from '@/ui/theme/theme-provider';

const STATUS_COLORS = [
  { label: 'En attente de RDV', light: '#C88226', dark: '#DC9E4E' },
  { label: 'Planifié',          light: '#A1602F', dark: '#C68A58' },
  { label: 'VIP',               light: '#7A3E7A', dark: '#A66BA6' },
];

export function StatusRowDemo() {
  const scheme = useResolvedColorScheme();

  return (
    <View className="gap-2 w-full" style={{ maxWidth: 320 }}>
      {STATUS_COLORS.map((s) => {
        const hex = scheme === 'dark' ? s.dark : s.light;
        return (
          <Surface key={s.label} variant="muted" className="rounded-2xl px-4 py-3 flex-row items-center gap-3">
            <View style={{ width: 16, height: 16, borderRadius: 8, backgroundColor: hex }} />
            <Text className="flex-1">{s.label}</Text>
            <Text variant="muted" className="text-xs">{hex.toUpperCase()}</Text>
          </Surface>
        );
      })}
    </View>
  );
}
```

- [ ] **Step 4: Create `tour-stop-list-demo.tsx`**

A vertical list of 3 mini-stops, each with time + client name + service summary.

```tsx
// src/ui/help/previews/tour-stop-list-demo.tsx
import { View } from 'react-native';
import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';

const STOPS = [
  { time: '08:15 → 09:00', name: 'Famille Le Goff',   summary: '5 Tontes' },
  { time: '09:30 → 10:15', name: 'Ferme du Pré Vert',  summary: '8 Tontes, 1 Parage' },
  { time: '10:45 → 11:30', name: 'GAEC des Trois Chênes', summary: '12 Tontes' },
];

export function TourStopListDemo() {
  return (
    <View className="gap-2 w-full" style={{ maxWidth: 320 }}>
      {STOPS.map((s, i) => (
        <Surface key={i} variant="muted" className="rounded-2xl px-4 py-3 gap-1">
          <Text variant="muted" className="text-xs">{s.time}</Text>
          <Text className="font-semibold">{s.name}</Text>
          <Text variant="muted" className="text-xs">{s.summary}</Text>
        </Surface>
      ))}
    </View>
  );
}
```

- [ ] **Step 5: Update `src/ui/help/previews/README.md` to add the 3 new entries to the maintenance table**

Add three rows to the existing table:

```md
| `service-row-demo.tsx` | catalog row in `app/(tabs)/settings/services/index.tsx` |
| `status-row-demo.tsx` | status row in `app/(tabs)/settings/statuses.tsx` |
| `tour-stop-list-demo.tsx` | tour stop row in `app/(tabs)/tours/[id].tsx` |
```

- [ ] **Step 6: Verify**

```
pnpm typecheck && pnpm lint
```

- [ ] **Step 7: Commit**

```
git add src/ui/help/previews/
git commit -m "$(cat <<'EOF'
feat(help): three Phase 2 preview demos (services, statuses, stops)

ServiceRowDemo + StatusRowDemo + TourStopListDemo, each ~30 lines of
JSX with hardcoded sheep-farmer-context data. README updated with the
maintenance table entries.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 6: Seven sheet content components

**Files:** create 7 files under `src/ui/help/sheets/`.

The pattern is identical to the Phase 1 sheets. Each file is one component using `<HelpSheet>` + `<HelpSection>` (with lucide icons) + optional `<HelpPreview>` wrapping a demo (only for the 3 sheets that have a demo).

- [ ] **Step 1: Create `help-sheet-map.tsx`** (no demo)

```tsx
import { useTranslation } from 'react-i18next';
import { Map, Filter, MapPin, Hash } from 'lucide-react-native';
import { Text } from '@/ui/primitives/text';
import { HelpSheet, HelpSection } from '@/ui/help/help-sheet';
import { TUTORIAL_KEYS } from '@/domain/tutorial/keys';

interface Props { visible: boolean; onClose: () => void; }

export function HelpSheetMap({ visible, onClose }: Props) {
  const { t } = useTranslation();
  return (
    <HelpSheet visible={visible} onClose={onClose} title={t('help.map.title')}>
      <HelpSection icon={Map} title={t('help.map.what_is_title')}>
        <Text>{t('help.map.what_is_body')}</Text>
      </HelpSection>
      <HelpSection icon={Filter} title={t('help.map.filter_title')}>
        <Text>{t('help.map.filter_body')}</Text>
      </HelpSection>
      <HelpSection icon={MapPin} title={t('help.map.popup_title')}>
        <Text>{t('help.map.popup_body')}</Text>
      </HelpSection>
      <HelpSection icon={Hash} title={t('help.map.kpis_title')}>
        <Text>{t('help.map.kpis_body')}</Text>
      </HelpSection>
    </HelpSheet>
  );
}
```

(Note `TUTORIAL_KEYS` is imported but not consumed here — it's not needed inside the sheet itself; `useHelpSheet` is the integration point. Actually you can drop the `TUTORIAL_KEYS` import for the sheet content components — they don't reference it. Verify against the existing sheets like `help-sheet-clients.tsx` to match the style.)

- [ ] **Step 2: Create `help-sheet-client-detail.tsx`** (no demo)

Sections: `what_is`, `edit`, `history`, `manual_status`, `delete` — each `<HelpSection>` with an icon (`User`, `Pencil`, `History`, `CircleDot`, `Trash2` — pick from lucide-react-native).

- [ ] **Step 3: Create `help-sheet-tour-detail.tsx`** (uses `<TourStopListDemo>`)

Sections: `what_is`, `edit`, `complete`, `delete`. After `what_is` section, insert `<HelpPreview caption={t('help.tour_detail.caption_main')}><TourStopListDemo /></HelpPreview>`.

- [ ] **Step 4: Create `help-sheet-services-catalog.tsx`** (uses `<ServiceRowDemo>`)

Sections: `what_is`, `create`, `archive`. After `what_is`, insert `<HelpPreview caption={t('help.services_catalog.caption_main')}><ServiceRowDemo /></HelpPreview>`.

- [ ] **Step 5: Create `help-sheet-statuses.tsx`** (uses `<StatusRowDemo>`)

Sections: `what_is`, `rename`, `manual`. After `what_is`, insert `<HelpPreview caption={t('help.statuses.caption_main')}><StatusRowDemo /></HelpPreview>`.

- [ ] **Step 6: Create `help-sheet-cloud.tsx`** (no demo)

Sections: `what_is`, `login`, `auto`, `restore` — icons `Cloud`, `Mail`, `RefreshCw`, `Download`.

- [ ] **Step 7: Create `help-sheet-settings.tsx`** (no demo)

Two sections: `what_is`, `sections` — icons `Settings`, `List`.

- [ ] **Step 8: Verify**

```
pnpm typecheck && pnpm lint
```

- [ ] **Step 9: Commit**

```
git add src/ui/help/sheets/
git commit -m "$(cat <<'EOF'
feat(help): seven Phase 2 sheet content components

HelpSheetMap, HelpSheetClientDetail, HelpSheetTourDetail,
HelpSheetServicesCatalog, HelpSheetStatuses, HelpSheetCloud,
HelpSheetSettings. Three of them embed Phase 2 demos
(TourStopListDemo, ServiceRowDemo, StatusRowDemo); the four others
are text + lucide icons only per spec §2.1.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 7: Wire seven `<HelpButton>` into screens (no coach-marks)

This task adds a `<HelpButton>` to the header of each of the 7 new sheet locations. Pattern is identical to Phase 1: import keys/component/sheet/hook, declare `useHelpSheet`, mount `<HelpSheetX>` at the bottom of the JSX, add `<HelpButton>` to the `rightSlot` of `<ScreenHeader>` (or wrap with existing rightSlot in a `<View>`).

For each screen below, repeat the pattern. Make ONE COMMIT GROUPING ALL SEVEN integrations (mechanical edit, low risk).

- [ ] **Step 1: Identify the 7 screen files**

Read these files and apply the integration:
1. **Map screen** — find it: probably `app/(tabs)/map/index.tsx` or `app/(tabs)/index.tsx`. Use `TUTORIAL_KEYS.sheetMap`, `<HelpSheetMap>`.
2. **Fiche client (detail)** — `app/(tabs)/clients/[id].tsx`. Use `TUTORIAL_KEYS.sheetClientDetail`, `<HelpSheetClientDetail>`.
3. **Détail tournée** — `app/(tabs)/tours/[id].tsx`. Use `TUTORIAL_KEYS.sheetTourDetail`, `<HelpSheetTourDetail>`.
4. **Catalogue prestations** — `app/(tabs)/settings/services/index.tsx`. Use `TUTORIAL_KEYS.sheetServicesCatalog`, `<HelpSheetServicesCatalog>`.
5. **Statuses** — `app/(tabs)/settings/statuses.tsx`. Use `TUTORIAL_KEYS.sheetStatuses`, `<HelpSheetStatuses>`.
6. **Cloud** — `app/(tabs)/settings/cloud.tsx`. Use `TUTORIAL_KEYS.sheetCloud`, `<HelpSheetCloud>`.
7. **Settings root** — `app/(tabs)/settings/index.tsx`. Use `TUTORIAL_KEYS.sheetSettings`, `<HelpSheetSettings>`.

For each, the integration is:

```tsx
// Top-of-file imports
import { TUTORIAL_KEYS } from '@/domain/tutorial/keys';
import { HelpButton } from '@/ui/help/help-button';
import { HelpSheetX } from '@/ui/help/sheets/help-sheet-X';
import { useHelpSheet } from '@/ui/help/hooks';
import { View } from 'react-native'; // if not already imported

// Inside component body
const helpSheet = useHelpSheet(TUTORIAL_KEYS.sheetX);

// In <ScreenHeader>, add to rightSlot (wrap with View if rightSlot has existing content)
rightSlot={<HelpButton tutorialKey={TUTORIAL_KEYS.sheetX} onPress={helpSheet.open} />}

// Before closing </Surface>
<HelpSheetX visible={helpSheet.isOpen} onClose={helpSheet.close} />
```

- [ ] **Step 2: Verify**

```
pnpm typecheck && pnpm lint
```

- [ ] **Step 3: Commit**

```
git add app/
git commit -m "$(cat <<'EOF'
feat(help): wire HelpButton into 7 Phase 2 screens

Map, ClientDetail, TourDetail, ServicesCatalog, Statuses, Cloud, and
Settings root each gain a <HelpButton> in their ScreenHeader rightSlot
that opens the corresponding HelpSheet. No coach-marks added in this
commit — only the contextual sheets surface.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 8: Wire `coachmark.cloud_backup` + `coachmark.manual_statuses` on Clients screen

**Files:** Modify `app/(tabs)/clients/index.tsx`.

Two coach-marks on the same screen with priority chaining (cloud_backup wins if both eligible).

- [ ] **Step 1: Read the existing file**

Confirm where `useSession()` is used (for `isCloudOptedIn`). The Phase 1 `coachmark.first_client` is already wired.

- [ ] **Step 2: Add imports**

```tsx
import { useTours } from '@/state/queries/tours'; // or wherever tour queries live
import { useSession } from '@/state/queries/auth';
import { HelpButton } from '@/ui/help/help-button'; // already imported in Phase 1
```

(Adjust based on what's actually imported.)

- [ ] **Step 3: Add the two coach-mark anchors**

```tsx
const headerHelpAnchorRef = useRef<View>(null); // anchored on the help button
const filterAnchorRef = useRef<View>(null);     // anchored on the filter button
```

(Note: `emptyCtaRef` from Phase 1 is for first_client; these are NEW refs.)

- [ ] **Step 4: Compute predicates**

```tsx
const { data: session } = useSession();
const isCloudOptedIn = !!session && !session.user.is_anonymous;

const { data: completedTours = [] } = useTours('completed');
const completedToursCount = completedTours.length;

const cloudCoach = useCoachMark(
  TUTORIAL_KEYS.coachmarkCloudBackup,
  !isLoading && !isError
    && !isCloudOptedIn
    && (allClients.length >= 5 || completedToursCount >= 1),
);

const statusesCoach = useCoachMark(
  TUTORIAL_KEYS.coachmarkManualStatuses,
  !isLoading && !isError
    && allClients.length >= 10
    && !cloudCoach.isVisible, // priority: cloud wins
);
```

- [ ] **Step 5: Wrap the anchors**

In the header `rightSlot`, wrap the existing `<HelpButton>` and `<ClientFilterButton>` with the refs:

```tsx
rightSlot={
  <View className="flex-row items-center gap-1">
    <View ref={filterAnchorRef} collapsable={false}>
      <ClientFilterButton />
    </View>
    <View ref={headerHelpAnchorRef} collapsable={false}>
      <HelpButton tutorialKey={TUTORIAL_KEYS.sheetClients} onPress={helpSheet.open} />
    </View>
  </View>
}
```

- [ ] **Step 6: Mount the two new CoachMark before closing `</Surface>`**

```tsx
<CoachMark
  visible={cloudCoach.isVisible}
  onDismiss={cloudCoach.dismiss}
  anchorRef={headerHelpAnchorRef}
  arrowDirection="up"
  title={t('coachmark.cloud_backup.title')}
  body={t('coachmark.cloud_backup.body')}
/>
<CoachMark
  visible={statusesCoach.isVisible}
  onDismiss={statusesCoach.dismiss}
  anchorRef={filterAnchorRef}
  arrowDirection="up"
  title={t('coachmark.manual_statuses.title')}
  body={t('coachmark.manual_statuses.body')}
/>
```

- [ ] **Step 7: Verify and commit**

```
pnpm typecheck && pnpm lint
git add app/(tabs)/clients/index.tsx
git commit -m "$(cat <<'EOF'
feat(help): cloud_backup + manual_statuses coach-marks on Clients

Two new discovery coach-marks anchored on the header buttons:
- cloud_backup: when 5+ clients OR 1+ completed tour AND user is on
  anonymous session. Anchored on the HelpButton.
- manual_statuses: when 10+ clients. Anchored on the filter button.

Priority chain: if cloud_backup is visible, manual_statuses is gated
off (cloud is more critical than client qualification).

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 9: Wire `coachmark.discover_catalog` on Tours screen

**Files:** Modify `app/(tabs)/tours/index.tsx`.

- [ ] **Step 1: Read the file** — Phase 1 already wired `coachmark.first_tour`. This task adds a 2nd coach-mark, anchored on the `<HelpButton>` of the header.

- [ ] **Step 2: Add the new coach-mark**

```tsx
const headerHelpAnchorRef = useRef<View>(null);
const { data: completedTours = [] } = useTours('completed');

const catalogCoach = useCoachMark(
  TUTORIAL_KEYS.coachmarkDiscoverCatalog,
  !isLoading && !isError && completedTours.length >= 1,
);
```

- [ ] **Step 3: Wrap the help button with the ref in `rightSlot`**

```tsx
rightSlot={
  <View ref={headerHelpAnchorRef} collapsable={false}>
    <HelpButton tutorialKey={TUTORIAL_KEYS.sheetTours} onPress={helpSheet.open} />
  </View>
}
```

(If existing rightSlot wraps multiple buttons, add the headerHelpAnchorRef ref around the HelpButton subtree only.)

- [ ] **Step 4: Mount CoachMark before closing `</Surface>`**

```tsx
<CoachMark
  visible={catalogCoach.isVisible}
  onDismiss={catalogCoach.dismiss}
  anchorRef={headerHelpAnchorRef}
  arrowDirection="up"
  title={t('coachmark.discover_catalog.title')}
  body={t('coachmark.discover_catalog.body')}
/>
```

- [ ] **Step 5: Verify and commit**

```
pnpm typecheck && pnpm lint
git add app/(tabs)/tours/index.tsx
git commit -m "$(cat <<'EOF'
feat(help): discover_catalog coach-mark on Tours

Discovery coach-mark anchored on the Tours screen HelpButton, fires
when the user has at least 1 completed tour. Suggests visiting the
prestation catalog in Réglages.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 10: Wire `coachmark.proximity_suggestions` on TourDraft screen

**Files:** TourDraft screen (path TBD on read — likely `app/(tabs)/tours/new.tsx` or similar).

- [ ] **Step 1: Locate the TourDraft screen**

It's the screen that contains the `<WaitingClientsMultiPicker>` with sections "Suggérés à proximité" / "Autres clients en attente". Search for `WaitingClientsMultiPicker` or `nearbyToAnchorsProvider` — that'll point to the file.

- [ ] **Step 2: Read it and identify**

- The variable holding the nearby clients list (probably `nearbyClients`, `proximityClients`, or similar)
- The component or section header that displays "Suggérés à proximité" — that's the anchor target
- The hook returning all tours count (we need `tours.length >= 1` to detect "this is the 2nd tour creation")

- [ ] **Step 3: Add imports and controllers**

```tsx
import { useRef } from 'react';
import { View } from 'react-native';
import { TUTORIAL_KEYS } from '@/domain/tutorial/keys';
import { CoachMark } from '@/ui/help/coach-mark';
import { useCoachMark } from '@/ui/help/hooks';
import { useTours } from '@/state/queries/tours';

// inside component
const proximityAnchorRef = useRef<View>(null);
const { data: allTours = [] } = useTours('all'); // or whichever filter returns ALL tours
const proximityCoach = useCoachMark(
  TUTORIAL_KEYS.coachmarkProximitySuggestions,
  allTours.length >= 1 && nearbyClients.length > 0,
);
```

(Replace `nearbyClients` with the actual variable name in the file.)

- [ ] **Step 4: Wrap the "Suggérés à proximité" section with the ref + collapsable=false**

Find the JSX that renders the section header / list. Wrap it:

```tsx
<View ref={proximityAnchorRef} collapsable={false}>
  {/* existing nearby section */}
</View>
```

- [ ] **Step 5: Mount CoachMark inside the screen (before its closing root)**

```tsx
<CoachMark
  visible={proximityCoach.isVisible}
  onDismiss={proximityCoach.dismiss}
  anchorRef={proximityAnchorRef}
  arrowDirection="up"
  title={t('coachmark.proximity_suggestions.title')}
  body={t('coachmark.proximity_suggestions.body')}
/>
```

- [ ] **Step 6: Verify and commit**

```
pnpm typecheck && pnpm lint
git add app/(tabs)/tours/
git commit -m "$(cat <<'EOF'
feat(help): proximity_suggestions coach-mark on TourDraft

Discovery coach-mark anchored on the 'Suggérés à proximité' section of
the tour planning client picker. Fires only on the 2nd+ tour creation
(allTours.length >= 1) AND when there are actually nearby suggestions
to highlight (nearbyClients.length > 0).

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 11: New `useHasAnyPaidStop` hook + wire `coachmark.payment_methods` on Completion screen

**Files:**
- Modify or create: `src/state/queries/tours.ts` (add `useHasAnyPaidStop`)
- Modify: `app/(tabs)/tours/[id]/complete.tsx`

- [ ] **Step 1: Add the hook**

In `src/state/queries/tours.ts` (or wherever tour-related queries live), add:

```ts
import { sql } from 'drizzle-orm';
import { tourStops } from '@/infra/db/schema';

const tourStopsKeys = {
  all: ['tour_stops'] as const,
  hasAnyPaid: ['tour_stops', 'hasAnyPaid'] as const,
};

export function useHasAnyPaidStop() {
  return useQuery({
    queryKey: tourStopsKeys.hasAnyPaid,
    queryFn: async () => {
      const rows = await db
        .select({ id: tourStops.id })
        .from(tourStops)
        .where(sql`${tourStops.isPaid} = 1`)
        .limit(1);
      return rows.length > 0;
    },
  });
}
```

(Adjust imports / file structure to match the existing patterns in `src/state/queries/tours.ts`.)

- [ ] **Step 2: Wire the coach-mark in the Completion screen**

Read `app/(tabs)/tours/[id]/complete.tsx`. The Phase 1 `<HelpButton>` is already wired. Add:

```tsx
import { useRef } from 'react';
import { View } from 'react-native';
import { TUTORIAL_KEYS } from '@/domain/tutorial/keys';
import { CoachMark } from '@/ui/help/coach-mark';
import { useCoachMark } from '@/ui/help/hooks';
import { useHasAnyPaidStop } from '@/state/queries/tours';

// inside component
const paymentAnchorRef = useRef<View>(null);
const { data: hasAnyPaid = false } = useHasAnyPaidStop();
const paymentCoach = useCoachMark(
  TUTORIAL_KEYS.coachmarkPaymentMethods,
  hasAnyPaid,
);
```

- [ ] **Step 3: Choose an anchor**

The cleanest target is the payment-method picker on the first stop. If finding that exact element is tricky, fall back to the screen's `<HelpButton>` in the header (less targeted but always present). Use whichever is simpler — the spec accepts either.

Wrap your chosen anchor in `<View ref={paymentAnchorRef} collapsable={false}>`.

- [ ] **Step 4: Mount CoachMark before closing `</Surface>`**

```tsx
<CoachMark
  visible={paymentCoach.isVisible}
  onDismiss={paymentCoach.dismiss}
  anchorRef={paymentAnchorRef}
  arrowDirection="up"
  title={t('coachmark.payment_methods.title')}
  body={t('coachmark.payment_methods.body')}
/>
```

- [ ] **Step 5: Verify and commit**

```
pnpm typecheck && pnpm lint && pnpm test
git add src/state/queries/tours.ts "app/(tabs)/tours/[id]/complete.tsx"
git commit -m "$(cat <<'EOF'
feat(help): payment_methods coach-mark on Completion + useHasAnyPaidStop

New hook useHasAnyPaidStop runs a cheap SELECT 1 LIMIT 1 query on
tour_stops to detect whether the user has ever recorded a paid stop.
The coach-mark fires on the Completion screen the first time the
predicate is true — introducing the idea of customisable payment
methods at the right moment.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 12: Final validation

**Files:** none.

- [ ] **Step 1: Run all automated tests**

```
pnpm test
```

Expected: vitest + jest both PASS. New tests: 4 (3 essential + session-store) on top of Phase 1's 18 = 22 tutorial-related total.

- [ ] **Step 2: Typecheck and lint**

```
pnpm typecheck && pnpm lint
```

Expected: PASS.

- [ ] **Step 3: Manual dev client validation**

```
pnpm start
```

Run through:

**Sheets (7 new):**
- [ ] On Map screen: tap `?` → HelpSheetMap opens, scrolls cleanly, dismisses cleanly. Pastille disappears.
- [ ] On a client detail: tap `?` → HelpSheetClientDetail opens correctly.
- [ ] On a tour detail: tap `?` → HelpSheetTourDetail opens with TourStopListDemo embedded and looks right in light + dark.
- [ ] On Réglages > Catalogue: tap `?` → HelpSheetServicesCatalog opens with ServiceRowDemo.
- [ ] On Réglages > Statuts: tap `?` → HelpSheetStatuses opens with StatusRowDemo.
- [ ] On Réglages > Cloud: tap `?` → HelpSheetCloud opens.
- [ ] On Réglages root: tap `?` → HelpSheetSettings opens.

**Coach-marks (5 new + policy):**
- [ ] Wipe DB. Create 5+ clients on an anonymous session. Open Clients tab → `coachmark.cloud_backup` appears.
- [ ] Same DB, also have 10+ clients. After dismissing cloud_backup → manual_statuses does NOT fire in the same session (policy). Restart app → cloud_backup is now seen, manual_statuses fires.
- [ ] After completing 1 tour, open Tours tab → `coachmark.discover_catalog` fires (or doesn't, if a discovery already fired this session).
- [ ] Create your 2nd tour, in the picker → `coachmark.proximity_suggestions` fires if there are nearby clients to suggest.
- [ ] After recording a paid stop in completion, re-enter completion screen → `coachmark.payment_methods` fires.

**Reset behavior:**
- [ ] Réglages > Aide & tutoriels → Rejouer. Counter goes to 0/17. Discovery coach-marks become eligible again in the current session (no cold-restart needed).
- [ ] After reset, navigate to a screen that triggers a discovery coach-mark → it fires immediately (proves resetSessionDiscoveryFlag wired correctly).

**Backup:**
- [ ] Backup → restore on a different DB state. Tutorials seen state is preserved (already covered by Phase 1; spot-check that it still works).

- [ ] **Step 4: If everything passes, push or merge per user instructions**

(Don't push without explicit user instruction.)

---

## What's NOT in this plan

- No new entries beyond §2.1 of the Phase 2 spec.
- The maintenance burden of the new sheets and demos is documented in the spec and `src/ui/help/previews/README.md`.
- If a future Phase 3 emerges (additional features, more triggers), it follows the same pattern: extend the catalog, add a sheet, optionally a demo, optionally a coach-mark — no architecture change.
