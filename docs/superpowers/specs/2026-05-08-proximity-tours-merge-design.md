# Proximity ↔ Tours merge — design

**Date:** 2026-05-08
**Scope:** Permettre la création d'une tournée optimisée directement depuis l'onglet Proximité (sans repasser par commune/radius), et harmoniser la carte Proximité pour que le tap sur un pin client ouvre le même bottom sheet que la carte principale.

## 1. Goals

- Bouton "Créer tournée (N)" en bas de Proximité, visible sur les vues *list* et *map*, qui pré-remplit le draft avec **pivot + nearbyClients** et lance directement l'optimisation ORS + TSP avant d'ouvrir `tours/new/draft`.
- Tap sur un pin client (incluant le pin pivot) sur la vue *map* de Proximité → ouverture du bottom sheet `ClientPinPopup`, identique à la carte principale, avec une action "Définir comme pivot" à la place de "Planifier".
- Réutiliser la routine d'optimisation déjà présente dans `optimized-config.tsx` via un use-case domaine pur, plutôt que de la dupliquer.
- Aucun nouvel onglet, aucune fusion d'onglets, aucun renommage. Les 5 onglets actuels restent intacts.

## 2. Non-goals

- Pas de fusion en un onglet unique. Les onglets Tournées et Proximité gardent leur existence séparée.
- Pas de bottom sheet sur la **vue liste** de Proximité — le tap sur `ClientCard` continue de pousser vers `/(tabs)/clients/{id}`.
- Pas de mode multi-sélection (case à cocher par client) dans Proximité. La sélection est implicite : "tout ce qui est dans le rayon, point". L'utilisateur peut affiner en réglant le pivot ou le rayon avant de tapper le bouton.
- Pas de cache des résultats ORS, pas de mode offline particulier, pas de progress feedback au-delà d'un spinner inline.
- Pas de suppression de l'écran `tours/new/optimized-config`. Il reste pour l'utilisateur qui part d'une commune et non d'un pivot client.
- Pas d'évolution du pivot pour qu'il puisse être autre chose qu'un client (la base, une adresse libre, etc.) — hors scope.

## 3. Architecture d'ensemble

```
┌─────────────────────────────────────────────────────────┐
│  app/(tabs)/proximity/index.tsx                         │
│                                                         │
│   pivot + nearbyClients (déjà calculés aujourd'hui)     │
│           │                                             │
│   vue map ─┼─ ClientPin onPress ──▶ setSelectedClient   │
│           │                          │                  │
│           │                          ▼                  │
│           │                   <ClientPinPopup           │
│           │                     planAction=             │
│           │                       "Définir comme pivot" │
│           │                   />                        │
│           │                                             │
│           ▼                                             │
│   bouton flottant inline → propose.mutate(...)          │
│           │                                             │
└───────────┼─────────────────────────────────────────────┘
            │
            ▼
┌─────────────────────────────────────────────────────────┐
│  src/state/queries/use-propose-optimized-tour.ts        │
│   useMutation:                                          │
│     ├─▶ proposeOptimizedTour(domain)                    │
│     │     ├─ build coords [BASE, ...candidates]         │
│     │     ├─ resolveMatrix (ORS)                        │
│     │     └─ optimizeTourOrder (TSP)                    │
│     ├─▶ tourDraftStore.reset()                          │
│     ├─▶ tourDraftStore.setOrder(orderedIds)             │
│     └─▶ router.push('/(tabs)/tours/new/draft')          │
└─────────────────────────────────────────────────────────┘
```

Pas de nouvel écran. Pas de nouveau store. Pas de nouvelle table.

## 4. Composants modifiés et ajoutés

### 4.1 Ajoutés

```
src/domain/use-cases/propose-optimized-tour.ts
src/state/queries/use-propose-optimized-tour.ts
tests/domain/propose-optimized-tour.spec.ts
```

### 4.2 Modifiés

```
app/(tabs)/proximity/index.tsx
src/ui/components/client-pin-popup.tsx
app/(tabs)/tours/new/optimized-config.tsx          (refactor pour réutiliser le use-case)
src/i18n/locales/fr.json                           (set_as_pivot, create_tour_cta)
src/i18n/locales/en.json
```

## 5. Use case domaine — `proposeOptimizedTour`

Pure, testable, sans React, sans zustand, sans router.

