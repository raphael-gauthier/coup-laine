# Saisie en série de clients — Design

**Date** : 2026-05-20
**Statut** : validé (design)
**Approche retenue** : A — Redirection intelligente + raccourcis contextuels

## Problème

Lors de la reprise initiale d'une clientèle existante (onboarding), l'utilisateur
crée beaucoup de clients à la suite, chacun avec son historique complet
d'interventions (nombre variable : parfois 1-2, parfois davantage). Le parcours
actuel impose, pour chaque client :

1. FAB « + » sur la liste → modal de création (`app/(tabs)/clients/new.tsx`)
2. Save → `router.back()` ramène à la **liste**
3. Retrouver le client dans la liste, le taper → fiche client (`[id].tsx`)
4. Dans la fiche, « ajouter une intervention » → modal (`[id]/history/new.tsx`)
5. Save → retour fiche

Deux boucles sont pénibles :

- **Boucle externe** : finir un client → démarrer le suivant (oblige à repasser
  par la liste + recherche + tap).
- **Boucle interne** : ajouter plusieurs interventions au même client (un
  aller-retour fiche ↔ modal par intervention).

## Objectif

Fluidifier les deux boucles **en réutilisant les écrans et formulaires
existants**, sans créer de parcours parallèle. Coût et risque faibles.

## Conception

### 1. Atterrissage sur la fiche après création (boucle externe, 1/2)

`app/(tabs)/clients/new.tsx` : à la création, au lieu de `router.back()` vers la
liste, rediriger vers la fiche du client fraîchement créé en passant un flag
contextuel.

- `useUpsertClient` renvoie déjà l'objet `client` complet dans `onSuccess` — on
  dispose donc de `client.id`.
- Redirection : `router.replace({ pathname: '/(tabs)/clients/[id]', params: { id: client.id, justCreated: '1' } })`.
- **Ne concerne que la création.** L'édition (`app/(tabs)/clients/[id]/edit.tsx`)
  conserve strictement son comportement actuel.

**Risque technique à valider sur le dev client** : l'écran de création est en
présentation `modal`. Vérifier que la fiche (`[id].tsx`) ne **hérite pas** du
style modal après `router.replace`. La fiche ne déclare pas
`presentation: 'modal'`, donc elle devrait s'afficher en push normal. Repli si
besoin : `router.dismiss()` puis `router.push(...)` vers la fiche.

### 2. Bannière contextuelle « Nouveau client » (boucle externe, 2/2)

`app/(tabs)/clients/[id].tsx` lit le paramètre `justCreated` via
`useLocalSearchParams`. Quand il vaut `'1'`, la fiche affiche en haut du
`ScrollView` une bannière discrète :

> ✓ Client enregistré — **+ Ajouter un autre client**

- Le CTA fait `router.push('/(tabs)/clients/new')`.
- Le nouveau client créé re-déclenche la redirection (§1) vers sa propre fiche
  avec `justCreated: '1'` → la bannière réapparaît → **le cycle s'enchaîne**.
- La bannière persiste tant que l'écran de fiche reste monté : elle **survit aux
  allers-retours d'ajout d'intervention** (le push d'un modal ne démonte pas la
  fiche) et **disparaît** au retour vers la liste.
- Pas de bouton de fermeture (choix minimal). La bannière étant non intrusive et
  uniquement présente sur un client tout juste créé, elle ne gêne pas l'usage
  courant.

### 3. « Enregistrer et ajouter une autre » sur l'intervention (boucle interne)

`src/ui/components/manual-history-form.tsx` :

- Nouvelle prop `allowAddAnother?: boolean` (défaut `false`). Quand `true`, le
  formulaire affiche un **second bouton** « Enregistrer et ajouter une autre » à
  côté du bouton « Enregistrer » existant.
- La signature de `onSubmit` devient
  `onSubmit: (input: UpsertManualHistoryInput, opts: { addAnother: boolean }) => void | Promise<void>`.
- Le bouton pressé détermine `addAnother`. `onValid` `await`-e `onSubmit(...)`
  puis, **si `addAnother` est vrai et que la soumission a réussi**, réinitialise
  le formulaire : date = aujourd'hui, notes vide, `services = []`,
  `travelFeeCents = 0`, `payment` = défaut (`{ ...EMPTY_PAYMENT, isPaid: true }`),
  `methodError = null`. Un `try/catch` autour du `await` évite le reset si la
  mutation rejette (l'entrée n'est pas perdue, l'utilisateur corrige).

`app/(tabs)/clients/[id]/history/new.tsx` :

- Passe `allowAddAnother`.
- Câble `onSubmit` sur `upsert.mutateAsync(input)` : déclenche `haptics.success()`,
  puis `router.back()` **uniquement si `!addAnother`**. En cas d'erreur,
  remonter via `mutationErrorToast` (et laisser `mutateAsync` rejeter pour que le
  formulaire ne se réinitialise pas).

`app/(tabs)/clients/[id]/history/[entryId].tsx` (édition d'une intervention) :
**ne passe pas** `allowAddAnother` → comportement inchangé.

### 4. i18n

Clés en anglais, valeurs FR dans `src/i18n/locales/*.json` :

- Titre / confirmation bannière (ex. `clients.just_created_banner_title`)
- CTA bannière (ex. `clients.just_created_banner_cta` → « Ajouter un autre client »)
- Label bouton (ex. `history.manual.save_and_add_another` → « Enregistrer et
  ajouter une autre »)

(Noms de clés exacts à finaliser à l'implémentation en suivant les conventions du
fichier de locales.)

## RGPD

**Aucun impact.** Pas de nouveau champ stockant des données personnelles, pas de
nouveau service/SDK, aucun changement aux flux de rétention / suppression /
export / consentement, pas de nouveau traceur. La feature se limite à du
recâblage de navigation et à une réinitialisation de formulaire côté UI.

## Critères de vérification

- Créer un client → atterrissage **direct sur sa fiche**, bannière visible.
- Bannière → « + Ajouter un autre client » → modal de création → save → nouvelle
  fiche **avec bannière** (cycle vérifié sur ≥ 2 itérations).
- Intervention → « Enregistrer et ajouter une autre » → formulaire **vierge**,
  modal **toujours ouvert**, et l'entrée précédente est bien **persistée**
  (visible dans la liste des interventions après fermeture).
- Intervention → « Enregistrer » (bouton classique) → **retour fiche**
  (comportement inchangé).
- Édition d'un client → comportement **inchangé** (pas de bannière, retour
  habituel).
- Édition d'une intervention → comportement **inchangé** (pas de bouton « ajouter
  une autre »).
- Mutation d'intervention en erreur pendant « ajouter une autre » → le formulaire
  **ne se réinitialise pas**, l'erreur est remontée.

## Hors périmètre

- Assistant de reprise dédié / mode import (approche B).
- Écran combiné client + interventions (approche C).
- Modification de la prominence du bouton « ajouter une intervention » sur la
  fiche.
- Bouton de fermeture de la bannière.
