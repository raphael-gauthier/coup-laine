# Tour drafts — design

**Date:** 2026-05-08
**Scope:** Permettre la création d'une tournée en mode "brouillon" (sans date), accumuler des clients dessus, puis la planifier ultérieurement avec une date et une heure de départ. Plusieurs brouillons peuvent coexister, identifiés par un titre libre optionnel.

## 1. Goals

- Une tournée peut être sauvegardée en `status='draft'` sans renseigner `scheduledDate` ni `departureTime`.
- L'éditeur expose deux actions : "Enregistrer brouillon" (status=draft) et "Planifier" (status=planned, date+time obligatoires via une sheet).
- L'onglet Tournées passe à un SegmentedControl 3 valeurs : Brouillons / Planifiées / Terminées.
- Les brouillons sont synchronisés via le cloud comme n'importe quel tour.
- Le bouton "Créer tournée" depuis Proximité, la FAB Manuel et la FAB Optimisé créent désormais un brouillon (pas une tournée planifiée directement).
- Plusieurs brouillons peuvent coexister, distingués par un titre libre optionnel (fallback : "Brouillon du JJ mois").
- Un brouillon doit avoir au moins 1 client pour être enregistré.

## 2. Non-goals

- Pas de "demote" planifiée → brouillon. Une tournée planifiée ne peut pas redevenir brouillon ; pour annuler, on supprime.
- Pas d'auto-save pendant l'édition. Les changements non sauvés sont perdus si l'utilisateur quitte l'écran sans cliquer "Enregistrer brouillon" ou "Planifier".
- Pas de planification en swipe / long-press / menu rapide depuis la card de la liste. La planification se fait uniquement depuis l'éditeur.
- Pas de fusion ni d'import croisé entre brouillons (pas de "ajouter à un brouillon existant" depuis Proximité).
- Pas de templates / brouillons-modèles à dupliquer.
- Pas de tri custom dans la vue Brouillons (tri imposé : `updatedAt DESC`).
- Pas de KPI affichés sur la card brouillon (revenue, distance, durée). La card brouillon montre juste titre + nombre de stops + temps depuis la dernière modif. Les KPI restent disponibles dans l'éditeur.
- Pas de redesign de la vue détail pour les brouillons. Tap sur une card brouillon redirige vers l'éditeur — la vue détail (`tours/[id].tsx`) reste pour les planifiées et terminées.

## 3. Architecture d'ensemble

```
┌──────────────────────────────────────────────────────────┐
│  app/(tabs)/tours/index.tsx                              │
│   SegmentedControl: Brouillons | Planifiées | Terminées  │
│   ↓                                                      │
│   FlashList<TourCard>                                    │
│     └─ tap → router.push(/(tabs)/tours/{id})             │
│              └─ status==='draft' →                       │
│                  router.replace(/tour-new/draft?id={id}) │
└──────────────────────────────────────────────────────────┘
                            ↓
┌──────────────────────────────────────────────────────────┐
│  app/tour-new/draft.tsx (éditeur unifié)                 │
│                                                          │
│   - id?: string from search params                       │
│   - state local: title, date|null, time|null             │
│   - Zustand: pickedClientIds, servicesByClient           │
│   - chargement initial depuis DB si id fourni            │
│                                                          │
│   Footer:                                                │
│     [Enregistrer brouillon]  [Planifier]                 │
│            │                       │                     │
│            ↓                       ↓                     │
│     useSaveDraft.mutate     <ScheduleTourSheet/>         │
│                                    │                     │
│                                    ↓                     │
│                             useScheduleTour.mutate       │
└──────────────────────────────────────────────────────────┘
```

Pas de nouvelle table, pas de nouveau store, pas de nouvel onglet. Les flows existants (FAB, Proximité, optimized-config) ne changent pas — leur point d'arrivée est l'éditeur, qui désormais sauve par défaut en brouillon.

## 4. Fichiers modifiés et ajoutés

### 4.1 Ajoutés

```
src/ui/components/schedule-tour-sheet.tsx        ← modal date+time pour planifier
src/domain/use-cases/assert-tour-invariants.ts   ← garde des invariants applicatifs
tests/domain/assert-tour-invariants.test.ts      ← vitest
src/infra/db/migrations/000X_tour_drafts.sql     ← migration hand-écrite (rename + recreate + copy)
```

### 4.2 Modifiés