```ts
// src/domain/use-cases/propose-optimized-tour.ts
import type { MatrixCoord } from '@/infra/services/ors-routing';
import { optimizeTourOrder } from '@/domain/use-cases/tour-order-optimizer';

interface ProposeOptimizedTourInput {
  baseCoord: { lat: number; lon: number };
  candidates: { id: string; lat: number; lon: number }[];
  resolveMatrix: (coords: MatrixCoord[]) => Promise<{
    matrix: Map<string, { distanceKm: number }>;
  }>;
}

interface ProposeOptimizedTourResult {
  orderedIds: string[];
}

export async function proposeOptimizedTour(
  input: ProposeOptimizedTourInput,
): Promise<ProposeOptimizedTourResult> {
  const coords: MatrixCoord[] = [
    { id: 'BASE', lat: input.baseCoord.lat, lon: input.baseCoord.lon },
    ...input.candidates.map((c) => ({ id: c.id, lat: c.lat, lon: c.lon })),
  ];
  const result = await input.resolveMatrix(coords);
  const distanceKm = (from: string, to: string) =>
    result.matrix.get(`${from}-${to}`)?.distanceKm ?? 0;
  const orderedIds = optimizeTourOrder({
    stopIds: input.candidates.map((c) => c.id),
    distanceKm,
  });
  return { orderedIds };
}
```

Reproduit exactement la logique des lignes 103-131 de `app/(tabs)/tours/new/optimized-config.tsx`. Aucune divergence de comportement.

## 6. Hook React — `useProposeOptimizedTour`

```ts
// src/state/queries/use-propose-optimized-tour.ts
import { useMutation } from '@tanstack/react-query';
import { useRouter } from 'expo-router';
import { proposeOptimizedTour } from '@/domain/use-cases/propose-optimized-tour';
import { useResolveDistanceMatrix } from '@/state/queries/distance-matrix';
import { useTourDraftStore } from '@/state/stores/tour-draft-store';

export function useProposeOptimizedTour() {
  const resolve = useResolveDistanceMatrix();
  const reset = useTourDraftStore((s) => s.reset);
  const setOrder = useTourDraftStore((s) => s.setOrder);
  const router = useRouter();

  return useMutation({
    mutationFn: async (input: {
      baseCoord: { lat: number; lon: number };
      candidates: { id: string; lat: number; lon: number }[];
    }) => {
      const { orderedIds } = await proposeOptimizedTour({
        ...input,
        resolveMatrix: resolve.mutateAsync,
      });
      reset();
      setOrder(orderedIds);
      router.push('/(tabs)/tours/new/draft' as never);
    },
  });
}
```

Renvoie `{ mutate, isPending, error }` consommé directement par la vue.

## 7. Branchement Proximité — création de tournée

### 7.1 Bouton flottant

Visible quand `geocodedCandidates.length >= 2`. Position fixée en bas, mêmes coordonnées que le bouton "Continuer" de `tours/new/pick-clients.tsx` pour la cohérence visuelle.

```tsx
const propose = useProposeOptimizedTour();
const { data: base } = useBaseAddress();

const geocodedCandidates = useMemo(() => {
  const all = [pivot, ...nearbyClients];
  return all.filter(
    (c): c is typeof c & { latitude: number; longitude: number } =>
      c.latitude != null && c.longitude != null,
  );
}, [pivot, nearbyClients]);

const onCreateTour = () => {
  if (!base || geocodedCandidates.length < 2) return;
  propose.mutate(
    {
      baseCoord: { lat: base.lat, lon: base.lon },
      candidates: geocodedCandidates.map((c) => ({
        id: c.id,
        lat: c.latitude,
        lon: c.longitude,
      })),
    },
    {
      onError: (err) => {
        void haptics.error();
        errorToast(
          err instanceof Error ? err.message : t('tours.optimized_propose_failed'),
        );
      },
    },
  );
};

{geocodedCandidates.length >= 2 && base ? (
  <View className="absolute bottom-4 left-4 right-4">
    <Button onPress={onCreateTour} disabled={propose.isPending}>
      {propose.isPending ? <ActivityIndicator /> : <RouteIcon size={16} />}
      {t('proximity.create_tour_cta', { count: geocodedCandidates.length })}
    </Button>
  </View>
) : null}
```

### 7.2 Comportement

- Le bouton apparaît dans les vues *list* et *map* (l'utilisateur n'est pas obligé de switcher de vue).
- `propose.isPending` désactive le bouton et affiche un spinner inline.
- En cas d'erreur, toast + haptique d'erreur, aucune mutation du `tour-draft-store`.
- Au succès, `router.push` se déclenche depuis le hook ; le store est rempli avec l'ordre optimisé.

### 7.3 Refactor `optimized-config.tsx`

Le `onContinue` (lignes 103-140) est simplifié pour appeler `proposeOptimizedTour` (le use-case domaine, pas le hook) puisque l'écran a besoin de garder son propre state local `proposing` / `errorMsg` pour le rendu de la page :

