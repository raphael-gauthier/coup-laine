# Champs date/heure masqués avec picker — Design

**Date :** 2026-05-20
**Statut :** Validé (brainstorming)

## Problème

Chaque écran qui saisit une date ou une heure réimplémente le même bloc : un état
`showPicker`, un `PressScale` affichant la date formatée en lecture seule, et un
`<DateTimePicker>` inline. Conséquences :

1. **Pas de saisie clavier** — l'utilisateur doit obligatoirement passer par le
   picker natif, fastidieux pour entrer une date connue.
2. **Logique dupliquée** sur 7 sites (5 dates + 2 heures), donc fragile.
3. **Warning de dépréciation** : `DateTimePicker: onChange is deprecated. Use
   onValueChange, onDismiss, and onNeutralButtonPress instead.` (package
   `@react-native-community/datetimepicker@9.1.0`).

## Objectif

Remplacer ces blocs par un champ texte **masqué et éditable au clavier**, doublé
d'un **bouton picker** pour ceux qui préfèrent. Centraliser la logique pour
corriger le warning une seule fois.

## Périmètre

- **Dates ET heures** (décision validée).
- 7 sites : `settings/season.tsx`, `manual-history-form.tsx`, `payment-editor.tsx`,
  `tour-draft-editor.tsx` (date + heure), `schedule-tour-sheet.tsx` (date + heure).

### Hors périmètre

- Aucune nouvelle contrainte min/max : les bornes actuelles ne changent pas (les
  dates passées restent permises là où elles l'étaient).
- L'affichage long (« lundi 5 mai 2026 ») est abandonné au profit du champ
  éditable `JJ/MM/AAAA` — inhérent à un champ saisissable.

## Formats (convention française)

- Date : `JJ/MM/AAAA`
- Heure : `HH:MM` (24 h)

## Architecture

Deux composants présentationnels + une logique de parsing pure et testable.
Pas de wrapper react-hook-form dédié (YAGNI) : l'hôte RHF réutilise `DateField`
dans son `Controller` existant.

### `src/ui/components/date-field.tsx`

```ts
interface DateFieldProps {
  label: string;
  value: Date | null;
  onChange: (date: Date | null) => void;       // émis uniquement sur valeur valide
                                                // (ou null si vidé et !required)
  onValidityChange?: (valid: boolean) => void;  // pour griser le bouton Enregistrer
  required?: boolean;                            // défaut: true
  accessibilityLabel?: string;
}
```

Comportement :

- Masque `JJ/MM/AAAA` via `MaskInput` (`react-native-mask-input`, déjà installé) :
  `[/\d/, /\d/, '/', /\d/, /\d/, '/', /\d/, /\d/, /\d/, /\d/]`. Style aligné sur
  l'`Input` de l'app.
- Buffer texte interne initialisé depuis `value` (`format(value, 'dd/MM/yyyy')`).
  Un `useEffect` sur `value` resynchronise le buffer si la valeur change de
  l'extérieur (ex. bouton « Aujourd'hui » de l'écran saison).
- À chaque frappe, on parse via `parseDateInput` (cf. logique pure) :
  - **valide** → `onChange(date)`, pas d'erreur, validité `true` ;
  - **vide et `!required`** → `onChange(null)`, validité `true` ;
  - **invalide / incomplète** → erreur inline (via `FormField`), validité `false`,
    **et on n'émet pas `onChange`** : la dernière valeur valide de l'hôte est
    conservée.
- Bouton icône **calendrier** (lucide `Calendar`) à droite du champ. Au tap, ouvre
  `<DateTimePicker mode="date" value={value ?? new Date()} />` avec la **nouvelle
  API** : `onValueChange={(_, d) => { setText(format(d,'dd/MM/yyyy')); onChange(d); }}`
  et `onDismiss` pour fermer. Gestion de visibilité par plateforme conservée comme
  l'existant (Android : dialog one-shot ; iOS : inline).

### `src/ui/components/time-field.tsx`

Identique, avec :

- Masque `HH:MM` : `[/\d/, /\d/, ':', /\d/, /\d/]`.
- `value: string | null` au format `'HH:mm'`.
- Validation HH ∈ 00–23, MM ∈ 00–59.
- Icône **horloge** (lucide `Clock`) → `<DateTimePicker mode="time" />`.

### `src/domain/use-cases/parse-date-input.ts`

Fonctions pures, sans dépendance UI :

```ts
export function parseDateInput(text: string):
  | { ok: true; date: Date }
  | { ok: false; reason: 'empty' | 'invalid' };

export function parseTimeInput(text: string):
  | { ok: true; value: string }   // 'HH:mm'
  | { ok: false; reason: 'empty' | 'invalid' };
```

`parseDateInput` utilise date-fns `parse(text, 'dd/MM/yyyy', new Date())` + `isValid`,
en rejetant les chaînes incomplètes (< 10 caractères significatifs) et les dates
calendairement invalides (`32/13/2026`). `parseTimeInput` valide les bornes
horaires.

## Migration des hôtes

| Fichier | Champ(s) | Type de valeur stockée |
|---|---|---|
| `settings/season.tsx` | date | `Date` (state local) |
| `manual-history-form.tsx` | date | `Date` (RHF `Controller`) |
| `payment-editor.tsx` | date paiement | string ISO (`paidAt`) — converti `Date ↔ ISO` au bord |
| `tour-draft-editor.tsx` | date + heure | `Date` + `'HH:mm'` |
| `schedule-tour-sheet.tsx` | date + heure | `Date` + `'HH:mm'` |

Pour chaque hôte :

1. Remplacer le bloc `showPicker` + `PressScale` + `<DateTimePicker>` par
   `<DateField/>` ou `<TimeField/>`.
2. Griser le bouton Enregistrer/Confirmer via un état de validité alimenté par
   `onValidityChange` (un booléen par champ date/heure de l'écran).
3. Supprimer les `useState` de visibilité du picker et les imports devenus
   inutiles (`DateTimePicker`, `Platform`).

L'hôte RHF (`manual-history-form`) garde son `Controller` pour le plumbing
`field.value` / `field.onChange`, mais l'affichage du label et de l'erreur passe
désormais par le `FormField` interne de `DateField` (on ne double-wrappe pas).

Une fois les 7 sites migrés, plus aucun `onChange` de picker dans le code → le
warning de dépréciation disparaît.

## i18n

Nouvelles clés (valeurs FR uniquement, clés en anglais) :

```json
"dateField": {
  "placeholder": "JJ/MM/AAAA",
  "invalid": "Date invalide (JJ/MM/AAAA)"
},
"timeField": {
  "placeholder": "HH:MM",
  "invalid": "Heure invalide (HH:MM)"
}
```

Aucune chaîne française en dur dans le JSX.

## Tests

- **Unitaires (vitest, `tests/domain/`)** sur `parse-date-input.ts` : dates valides,
  `32/13/2026`, dates incomplètes, `25:70`, heures valides, chaîne vide.
- Pas de test de rendu de composant ajouté (le dépôt teste surtout domain/data ;
  la logique risquée est isolée dans les fonctions pures ci-dessus).

## Critères de succès

1. Sur les 7 sites, on peut saisir la date/heure au clavier au format masqué **et**
   ouvrir le picker.
2. Une saisie invalide affiche une erreur inline et empêche l'enregistrement.
3. `pnpm typecheck`, `pnpm lint`, `pnpm test` passent.
4. Plus de warning `onChange is deprecated` au runtime.

## RGPD

Aucun impact : pas de nouveau champ de données personnelles, pas de nouveau
sous-traitant, pas de changement de rétention. Refonte purement UI/saisie de
champs date existants.