```
src/domain/models/tour.ts                        ← TourStatus + nullables + title
src/infra/db/schema.ts                            ← schéma tours
src/infra/db/migrations/meta/_journal.json        ← entry + when=Date.now()
src/infra/db/migrations.js                        ← régénéré par pnpm db:bundle
src/data/repositories/tour-repository.ts          ← gérer null + title + tri par status
src/state/queries/tours.ts                        ← split useSaveDraft / useScheduleTour
src/ui/components/tour-draft-editor.tsx           ← title input + 2 boutons + delete + load by id
src/ui/components/tour-card.tsx                   ← rendu adapté pour status='draft'
app/(tabs)/tours/index.tsx                        ← SegmentedControl 3 valeurs + empty states
app/(tabs)/tours/[id].tsx                         ← redirect si status='draft'
app/(tabs)/tours/[id]/edit.tsx                    ← branche useScheduleTour
app/tour-new/draft.tsx                            ← branche les 2 actions + load by id
src/i18n/locales/fr.json                          ← nouvelles clés
```

`src/state/queries/use-propose-optimized-tour.ts` reste inchangé : son `router.push('/tour-new/draft')` continue de fonctionner. `app/tour-new/optimized-config.tsx` reste inchangé. La FAB `CreateTourSheet` reste inchangée.

## 5. Modèle de données et migration

### 5.1 Schéma Drizzle

```ts
// src/infra/db/schema.ts
export const tours = sqliteTable('tours', {
  id: text('id').primaryKey(),
  scheduledDate: text('scheduled_date'),         // ← nullable
  departureTime: text('departure_time'),         // ← nullable
  title: text('title'),                          // ← nouveau, nullable
  baseLat: real('base_lat').notNull(),
  baseLng: real('base_lng').notNull(),
  status: text('status').notNull(),              // 'draft' | 'planned' | 'completed'
  totalDistanceKm: real('total_distance_km'),
  totalDriveSeconds: integer('total_drive_seconds'),
  totalMinutes: integer('total_minutes'),
  totalRevenueCents: integer('total_revenue_cents'),
  totalAnimalsCount: integer('total_animals_count'),
  routeGeometry: text('route_geometry'),
  notes: text('notes'),
  completedAt: text('completed_at'),
  createdAt: text('created_at').notNull(),
  updatedAt: text('updated_at').notNull(),
});
```

### 5.2 Migration SQL hand-écrite

SQLite ne sait pas drop `NOT NULL` via un `ALTER TABLE` direct → il faut recréer la table.

```sql
-- 000X_tour_drafts.sql
PRAGMA foreign_keys=OFF;

CREATE TABLE __new_tours (
  id text PRIMARY KEY NOT NULL,
  scheduled_date text,
  departure_time text,
  title text,
  base_lat real NOT NULL,
  base_lng real NOT NULL,
  status text NOT NULL,
  total_distance_km real,
  total_drive_seconds integer,
  total_minutes integer,
  total_revenue_cents integer,
  total_animals_count integer,
  route_geometry text,
  notes text,
  completed_at text,
  created_at text NOT NULL,
  updated_at text NOT NULL
);

INSERT INTO __new_tours
SELECT
  id, scheduled_date, departure_time,
  NULL,
  base_lat, base_lng, status,
  total_distance_km, total_drive_seconds, total_minutes,
  total_revenue_cents, total_animals_count,
  route_geometry, notes, completed_at, created_at, updated_at
FROM tours;

DROP TABLE tours;
ALTER TABLE __new_tours RENAME TO tours;

PRAGMA foreign_keys=ON;
```

Conformément à `CLAUDE.md` §6 — Drizzle migrations :
- L'entrée du journal `_journal.json` reçoit `when: Date.now()` au moment de l'édition (pas une date "propre").
- `pnpm db:bundle` est exécuté tout de suite après pour régénérer `migrations.js` et valider l'ordre des `when`.
- Aucun ajout dans `KNOWN_HISTORICAL_VIOLATIONS`.

### 5.3 Modèle domaine

```ts
// src/domain/models/tour.ts
export const TourStatus = z.enum(['draft', 'planned', 'completed']);

export const Tour = z.object({
  id: z.string(),
  scheduledDate: z.string().nullable(),
  departureTime: z.string().nullable(),
  title: z.string().nullable(),
  baseLat: z.number(),
  baseLng: z.number(),
  status: TourStatus,
  totalDistanceKm: z.number().nullable(),
  totalDriveSeconds: z.number().int().nullable(),
  totalMinutes: z.number().int().nullable(),
  totalRevenueCents: z.number().int().nullable(),
  totalAnimalsCount: z.number().int().nullable(),
  routeGeometry: z.string().nullable(),
  notes: z.string().nullable(),
  completedAt: z.string().nullable(),
  createdAt: z.string(),
  updatedAt: z.string(),
});
```