```ts
const onContinue = async () => {
  if (!commune || !base) return;
  const selected = inRadius.filter((c) => !unchecked.has(c.id));
  if (selected.length === 0) {
    void haptics.error();
    setErrorMsg(t('tours.optimized_propose_empty'));
    return;
  }
  setProposing(true);
  setErrorMsg(null);
  void haptics.selection();
  try {
    const { orderedIds } = await proposeOptimizedTour({
      baseCoord: { lat: base.lat, lon: base.lon },
      candidates: selected.map((s) => {
        const c = clientsById.get(s.id)!;
        return { id: c.id, lat: c.latitude!, lon: c.longitude! };
      }),
      resolveMatrix: resolve.mutateAsync,
    });
    reset();
    setOrder(orderedIds);
    router.push('/(tabs)/tours/new/draft' as never);
  } catch (err) {
    void haptics.error();
    setErrorMsg(err instanceof Error ? err.message : t('tours.optimized_propose_failed'));
  } finally {
    setProposing(false);
  }
};
```

Le bloc supprime une dizaine de lignes (la construction des `coords` et l'appel à `optimizeTourOrder` sont absorbés par le use-case).

## 8. Branchement Proximité — bottom sheet harmonisé

### 8.1 Modification de `ClientPinPopup`

Ajout d'une prop optionnelle `planAction` qui, quand elle est fournie, override le bouton "Planifier" :

```ts
import type { LucideIcon } from 'lucide-react-native';

interface PlanAction {
  label: string;
  icon?: LucideIcon;
  onPress: () => void;
  disabled?: boolean;
}

interface Props {
  client: Client & { latitude: number; longitude: number };
  onClose: () => void;
  arrivalTime?: string;
  onNavigate?: () => void;
  planAction?: PlanAction;
}
```

Comportement par défaut (carte principale) inchangé : bouton "Planifier" → `setPivotId(client.id)` + `router.push('/(tabs)/proximity')`. Quand `planAction` est fourni, le rendu du bouton de droite (lignes 211-219 du fichier actuel) devient :

```tsx
const PlanIcon = planAction?.icon ?? RouteIcon;
const planLabel = planAction?.label ?? t('map.pin_popup_plan');
const planOnPress = planAction?.onPress ?? openPlan;
const planDisabled = planAction?.disabled ?? false;

<Button
  className="flex-1"
  variant="secondary"
  onPress={planOnPress}
  disabled={planDisabled}
  accessibilityLabel={planLabel}
>
  <PlanIcon size={16} color="#5C4E40" />
  <Text className="font-semibold">{planLabel}</Text>
</Button>
```

Le `setPivotId` import et le `useProximityStore` restent dans le popup pour le default.

### 8.2 Branchement dans `proximity/index.tsx`

Sur la vue *map* uniquement :

```tsx
const [selectedClient, setSelectedClient] = useState<GeoClient | null>(null);

// pivot pin :
<ClientPin
  client={pivot as GeoClient}
  onPress={() => setSelectedClient(pivot as GeoClient)}
/>

// nearby pins :
.map((c) => (
  <ClientPin key={c.id} client={c as GeoClient} onPress={() => setSelectedClient(c as GeoClient)} />
))

// popup, à la racine du <View flex-1> de la vue map :
{selectedClient ? (
  <ClientPinPopup
    client={selectedClient}
    onClose={() => setSelectedClient(null)}
    planAction={{
      label: t('proximity.set_as_pivot'),
      icon: Crosshair,
      disabled: selectedClient.id === pivot.id,
      onPress: () => {
        setPivotId(selectedClient.id);
        setSelectedClient(null);
        mapRef.current?.flyTo(selectedClient.longitude, selectedClient.latitude, 12);
      },
    }}
  />
) : null}
```

### 8.3 Comportement attendu

- Tap sur un pin (pivot ou nearby) → bottom sheet apparaît.
- Bouton "Définir comme pivot" :
  - *enabled* si le client sélectionné n'est pas le pivot courant → set le pivot, ferme le sheet, recentre la carte.
  - *disabled* si c'est déjà le pivot (cas du tap sur le pin central par curiosité).
- Tap sur le corps de la card (zone `PressScale openDetail`) → push détail client (comportement par défaut du popup).
- Bouton X (top-right) → ferme le sheet.
- Boutons "Itinéraire", "Appeler", "SMS" → comportement par défaut.

### 8.4 La vue *list* est intentionnellement non concernée

`ClientCard` continue de `router.push('/(tabs)/clients/{id}')` au tap (line 142 actuel). Décision validée pendant la phase de questions.

## 9. Data flow et erreurs

### 9.1 Data flow nominal

```
[user tap "Créer tournée (N)" sur Proximité]
    │
    ▼
useProposeOptimizedTour.mutate({ baseCoord, candidates })
    │
    ├─▶ resolveDistanceMatrix.mutateAsync(coords)   (ORS API)
    │
    ├─▶ optimizeTourOrder({ stopIds, distanceKm })  (pure TSP)
    │
    ├─▶ tourDraftStore.reset()
    ├─▶ tourDraftStore.setOrder(orderedIds)
    │
    └─▶ router.push('/(tabs)/tours/new/draft')
          │
          ▼
    [écran draft lit pickedClientIds depuis le store]
```

Au retour du draft (back), `tour-draft-store` reste peuplé jusqu'au prochain `reset()`. Comportement identique au flow `optimized-config` actuel — pas de régression.

### 9.2 Cas d'erreur

| Cas | Comportement |
|-----|--------------|
| `base` indisponible (settings non chargés) | Bouton non rendu (la condition `base ?` masque). Aucune erreur runtime. |
| `geocodedCandidates.length < 2` (pivot seul, pas de nearby géocodé) | Bouton non rendu. |
| `resolveMatrix` reject (network, ORS 5xx) | `errorToast(t('tours.optimized_propose_failed'))` + `haptics.error()`. Le `tour-draft-store` reste intact. L'utilisateur reste sur Proximité. |
| Matrice incomplète | `optimizeTourOrder` est tolérant via `?? 0`. Pas de crash. |
| Utilisateur back avant la fin de `mutate` | `mutate` continue, le `router.push` peut échouer silencieusement. Acceptable car aucun side-effect destructeur (le store est juste rempli inutilement, sera reset au prochain flow de création). |
| Client sélectionné devient le pivot pendant que le sheet est ouvert | Le bouton "Définir comme pivot" passe à *disabled* dès que `selectedClient.id === pivot.id`. |

### 9.3 RGPD

**Aucun impact RGPD.** Pas de nouveau champ stocké, pas de nouvelle donnée personnelle envoyée à un tiers, pas de nouveau sub-processor. ORS est déjà appelé par `optimized-config.tsx` ; on rebranche uniquement la même donnée (lat/lon clients) au même endpoint.

## 10. Tests

### 10.1 Domain (`tests/domain/`, vitest)

`propose-optimized-tour.spec.ts` :

- `BASE` est inclus comme premier coord du `resolveMatrix` call (vérification de l'argument).
- `candidates` sont passés tels quels avec leurs IDs ; `orderedIds` correspond au retour de `optimizeTourOrder` mocké.
- Si `resolveMatrix` reject, l'erreur est propagée sans état partiel.
- Si la matrice ne contient pas un couple `from-to`, la `distanceKm` retournée est `0` (et `optimizeTourOrder` ne crash pas).

### 10.2 Pas de tests data/infra (jest)

Le hook `useProposeOptimizedTour` est de la pure plomberie React Query + zustand + router. Pas de logique propre testable au-delà du domain.

### 10.3 Pas de tests UI

La prop `planAction` du popup et le bouton flottant de Proximité sont testés en revue de PR + tests manuels iOS/Android.

## 11. Internationalisation

Nouvelles clés à ajouter (`src/i18n/locales/fr.json` et `en.json`) :

```jsonc
{
  "proximity": {
    "create_tour_cta": "Créer tournée ({{count}})",
    "set_as_pivot": "Définir comme pivot"
  }
}
```

Anglais :

```jsonc
{
  "proximity": {
    "create_tour_cta": "Create tour ({{count}})",
    "set_as_pivot": "Set as pivot"
  }
}
```

## 12. Plan de validation manuelle

Avant merge :

1. Sur Proximité, choisir un pivot avec ≥2 clients géocodés dans le rayon → le bouton "Créer tournée (N)" apparaît avec le bon compteur sur les deux vues.
2. Taper le bouton → spinner ~1-3s, puis arrivée sur `tours/new/draft` avec les clients ordonnés (pivot inclus).
3. Couper le réseau → taper le bouton → toast d'erreur, reste sur Proximité.
4. Régler le rayon à 0 nearby → le bouton disparaît.
5. Vue *map* : taper sur un pin nearby → bottom sheet, "Définir comme pivot" enabled → tap → pivot change, sheet se ferme, carte recentre.
6. Vue *map* : taper sur le pin pivot → bottom sheet, "Définir comme pivot" disabled.
7. Vue *map* : taper sur le corps de la card du sheet → push vers détail client.
8. Carte principale (onglet Carte) : taper sur un pin → comportement inchangé, "Planifier" route vers Proximité comme avant.
9. `tours/new/optimized-config` : flow commune + radius → toujours fonctionnel après le refactor (régression).