### 5.4 Invariants applicatifs

```ts
// src/domain/use-cases/assert-tour-invariants.ts
export function assertTourInvariants(tour: Tour): void {
  if (tour.status === 'planned' || tour.status === 'completed') {
    if (tour.scheduledDate == null || tour.departureTime == null) {
      throw new Error(`Tour ${tour.id} status=${tour.status} requires scheduledDate and departureTime`);
    }
  }
  if (tour.status === 'draft') {
    if (tour.scheduledDate != null || tour.departureTime != null) {
      throw new Error(`Tour ${tour.id} status=draft must not carry scheduledDate or departureTime`);
    }
  }
}
```

Appelée par `useSaveDraft` et `useScheduleTour` avant chaque upsert. C'est une garde, pas une contrainte SQL — on ne veut pas se piéger à la migration ni complexifier le schéma.

### 5.5 Sync cloud

Aucune action particulière côté domain : un brouillon est un tour comme un autre. À vérifier au moment de l'implémentation : la table miroir Supabase `tours` doit avoir `scheduled_date` et `departure_time` nullable et la colonne `title text`. Si la migration Supabase n'est pas en place, la sync rejettera les rows draft. Inclure cette migration Supabase dans le scope de la PR.

## 6. Mutations React Query

### 6.1 Split

```ts
// src/state/queries/tours.ts

export interface SaveDraftInput {
  id?: string;
  title: string | null;
  stops: UpsertTourStopInput[];
  totalDistanceKm: number | null;
  totalMinutes: number | null;
}

export function useSaveDraft() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (input: SaveDraftInput) => {
      const now = new Date().toISOString();
      const existing = input.id ? await tourRepo.byId(input.id) : null;
      const tourId = input.id ?? newId();
      const tour: Tour = {
        id: tourId,
        scheduledDate: null,
        departureTime: null,
        title: input.title,
        baseLat: existing?.tour.baseLat ?? 0,  // base réelle injectée au call-site
        baseLng: existing?.tour.baseLng ?? 0,
        status: 'draft',
        // … reste comme useUpsertTour
      };
      assertTourInvariants(tour);
      const stops = buildStops(input.stops, tourId);
      await tourRepo.upsertTour(tour, stops);
      return { tour, stops };
    },
    onSuccess: ({ tour }) => {
      void qc.invalidateQueries({ queryKey: toursKeys.all });
      void qc.invalidateQueries({ queryKey: ['kpis'] });
      qc.removeQueries({ queryKey: toursKeys.byId(tour.id) });
    },
  });
}

export interface ScheduleTourInput {
  id?: string;
  title: string | null;
  scheduledDate: string;                  // YYYY-MM-DD, requis
  departureTime: string;                  // HH:mm, requis
  baseLat: number;
  baseLng: number;
  stops: UpsertTourStopInput[];
  totalDistanceKm: number | null;
  totalMinutes: number | null;
}

export function useScheduleTour() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (input: ScheduleTourInput) => {
      // construit le tour avec status='planned' + date+time + title
      // assertTourInvariants(tour) avant upsert
      // upsert via tourRepo
    },
    onSuccess: ({ tour }) => {
      void qc.invalidateQueries({ queryKey: toursKeys.all });
      void qc.invalidateQueries({ queryKey: ['clients'] });
      void qc.invalidateQueries({ queryKey: ['kpis'] });
      qc.removeQueries({ queryKey: toursKeys.byId(tour.id) });
    },
  });
}
```

`useUpsertTour` actuel est **retiré entièrement**. Tous les call-sites migrent vers `useSaveDraft` ou `useScheduleTour`. Le découpage public garantit qu'aucun call-site ne peut accidentellement créer une tournée planifiée sans date. Si du code partagé entre les deux est utile (ex. construction des `stops` à partir de `UpsertTourStopInput[]`), il vit dans une fonction utilitaire privée non exportée du module.

### 6.2 Repo — tri par status

```ts
// src/data/repositories/tour-repository.ts
async listByStatus(status: TourStatus): Promise<Array<{ tour: Tour; stops: TourStop[] }>> {
  const orderBy = (() => {
    switch (status) {
      case 'draft':     return 'updated_at DESC';
      case 'planned':   return 'scheduled_date ASC';
      case 'completed': return 'scheduled_date DESC';
    }
  })();
  // SELECT … FROM tours WHERE status = ? ORDER BY <orderBy>
}
```

## 7. Éditeur — UI

### 7.1 Champ titre (haut de l'éditeur)

```tsx
<View className="gap-2">
  <Text className="text-sm font-medium">{t('tours.title_label')}</Text>
  <TextInput
    value={title ?? ''}
    onChangeText={(v) => setTitle(v.length > 0 ? v : null)}
    placeholder={t('tours.title_placeholder')}
    className="rounded-2xl px-4 py-3 bg-muted dark:bg-muted-dark"
  />
</View>
```

État local `title: string | null`. Initialement `null` (nouveau brouillon) ou la valeur du tour chargé.

### 7.2 Date/time pickers — comportement en mode draft

État local passe de `date: Date` à `date: Date | null`, et `time: string` à `time: string | null`. Initialement `null` pour un nouveau brouillon. Affichage "Optionnel" comme placeholder. L'utilisateur peut taper sur le picker pour les remplir, sinon ils restent null.

Édition d'une planifiée existante : `date` et `time` sont initialisés depuis les valeurs DB (non-null garanti par les invariants).

### 7.3 Boutons d'action (footer)

```tsx
<View className="px-4 pt-3 pb-6 border-t border-border dark:border-border-dark bg-background dark:bg-background-dark flex-row gap-2">
  {tourStatus !== 'planned' && tourStatus !== 'completed' ? (
    <Button
      variant="secondary"
      className="flex-1"
      onPress={onSaveDraft}
      disabled={saving || initialStops.length === 0}
    >
      <Text className="font-semibold">{t('tours.save_as_draft')}</Text>
    </Button>
  ) : null}
  <Button
    className="flex-1"
    onPress={() => setScheduleSheetVisible(true)}
    disabled={saving || initialStops.length === 0}
  >
    <Text variant="onPrimary" className="font-semibold">{t('tours.schedule_cta')}</Text>
  </Button>
</View>
```

Pour les tournées déjà planifiées (`tours/[id]/edit.tsx`), le bouton "Enregistrer brouillon" n'est pas rendu — seul "Planifier" est visible (label peut rester "Planifier" car la sémantique est "appliquer la planification").

### 7.4 Sheet `ScheduleTourSheet`

```tsx
// src/ui/components/schedule-tour-sheet.tsx

interface Props {
  visible: boolean;
  initialDate: Date | null;
  initialTime: string | null;
  onClose: () => void;
  onConfirm: (input: { date: Date; time: string }) => void;
}

export function ScheduleTourSheet({ visible, initialDate, initialTime, onClose, onConfirm }: Props) {
  const [date, setDate] = useState<Date>(initialDate ?? new Date());
  const [time, setTime] = useState<string>(initialTime ?? '08:00');
  const [showDatePicker, setShowDatePicker] = useState(false);
  const [showTimePicker, setShowTimePicker] = useState(false);

  // Modal transparent + Surface rounded-t-3xl, pattern aligné sur CreateTourSheet
  // Deux PressScale → Surface → Text qui ouvrent les DateTimePicker
  // Bouton Annuler (variant ghost) + Confirmer (primary) qui appelle onConfirm({ date, time })
}
```

### 7.5 Bouton "Supprimer brouillon"

Visible dans l'éditeur uniquement si :
- `id` est fourni (mode édition d'un draft existant)
- `tourStatus === 'draft'`

Position : à droite du `ScreenHeader` (slot d'action), icône `Trash2` rouge. Tap → `confirm()` → `useDeleteTour.mutate(id)` → `router.replace('/(tabs)/tours')`.

### 7.6 Chargement par `id`

```tsx
const { id } = useLocalSearchParams<{ id?: string }>();
const [title, setTitle] = useState<string | null>(null);
const [tourStatus, setTourStatus] = useState<TourStatus>('draft');

useEffect(() => {
  if (id) {
    void tourRepo.byId(id).then((result) => {
      if (!result) return;
      reset();
      setOrder(result.stops.map((s) => s.clientId));
      hydrateServices(
        result.stops.map((s) => ({ clientId: s.clientId, services: s.plannedServices })),
      );
      setTitle(result.tour.title);
      setTourStatus(result.tour.status);
      // également: setDate / setTime si non-null
    });
    return;
  }
  if (picked.length === 0) {
    router.push('/tour-new/pick-clients' as never);
  }
  // eslint-disable-next-line react-hooks/exhaustive-deps
}, [id]);
```

`hydrateServices` est l'action existante du `tour-draft-store` qui peuple `servicesByClient` en bloc.

### 7.7 Validations

| Cas | Comportement |
|-----|--------------|
| Stops < 1 | Les deux boutons sont disabled. |
| Stops sans services + tap "Planifier" | Confirm dialog "Continuer ?" comme aujourd'hui. |
| Stops sans services + tap "Enregistrer brouillon" | Pas de prompt. |
| `base` indisponible (settings non chargés) | Les deux boutons disabled (déjà géré pour Planifier aujourd'hui). |
| Tap "Planifier" puis Annuler dans la sheet | Aucune mutation, retour à l'éditeur, valeurs date/time éventuellement modifiées dans la sheet sont jetées. |

## 8. Liste Tournées — UI

### 8.1 SegmentedControl

```tsx
type Filter = 'draft' | 'planned' | 'completed';
const [filter, setFilter] = useState<Filter>('planned');

<SegmentedControl<Filter>
  value={filter}
  onChange={setFilter}
  options={[
    { value: 'draft',     label: t('tours.filter_draft') },
    { value: 'planned',   label: t('tours.filter_planned') },
    { value: 'completed', label: t('tours.filter_completed') },
  ]}
/>
```

Default `'planned'` (cohérent avec aujourd'hui).

### 8.2 Card brouillon

```
┌────────────────────────────────────────┐
│ [Brouillon]                          > │
│ 📝 Mardi nord                          │
│ 3 clients · modifié il y a 2 h         │
└────────────────────────────────────────┘
```

`tour-card.tsx` adapté :
- Status badge : nouveau preset `'draft'` → `bg-muted dark:bg-muted-dark` + texte `text-muted-foreground dark:text-muted-foreground-dark` + label `t('tours.draft_status_label')`.
- Pas de ligne `<Calendar/> {date}` quand `status==='draft'` (car date null).
- Titre principal : `tour.title ?? t('tours.draft_fallback_title', { date: format(parseISO(tour.createdAt), 'd MMM') })`.
- Sous-titre : `t('tours.stop_summary_count_label', { count: stopCount }) + ' · ' + formatDistanceToNow(parseISO(tour.updatedAt), { locale: fr, addSuffix: true })` — exemple : `"3 clients · modifié il y a 2 h"`.
- Pas d'appel `useTourKpis` pour les drafts (le hook reste appelé pour planned/completed).

### 8.3 Empty states

```jsonc
{
  "tours": {
    "draft_empty_title": "Aucun brouillon",
    "draft_empty_message": "Crée une tournée pour commencer un brouillon."
    // empty_filtered_title / empty_filtered_message inchangés pour planned/completed
  }
}
```

`tours/index.tsx` choisit la copie selon `filter`.

### 8.4 Tap sur card brouillon

```tsx
// app/(tabs)/tours/[id].tsx
useEffect(() => {
  if (tour?.status === 'draft') {
    router.replace(`/tour-new/draft?id=${tour.id}` as never);
  }
}, [tour?.status, tour?.id]);
```

Le mount de la vue détail détecte le draft et redirige immédiatement vers l'éditeur. Le user voit un flash bref de la vue détail (acceptable, sera optimisable plus tard si besoin via un préfiltre côté liste).

## 9. Tests

### 9.1 Domain (vitest, `tests/domain/`)

`assert-tour-invariants.test.ts` :

```ts
describe('assertTourInvariants', () => {
  it('accepts a draft with both date and time null');
  it('accepts a planned with both date and time set');
  it('accepts a completed with both date and time set');
  it('throws when planned has scheduledDate null');
  it('throws when planned has departureTime null');
  it('throws when completed has scheduledDate null');
  it('throws when draft has scheduledDate set');
  it('throws when draft has departureTime set');
});
```

### 9.2 Tests existants à actualiser

- `tests/data/tour-repository.test.ts` (s'il existe) : adapter aux nullable et au nouveau `title`.
- Tout `Tour({ … })` construit en test doit ajouter `title: null`.
- Vérifier qu'aucun test ne passe `useUpsertTour` directement (le hook n'est plus public).

### 9.3 Pas de tests UI

L'éditeur, la sheet de planification, la card brouillon sont validés en revue de PR + tests manuels iOS/Android (cf §11).

## 10. i18n (`fr.json`)

Nouvelles clés à ajouter (sans toucher les existantes) :

```jsonc
{
  "tours": {
    "filter_draft": "Brouillons",
    "draft_status_label": "Brouillon",
    "draft_fallback_title": "Brouillon du {{date}}",
    "save_as_draft": "Enregistrer brouillon",
    "schedule_cta": "Planifier",
    "schedule_sheet_title": "Planifier la tournée",
    "schedule_sheet_confirm": "Confirmer",
    "title_label": "Titre du brouillon",
    "title_placeholder": "Optionnel",
    "draft_empty_title": "Aucun brouillon",
    "draft_empty_message": "Crée une tournée pour commencer un brouillon.",
    "delete_draft_cta": "Supprimer le brouillon",
    "delete_draft_confirm_title": "Supprimer ce brouillon ?",
    "delete_draft_confirm_message": "Cette action est irréversible.",
    "stop_summary_count_label": "{{count}} client(e)s",
    "draft_modified_at": "modifié {{when}}"
  }
}
```

Un seul locale dans le repo (`fr.json`). Pas d'`en.json`.

## 11. Plan de validation manuelle

À jouer en ordre, avant merge :

1. **Migration sur DB pré-existante** : ouvrir l'app sur une DB qui contient au moins 1 tournée planifiée + 1 terminée → la migration s'applique au boot → tournées intactes (status préservés, dates préservées), `title` est `null` partout.
2. **Créer un brouillon depuis FAB Manuel** : FAB → Manuel → pick-clients → ajouter 2 clients → Enregistrer brouillon (titre vide) → toast success → arrivée sur l'index Tournées (filtre Planifiées par défaut). Switch sur Brouillons → la card "Brouillon du 8 mai · 2 clients" apparaît.
3. **Saisir un titre** : ouvrir le brouillon → taper "Mardi nord" → Enregistrer brouillon → la liste affiche "Mardi nord".
4. **Ajouter clients depuis Proximité** : Proximité → set pivot → "Créer tournée (3)" → arrivée sur l'éditeur avec 3 clients pré-remplis → Enregistrer brouillon → 2e card brouillon.
5. **Planifier un brouillon** : ouvrir un brouillon → Planifier → sheet date+time → Confirmer → toast → arrivée sur la liste, switch Planifiées → la tournée y est, le titre conservé.
6. **Supprimer un brouillon** : ouvrir un brouillon → bouton Supprimer (header) → confirm → la card disparaît.
7. **Sauver vide** : ouvrir l'éditeur sans aucun client → les deux boutons sont désactivés.
8. **Min 1 client respecté** : ajouter 1 client → boutons activés.
9. **Stop sans services + Planifier** : ajouter 1 client sans service → tap Planifier → confirm "Continuer ?" → OK → planifie.
10. **Stop sans services + Enregistrer brouillon** : ajouter 1 client sans service → Enregistrer brouillon → pas de prompt.
11. **Édition d'une planifiée** : ouvrir une planifiée → Edit → seul "Planifier" visible (pas de "Enregistrer brouillon"). Date/time pré-remplis. Pas de demote.
12. **Sync cloud** (si compte cloud activé) : créer un brouillon → ouvrir l'app sur un autre device (ou clear+restore) → le brouillon est là avec son titre et ses stops.
13. **Empty state brouillons** : si 0 brouillon → switch Brouillons → empty state correct.
14. **Tap card brouillon → éditeur** : depuis la liste filtre Brouillons → tap card → ouvre l'éditeur. Vérifier que le flash de `tours/[id].tsx` est imperceptible.
15. **Optimized-config flow** : FAB → Optimisé → choisir commune + radius → Continuer → arrivée sur l'éditeur → Enregistrer brouillon ou Planifier — comportement conforme.

## 12. Risques et points d'attention

- **Migration Supabase** non-couverte par cette spec : si la table miroir cloud n'est pas mise à jour, les brouillons ne se sync pas. À orchestrer côté backend en parallèle.
- **`useUpsertTour` retiré** : tous les call-sites doivent migrer vers `useSaveDraft` ou `useScheduleTour`. Le compilateur TS attrapera les oublis (nouvelle signature). Lister tous les call-sites au début de l'implémentation pour ne pas en oublier.
- **`tours/[id].tsx` redirect** : flash possible de la vue détail avant la redirection. Acceptable pour la MVP. Si le flash gêne, alternative future = filtrer côté liste pour pousser vers l'éditeur directement.
- **Données `title` manquantes** : pour les tours déjà existants, `title === null` post-migration. La card planned/completed doit continuer de fonctionner (elle affiche la date comme aujourd'hui, pas le titre). Aucun changement visuel pour les tours pré-existants.
