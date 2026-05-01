# Refonte UI/UX — Modern Craft (v3)

> Troisième passe UI majeure. Reset complet de l'identité visuelle et refonte fonctionnelle de tous les écrans pour absorber les grosses features récentes (pivot multi-praticien, catalogue de prestations, multi-phones, historique manuel) qui ont rendu l'UI actuelle (Pastoral Chic v2) sous-dimensionnée et chargée d'infos manquantes.

## Contexte

Le pass v2 « Pastoral Chic » (palette sage + terracotta, Fraunces serif, illustrations) a été shipé avant le pivot multi-praticien et le catalogue de prestations. Depuis, plusieurs douleurs se sont accumulées :

- **Densité d'info trop faible** : statut client réduit à un dot 12px sans label ; hero card des écrans-détail dupliquant l'info animaux ; pas de stats agrégées (revenu cumulé client, revenu mois, distance totale, dernière intervention) ; historique sans groupement temporel.
- **Hiérarchie plate** : titres de tiles peu différenciés du body, badges minuscules, primary/secondary peu distincts, motion absent.
- **Boutons d'action mal placés** : edit/delete coincés top-right en icônes sans label, pas d'`AppActionBar` sticky, FABs dispersés.
- **Patterns incohérents** : forms validés au save uniquement, confirmations destructives ad-hoc, empty states inégaux, search/filter implémentés différemment d'un écran à l'autre.
- **Identité visuelle vieillissante** : pastoral chic ne correspond plus à la cible *outil pro de gestion quotidienne* — le serif Fraunces et le ton « lifestyle » sonnent décoratifs face à la densité d'info à afficher.

Cette refonte vise à transformer Coup'Laine en **outil pro dense, sobre et signature**, dans la veine Superhuman / Arc / Cron / Things 3, adapté à un usage majoritairement de planification le soir avec consultation occasionnelle en mobilité.

## Goals

- **Identité visuelle Modern Craft** : palette vert forêt + cuivre, Inter sans-serif unique, hairlines 0.5px, motion soigné, icon set custom (pictogrammes métier).
- **Densité d'info élevée** sur tous les écrans-clés : KPI rows, stats agrégées, breakdowns visibles sans scroll.
- **Refonte fonctionnelle de tous les écrans** : foundations + screens migrés en une passe globale (phasée à l'implémentation).
- **Patterns globaux unifiés** : header + action bar sticky, validation inline, confirmations destructives standardisées, search/filter cohérent, loading/empty/error états standardisés.
- **Nouveaux composants signature** : `AppKpiCard`, `AppKpiRow`, `AppListTile` (3 variantes), `AppHeader`, `AppActionBar`, `AppTimelineRow`, `AppStat`, `AppDiffRow`, `AppCommandPalette`, `AppSkeleton`, `AppErrorState`.

## Non-goals

- Pas de changement de routing / navigation (`GoRouter` + `StatefulShellRoute` inchangés).
- Pas de changement de logique métier / data / providers / schéma Drift.
- Pas de transitions custom entre routes (transitions Material par défaut).
- Pas de tests widget pour la refonte (la base de tests widget est quasi-inexistante ; smoke tests manuels en remplacement, cohérent avec la pratique du repo).
- Pas de personnalisation des libellés de statuts client (autre chantier — `TODO.md` #3).
- Pas de synchronisation cloud / multi-device (autre chantier — `TODO.md` #1).
- Pas d'audit a11y complet (on respecte les bonnes pratiques contraste/touch/labels mais on n'industrialise pas).

---

## 1. Fondations (Design System v3)

### 1.1 Palette

**Light mode** (mode principal — usage majoritaire de planification du soir, en intérieur)

| Token | Hex | Usage |
|---|---|---|
| `background` | `#FAF8F3` | Fond global (ivoire chaud) |
| `surface` | `#FFFFFF` | Cards, sheets, dialogs |
| `surfaceMuted` | `#F2EFE8` | Cards secondaires, sections groupées |
| `foreground` | `#1B1F1A` | Texte principal (quasi-noir vert) |
| `mutedForeground` | `#6B6F66` | Texte secondaire, labels |
| `subtleForeground` | `#9CA09A` | Texte tertiaire, helper, placeholder |
| `primary` | `#1F3A2E` | CTA, états actifs, accents principaux (vert forêt profond) |
| `primaryForeground` | `#FAF8F3` | Texte sur primary |
| `accent` | `#B8895C` | Chiffres-clés, highlight ponctuel (cuivre/laiton) |
| `border` | `#E8E4DA` | Hairlines 0.5px |
| `borderStrong` | `#D4CEBE` | Bordures cards (1px) |
| `success` | `#3F7D58` | Statut « complété/done » par défaut |
| `warning` | `#C4663F` | Statut « planifié/scheduled » par défaut |
| `destructive` | `#A8403E` | Delete, statut « banni » par défaut |
| `info` | `#3E6A82` | Statut « waiting » par défaut |

**Dark mode** (secondaire mais soigné)

| Token | Hex |
|---|---|
| `background` | `#0F1311` |
| `surface` | `#1A1F1C` |
| `surfaceMuted` | `#222825` |
| `foreground` | `#EDEAE2` |
| `mutedForeground` | `#9CA09A` |
| `subtleForeground` | `#6B6F66` |
| `primary` | `#7DA08B` |
| `primaryForeground` | `#0F1311` |
| `accent` | `#D4A47A` |
| `border` | `#2A302D` |
| `borderStrong` | `#3A413D` |
| `success` | `#6FA786` |
| `warning` | `#E08763` |
| `destructive` | `#D46B68` |
| `info` | `#6B96B0` |

**Décisions** :

- L'**accent cuivre** (`#B8895C`) ne sert **que** pour les chiffres-clés (revenu, distance, durée totale d'une tournée) et les badges de hero card. Jamais pour les CTA — qui sont en `primary`.
- Les couleurs des **statuts client** (`waiting`/`scheduled`/`done`/`noAnimals`/`banned`) deviennent les nouveaux defaults ; le mécanisme actuel (`Settings.markerXxxColor` persisté, customisable) est conservé sans changement.
- Tous les contrastes WCAG AA (4.5:1) sont vérifiés à l'implémentation.

### 1.2 Typographie

**Une seule famille : Inter (variable)**. Pas de serif. Drop complet de Fraunces.

| Token | Taille | Weight | Letter-spacing | Usage |
|---|---|---|---|---|
| `display` | 36 | 700 | -1.0 | Hero numbers (revenu tournée, distance totale) — **tabular** |
| `title-xl` | 28 | 600 | -0.5 | Page title |
| `title-lg` | 22 | 600 | -0.3 | Section title, dialog title |
| `title-md` | 18 | 600 | -0.2 | Card title, list group header |
| `title-sm` | 16 | 600 | -0.1 | Tile title (nom client, date tournée) |
| `body` | 15 | 400 | 0 | Texte courant |
| `body-sm` | 13 | 400 | 0 | Texte secondaire (ville, sous-titre) |
| `label` | 12 | 500 | 0.2 | Labels formulaire, badges |
| `caption` | 11 | 500 | 0.4 | Caption UPPERCASE pour group headers |

**Tabular figures activées** systématiquement pour les chiffres (montants, durées, distances) via `FontFeature.tabularFigures()` — alignement parfait dans les listes.

**Italique** utilisé volontairement pour info secondaire à l'intérieur d'une tile (ex. ville sous nom client, breakdown prestations sous date d'historique).

### 1.3 Spacing, radius, sizes

**Spacing scale** (multiples de 4) — base actuelle conservée + ajouts :

```
xxxs = 2   (NEW — hairline gap)
xxs  = 4
xs   = 8
sm   = 12
md   = 16
lg   = 24
xl   = 32
xxl  = 48
huge = 64  (NEW — empty states, hero spacing)
```

**Radius** — resserrés (effet plus pro, moins « guidé débutant ») :

```
sm   = 6   (était 8)  — boutons, inputs
md   = 10  (était 12) — cards, tiles
lg   = 16  (était 24) — sheets, hero cards
pill = 999 — gardé
```

**Sizes** — descendus :

```
primaryButtonHeight   = 52  (était 56)
secondaryButtonHeight = 44  (était 48)
iconButtonSize        = 44  (gardé)
textFieldMinHeight    = 48  (était 56)
sectionIconCircle     = 28  (était 32)
heroIconCircle        = 56  (était 72)
```

Touch targets restent ≥44dp (conforme aux specs Android/iOS).

### 1.4 Motion

| Token | Durée | Courbe | Usage |
|---|---|---|---|
| `instant` | 0ms | — | Tap feedback (color change) |
| `fast` | 120ms | `easeOut` | Boutons, switches, expand small |
| `normal` | 200ms | `easeOutCubic` | Sheets, dialogs, expand grands blocs |
| `emphasized` | 280ms | `cubicEmphasized` (Material) | Hero element morph, KPI updates |

**Patterns concrets** :

- **Sheets** : slide-up + fade en 200ms, drag-to-dismiss avec snap.
- **Cards tap** : scale 0.98 + opacity 0.95 en 80ms (instantané ressenti).
- **Stop reorder dans tour draft** : long-press → lift de 4dp avec ombre douce + haptique.
- **Number changes** (hero, totaux) : crossfade 200ms quand un total se met à jour.
- **Pas de motion gratuite** : pas de bounces ; pas d'anims sur scroll ; pas de page-transition custom.

### 1.5 Icon set

**Stratégie** : Lucide en base (déjà utilisé via `FIcons` Forui) **+ 8-10 pictogrammes custom métier** dessinés au même style (stroke 1.75px).

Pictogrammes custom à créer (SVG, à placer dans `assets/icons/`) :

- `cl_shears` — cisaille de tonte (remplace `FIcons.scissors`)
- `cl_sheep` — silhouette mouton de profil
- `cl_horse`, `cl_cow`, `cl_goat` — autres espèces seed
- `cl_route_pin` — drapeau-jalon de tournée
- `cl_route_loop` — boucle de tournée
- `cl_farm_home` — bâtiment de ferme (remplace `FIcons.home` pour adresse de base)
- `cl_clip_check` — clipboard tonte effectuée

Toutes les autres icônes UI restent Lucide via `FIcons`.

### 1.6 Composants signature

**Conservés et redessinés** :

- `AppPrimaryButton` — descend à 52dp, label-only par défaut (pas de prefixIcon imposé), variantes `primary` / `outline` / `destructive`.
- `AppSectionCard` — surface blanc + 0.5px border, header icon 28dp + title-md + optional trailing action ; padding 20dp.
- `AppEmptyState` — pictogramme custom (cl_shears/cl_sheep selon contexte) + title-lg + body + 1 CTA primary + 1 secondary optionnel ; centré.
- `AppBadge` — pill ou square ; size sm/md ; couleur sémantique ; **icône + label** par défaut (plus de bare dots).
- `AnimalCountsBadges` — gardé, redesigné avec icônes custom espèces.

**Déprécié** :

- `AppHeroCard` — remplacé par `AppKpiCard` (un seul KPI) et `AppKpiRow` (3-4 KPIs côte à côte). L'ancien hero gradient + border asymétrique disparaît.

**Nouveaux** :

- **`AppKpiCard`** — un grand chiffre tabular (`display 36`) en accent cuivre, label dessous (caption UPPERCASE muted), optionnel : delta vs période précédente, mini-sparkline (8-12 points). Padding 20dp, surface, border 0.5px.
- **`AppKpiRow`** — rangée de 2-4 mini-KPIs (chiffre + label) séparés par hairlines verticales. Ex. sur tour detail : `5 stops · 47 km · 6h12 · 480 €`.
- **`AppListTile`** — remplace les `FTile` directs. Surface blanche, border 0.5px, padding 14×16. 3 variantes :
  - `compact` — 1 ligne (`prefix + title + suffix`).
  - `standard` — 2 lignes (titre + subtitle italique).
  - `rich` — 3-4 lignes (titre, subtitle italique, metadata row, suffix).
- **`AppHeader`** — remplace `FHeader.nested`. `title-lg` + optional subtitle muted + actions trailing. **Labels visibles tant que l'écran a l'espace ≥360dp utilisable** ; en dessous, fallback icon-only avec tooltip 1.2s sur tap-and-hold.
- **`AppActionBar`** — barre d'actions secondaires sticky en bas pour écrans-détail (hauteur 64dp + safe-area, surface blanc + hairline top). 1 CTA primary plein-largeur, OU 1 primary + 1 outline (50/50), OU 3 outline répartis. Maximum 3 actions.
- **`AppCommandPalette`** — sheet plein-écran déclenchée par long-press sur le `AppHeader.title`. Recherche universelle : clients, tournées, prestations, paramètres ; navigation rapide aux écrans (« Aller à : Catalogue prestations »).
- **`AppTimelineRow`** — ligne d'historique dense : indicateur temporel à gauche (date verticale en label), pictogramme métier (`cl_shears` ou `cl_clip_check`), titre court, breakdown prestations en italique, montant + durée à droite tabular. Utilisé sur Client history et timeline de stops dans Tour detail.
- **`AppStat`** — micro-composant inline : `<icon> <number tabular> <unit muted>`. Brique de base de tous les KPIs et metadata rows.
- **`AppDiffRow`** — affiche prévu vs effectué côte à côte avec icône delta. Spécifique au Tour completion. Ex : `Tonte ~~5~~ → 6 (⬆ +1)`.
- **`AppFAB`** — remplace les `FloatingActionButton` Material. 56dp, primary fill, icon Lucide, position bottom-right. Variant `extended` avec label visible (collapse en icon-only après scroll).
- **`AppSkeleton`** — placeholders shimmer en `surfaceMuted` (1.2s). Remplace `FCircularProgress` centré sur les listes.
- **`AppErrorState`** — icône `triangleAlert` en `destructive`, message clair, bouton « Réessayer » primary, bouton « Détails » outline (toggle stack trace pour debug).

---

## 2. Patterns globaux

### 2.1 Navigation

**Bottom nav** : 4 destinations conservées (`Clients`, `Tournées`, `Carte`, `Paramètres`).

- Hauteur 56dp + safe-area.
- `surface` background, hairline 0.5px en haut.
- Item actif : icône `primary` fill + label `primary` 11px, **pin indicator 24×3dp** au-dessus de l'icône (signature : ligne fine au lieu de pastille).
- Item inactif : icône `subtleForeground`, label `mutedForeground`.
- Transition entre tabs : fade-only 120ms (plus de slide).

**Sub-pages** : restent sur `GoRoute` push avec `AppHeader`, swipe-back natif Android. Pas de changement structurel de routing.

**Command palette** : déclenchée par long-press sur le `AppHeader.title` (premier ship). Pas de bouton dédié dans la bottom nav pour ce premier passage.

### 2.2 Layout / Scaffold

Structure unifiée :

```
FScaffold
└── SafeArea (top: true)
    └── Column
        ├── AppHeader  (fixe, hauteur ~64dp)
        ├── Content    (CustomScrollView ou Column scrollable)
        └── AppActionBar  (sticky bottom, optionnel — uniquement écrans-détail)
```

`AppHeader` :

- Hauteur 64dp + padding `screenPaddingH`.
- Layout : `[back?] [title-lg + subtitle?] [trailing actions]`.
- Actions trailing : labels visibles ≥360dp utilisable, sinon icon-only + tooltip.
- Sur top-level (depuis bottom nav) : pas de back, mais icône `search` à droite déclenchant la command palette.

`AppActionBar` :

- Hauteur 64dp + safe-area bottom.
- N'apparaît que si l'écran a une action « finale » (compléter tournée, sauvegarder, supprimer).

### 2.3 Loading / Empty / Error

3 états standardisés :

- **Loading** : `AppSkeleton` (texte + cards en `surfaceMuted`, shimmer subtil).
- **Empty** : `AppEmptyState` redesigné (pictogramme custom, title-lg, body muted, 1 CTA primary + 1 secondary optionnel).
- **Error** : `AppErrorState` (icône `triangleAlert` destructive, bouton `Réessayer` primary).

### 2.4 Formulaires

**Validation inline systématique** — fini le « tout au save » :

- Validation `onBlur` du champ → message d'erreur 12dp en dessous, `destructive` color, icône `alertCircle` 14px.
- Indicateur `check` 14px en `success` quand un champ obligatoire est rempli valide.
- CTA save reste **toujours actif** : si invalide, tap → toast « Vérifie les champs en rouge » + scroll au premier champ erroné. Pas de bouton désactivé.

**Pattern textfield** :

- Hauteur 48dp, surface blanc, border 1px `borderStrong` au repos, `primary` 1.5px focused.
- Label flottant en `caption` UPPERCASE au-dessus du champ. Placeholder = exemple de saisie.
- Helper text 12dp muted en dessous (description), remplacé par error en destructive si invalid.

**Pattern reorderable list** (multi-phones, prestations dans tour draft) :

- Drag handle visible à gauche (`gripVertical`, `subtleForeground`).
- Long-press 200ms → lift + haptique légère + ombre douce 8dp.
- Drop avec spring rapide.

### 2.5 Actions destructives

Tout delete passe par confirm dialog :

- `FDialog`, title `title-lg` direct (« Supprimer ce client ? »), body court qui explique la conséquence concrète (« 12 interventions seront perdues. Cette action est irréversible. »).
- 2 actions : `Annuler` outline + `Supprimer` destructive.
- Pas de timer ni de saisie de confirmation.
- Snackbar d'undo 5s quand techniquement réversible côté UI.

### 2.6 Feedback / micro-interactions

- **Discret** (tap tile, switch, checkbox) : color change instantané + `HapticFeedback.selectionClick`.
- **Notable** (CTA validé, save réussi, suppression) : toast `FToast` en haut, 3s, icône + message (`success` / `destructive`).
- **Bloquant** (recompute distances, optimisation, export) : sheet bottom modale avec progress + label texte. Pas de spinner anonyme.

**Haptiques** :

- `selectionClick` : tap tile, switch, checkbox, tab change.
- `lightImpact` : tap CTA primary, drag start (reorder).
- `mediumImpact` : action validée (tournée complétée, client sauvegardé).
- `heavyImpact` : action destructive confirmée.

### 2.7 Recherche & filtres

Pattern unifié pour Clients list / Tours list / Map / Catalogue prestations :

- **Search field** sticky sous l'`AppHeader`, hauteur 44dp, full-width, icône `search` en prefix `subtleForeground`, icône `x` en suffix quand non-vide.
- **Filter button** carré 44dp à droite, ouvre une **bottom sheet** (pas un dialog) listant les filtres avec switches/chips.
- Indicateur visuel quand filtre non-default actif : pastille `accent` cuivre top-right du bouton.
- **Chips de filtres actifs** sous le search field, dismissible (tap → retire le filtre).

### 2.8 Pull-to-refresh

`RefreshIndicator` Material custom : couleur `primary`, élévation 0, fond `surface`. Haptique légère au trigger.

---

## 3. Refonte des 4 écrans prioritaires

### 3.1 Tour detail

**Intention** : en un coup d'œil, comprendre la tournée — quand, qui, combien rapporté/à rapporter, dans quel ordre — et passer à l'action (compléter, modifier, partager).

**Wireframe** :

```
─────────────────────────────────────────
[← back]   Tournée du 12 mai     [⋯ menu]
           Mardi · 5 stops · planifiée
─────────────────────────────────────────
┌─ AppKpiRow ─────────────────────────┐
│ 47.2 km │ 6 h 12 │ 480 €  │ 12 🐑   │
│ distance│ durée  │ revenu │ animaux │
└─────────────────────────────────────┘

  Trajet                          [carte]
┌─────────────────────────────────────┐
│  mini-map preview avec route et      │
│  pins numérotés des stops 1→5        │
│  tap → carte plein-écran             │
└─────────────────────────────────────┘

  Étapes
  ┌─ AppListTile rich (par stop) ────┐
  │ ① 09:00 · M. Le Goff             │
  │   Ploudaniel · 12 km depuis base │
  │   3 Tontes Petit · 1 Parage      │
  │                       180 €  45m │
  └──────────────────────────────────┘
  ┌─ stop ② … ────────────────────── ┐
  ...

  Résumé prestations
  ┌─ AppSectionCard ─────────────────┐
  │ Tonte Petit          ×8    240 € │
  │ Tonte Grand          ×3    180 € │
  │ Parage               ×1     60 € │
  │ ──────────────────────────────── │
  │ Total                      480 € │
  └──────────────────────────────────┘

(scroll bottom: ~80dp clearance)
─────────────────────────────────────────
[ AppActionBar ]
  ┌─ « Compléter la tournée »  primary ─┐
  └─────────────────────────────────────┘
```

**Variante `tournée complétée`** : `AppKpiRow` montre les valeurs réelles (ajustées au bilan) ; section « Résumé prestations » sur 2 colonnes prévu / réalisé ; `AppActionBar` affiche `[Modifier non disponible · Partager le bilan outline]`.

**Info ajoutée vs actuel** :

- `AppKpiRow` 4 valeurs au lieu d'un hero card avec juste la distance.
- Mini-map preview de la route — actuellement absente.
- Stop tile riche : horaire estimé, ville, distance depuis le précédent, breakdown prestations, montant + durée — actuellement « nom + count animaux ».
- Nouveau bloc « Résumé prestations agrégé » par catégorie sur l'ensemble de la tournée.
- Statut affiché en sous-titre du header au lieu d'un badge perdu.

**Interactions** :

- Tap mini-map → carte plein-écran avec pins numérotés et route tracée.
- Tap stop tile → fiche client de ce stop.
- Long-press stop tile → sheet « Réordonner les étapes » (uniquement si planifiée).
- Menu `⋯` du header : `Modifier`, `Partager le récap`, `Dupliquer`, `Supprimer` (destructive).
- Pull-to-refresh recharge tournée + recompute distances si nécessaire.

### 3.2 Client detail

**Intention** : profil 360° d'un client — qui, où, contacts, animaux, état actuel, historique, prochaine action prévue. Densifier sans scroll long.

**Wireframe** :

```
─────────────────────────────────────────
[← back]   Mme Kervella           [⋯ menu]
           Plouguerneau · client depuis 2024
─────────────────────────────────────────
  ┌─ AppKpiRow ──────────────────────┐
  │ 3 ans │ 14 │ 1 240 € │ il y a 8 mois│
  │ client│interv│ revenu │ dernière   │
  └──────────────────────────────────┘

  ● en attente · saison 2026
  ┌─ AppSectionCard « Prochaine action »─┐
  │ Aucune tournée planifiée             │
  │ [ + Planifier maintenant ] primary sm │
  └──────────────────────────────────────┘
  (ou si scheduled)
  ┌─ AppSectionCard « Prochaine action »─┐
  │ Mardi 12 mai · 09:00                 │
  │ Tournée #142 · 3 Tonte Petit · 60 €  │
  │ → Voir la tournée                    │
  └──────────────────────────────────────┘

  Animaux
  ┌─ AppSectionCard ─────────────────────┐
  │ ● 8 Moutons                          │
  │ ● 3 Chevaux                          │
  │ ● 1 Bovin                            │
  └──────────────────────────────────────┘

  Coordonnées
  ┌─ AppSectionCard ─────────────────────┐
  │ 📍  12 route de Lampaul              │
  │     29880 Plouguerneau               │
  │     [ Itinéraire ]  [ Copier ]       │
  │ ──────────────────────────────────── │
  │ 📞  06 12 34 56 78  (principal)      │
  │     [ Appeler ]  [ SMS ]             │
  │ 📞  02 98 11 22 33                   │
  │     [ Appeler ]  [ SMS ]             │
  └──────────────────────────────────────┘

  Notes (si présentes)
  ┌─ AppSectionCard ─────────────────────┐
  │ « Parking devant le hangar gauche.   │
  │   Préfère matinée. »                 │
  └──────────────────────────────────────┘

  Historique  (3 derniers + lien)
  ┌─ AppTimelineRow ─────────────────────┐
  │  03 sept 2025 · ✂ Tournée #128       │
  │  3 Tonte Petit · 1 Parage    180 € 45m│
  │  ──────────────────────────────────  │
  │  18 mai 2025 · ✏ Saisie manuelle     │
  │  2 Onglons                    60 € 20m│
  │  ──────────────────────────────────  │
  │  12 sept 2024 · ✂ Tournée #98        │
  │  ...                                 │
  └──────────────────────────────────────┘
       [ Voir tout l'historique → ]

(bottom 80dp)
─────────────────────────────────────────
[ AppActionBar ]
  [ + Tonte manuelle ] outline  | [ Modifier ] outline
─────────────────────────────────────────
```

**Info ajoutée vs actuel** :

- `AppKpiRow` synthèse : ans-de-relation / nb-interventions / revenu cumulé / dernière intervention en relatif.
- Bloc « Prochaine action » dédié (actuellement éclaté).
- Statut affiché en chip + saison contextuelle.
- Coordonnées avec actions inline (`Itinéraire`, `Copier`).
- Phones avec marqueur « principal » explicite.
- Timeline historique avec **3 dernières entrées visibles directement** (au lieu d'une section repliée) + lien vers full.
- Notes remontées en card dédiée si présentes (actuellement noyées).

**Interactions** :

- Menu `⋯` : `Supprimer le client` (destructive avec confirm).
- ActionBar `+ Tonte manuelle` ouvre la `ManualHistoryEntrySheet` directement.
- ActionBar `Modifier` push `/clients/:id/edit`.
- Tap sur ligne timeline → tour detail ou sheet d'édition (selon `kind`).
- Tap `Itinéraire` → intent maps avec adresse pré-remplie.
- Pull-to-refresh recharge le client + ses interventions.

### 3.3 Tour completion (Bilan)

**Intention** : valider rapidement ce qui a été fait — afficher clairement **prévu vs effectué**, ajouter prestations hors-plan, totaliser, valider. Doit être utilisable sur le siège du véhicule.

**Wireframe** :

```
─────────────────────────────────────────
[← back]   Bilan tournée du 12 mai
           5 stops · prévu 480 €
─────────────────────────────────────────
  ┌─ AppKpiRow live (refresh à chaque édit) ─┐
  │ 5/5 stops │ 470 € │ 6 h 35 │ Δ -10 €    │
  │ validés   │ réel  │ réel   │ vs prévu   │
  └──────────────────────────────────────────┘

  Stop ① · M. Le Goff
  ┌─ AppSectionCard ─────────────────────┐
  │  Tonte Petit       prévu 3 → [3] ✓  │
  │  Parage            prévu 1 → [1] ✓  │
  │  ──── hors-plan ──────────────────── │
  │  [ + Ajouter une prestation ]        │
  │                                      │
  │  Sous-total : 180 €  ·  durée 45m    │
  └──────────────────────────────────────┘

  Stop ② · Mme Kervella
  ┌─ AppSectionCard ─────────────────────┐
  │  Tonte Grand       prévu 2 → [3] ⬆  │  ← diff visible
  │  Tonte Petit       prévu 4 → [4] ✓  │
  │                                      │
  │  Sous-total : 240 €  ·  durée 1h05   │
  └──────────────────────────────────────┘

  Stop ③ · M. Riou
  ┌─ AppSectionCard ─────────────────────┐
  │  Tonte Petit       prévu 5 → [4] ⬇  │
  │  ──── hors-plan ──────────────────── │
  │  Onglons          ×  [2]   60 €      │
  │                                      │
  │  Sous-total : 240 €  ·  durée 50m    │
  └──────────────────────────────────────┘

  ... etc

  Notes globales
  ┌─ FTextField multi-line ──────────────┐
  │ (optionnel — observations tournée)  │
  └──────────────────────────────────────┘

(bottom 80dp)
─────────────────────────────────────────
[ AppActionBar ]
  ┌─ « Valider la tournée »  primary ────┐
  └──────────────────────────────────────┘
```

**Info ajoutée / pattern nouveau** :

- **`AppDiffRow`** — chaque ligne presta montre prévu → effectué avec icône delta (✓ identique, ⬆ +N, ⬇ -N) en couleur sémantique. Au lieu d'un simple input qty, on **voit** ce qui a changé.
- **`AppKpiRow` live** sticky en haut juste sous le header : compteur stops validés / revenu réel / durée réelle / **delta vs prévu** en accent cuivre. Refresh à chaque édit.
- Section par stop = `AppSectionCard` avec sous-total visible (montant + durée) — actuellement caché.
- Confirm dialog avant validation : « Valider la tournée ? Tu pourras encore éditer les prestations et compteurs animaux après. ».
- Snackbar de succès post-validation : « Tournée validée · 470 € encaissés » + undo 5s.

**Interactions** :

- Tap qty → bottom sheet stepper « − [3] + » avec haptique sur chaque tap (plus précis que clavier numérique sur le terrain).
- Tap `+ Ajouter une prestation` → `PrestationPickerSheet` existante (réutilisée).
- Long-press une presta hors-plan → action « Retirer ».
- Réordonner les stops impossible ici (mode bilan, pas planif).

### 3.4 Map

**Intention** : voir tous les clients sur le territoire, comprendre la répartition par statut, retrouver un client géographiquement, démarrer une action (planifier, voir détail) sans quitter la carte.

**Wireframe** :

```
─────────────────────────────────────────
[FlutterMap full-screen, fond ivoire]

   ┌──────────────────────────────────┐  ← overlay TOP
   │ [🔍 Recherche…]            [≡]  │
   └──────────────────────────────────┘

   ┌─ AppKpiRow flottante ────────────┐  ← chips status, tappable pour toggle
   │ 12 ● en attente   8 ● planifiés  │     pill, accent quand actif
   │ 24 ● tondus       2 ● bannis     │     count en tabular
   └──────────────────────────────────┘

       ●───────●───●
            ●           ●           ← pins clients colorés statut
   ●        ●                          + drop-pin home pour la base
        ●        ●●●
             ●

         ┌─ Pin tap → bottom sheet ───┐
         │ Mme Kervella · ● en attente│
         │ Plouguerneau · 12 km       │
         │ 8 Moutons · 3 Chevaux      │
         │ Dernière : 8 mois          │
         │                            │
         │ [Voir fiche]  [Itinéraire] │
         │ [Planifier dans tournée]   │
         └────────────────────────────┘

[FAB recentrer carte sur GPS user] ↘ bottom-right au-dessus bottom nav
─────────────────────────────────────────
```

**Info ajoutée vs actuel** :

- **`AppKpiRow` flottante de stats par statut** — actuellement aucune stat, légende dans dialog. Chaque chip est tappable et toggle l'affichage des pins de ce statut. État actif = chip rempli accent + count bold.
- Recherche en overlay top (pas dans dialog), résultat = focus + zoom sur le client.
- **Sheet riche au tap pin** : nom, statut, ville, distance depuis base, animaux compact, dernière intervention en relatif, **3 actions** (`Voir fiche` / `Itinéraire` (intent maps) / `Planifier dans tournée`). Actuellement juste le nom.
- **Drop-pin home** pour la base — déjà en place après pivot, on resize en signature 48×56 et on le rend tappable (centre carte sur base).
- FAB « me localiser » (recenter sur GPS user) en bottom-right.

**Interactions** :

- Tap chip statut → toggle visibilité des pins de ce statut (état persisté localement).
- Long-press sur chip statut → ouvre dialog d'édition de la couleur de ce statut (raccourci vers Settings) — *bonus*.
- Tap pin → sheet (au-dessus de la carte, snap mid-height puis full-height au drag-up).
- Bouton `≡` à droite de la search ouvre les **options carte** : couches (topo/satellite si dispo), fond, légende détaillée.
- Tap `Planifier dans tournée` → push `/proximity/:pivotId` avec ce client comme ancre.

---

## 4. Sweep des autres écrans

Le design system v3 est appliqué partout. Pour chaque écran, on liste **les changements clés** de layout/info au-delà du restyling automatique.

### 4.1 Clients list

- **Header** : titre `clientsListTitle` + sous-titre `total · waiting · scheduled · done` (compteurs en tabular, séparés par dots).
- **Search field + filter button** sticky (pattern §2.7). Filter button → bottom sheet, switches par statut.
- **`AppListTile rich`** par client :
  - Prefix : dot 10px statut (couleur user)
  - Title : nom client
  - Subtitle italique : ville
  - Metadata row : `🐑 12 · 🐎 3` (compact `AnimalCountsBadges`) · `📞 06 12…` principal · `dernière : 8 mois`
  - Suffix : chevron (ou icône `triangleAlert` warning si `needsDistanceRecompute`)
- **`AppFAB extended`** « + Client » (collapse en icon-only après scroll de 80dp).
- **Banner de recompute distances** : refonte en `AppSectionCard` avec border `info` (au lieu de destructive), bouton `Recalculer` outline.

### 4.2 Tours list

- **Header** : titre + `AppKpiRow` inline `total · planifiées · ce mois · revenu mois`.
- Search + filter (statut, mois).
- **`AppListTile rich`** par tournée :
  - Prefix : badge date verticale (jour bold + mois muted, ex. `12 / mai`)
  - Title : `Tournée du 12 mai · 5 stops`
  - Subtitle italique : `Plouguerneau, Lampaul-Plouarzel, Lannilis…` (3 premières villes)
  - Metadata row : `47 km · 6h12 · 480 €` tabular + badge statut (planifiée/complétée)
  - Suffix : chevron
- **`AppFAB`** « + Tournée » qui ouvre une **sheet de choix** (`Manuelle` / `Optimisée par commune`) au lieu d'aller direct sur l'un des deux.
- État vide : `AppEmptyState` avec illustration `cl_route_loop`, titre, body « Crée ta première tournée », CTA primary.

### 4.3 Settings

Refonte structurelle : split en groupes-cards numérotées au lieu d'un long form, chaque groupe est `AppSectionCard` repliable (collapsed par défaut sauf `1. Adresse de base` qui reste open) :

1. **Adresse de base** — autocomplete BAN, label, preview marker.
2. **Apparence** — theme mode (light/dark/system), language (FR/EN si dispo).
3. **Couleurs des statuts client** — 6 swatches alignés en grille, tap → color picker.
4. **Optimisation tournée** — radius par défaut, durée cible par défaut.
5. **Espèces & catégories** — lien vers `/settings/species` (résumé : « 3 actives, 1 archivée »).
6. **Catalogue de prestations** — lien vers `/settings/prestations` (résumé : « 5 actives, 0 archivées »).
7. **Données** — export JSON, import JSON, **« Réinitialiser » destructive** (avec confirm + saisie « SUPPRIMER »).

- Save flottant dans `AppActionBar` au lieu d'un bouton noyé en bas du form.
- Discard dialog si l'utilisateur back-navigue avec des changements non sauvés.

### 4.4 Onboarding

- **Stepper visuel** en haut sous le header : 3 cercles reliés `1 ─ 2 ─ 3` (label sous chaque), step actif en `primary` filled, autres en `subtleForeground` outline.
  - Step 1 : Adresse de base
  - Step 2 : Espèces gérées
  - Step 3 : Bienvenue (NOUVEAU — récap + premier conseil + CTA « Commencer »)
- **Step 2** : grille 2-col de cards seed (`Mouton`, `Cheval`, `Bovin`, `Caprin`) avec pictogramme custom, tappables (toggle inclusion). CTA secondaire « Ajouter une espèce custom » → sheet existante.
- **Step 3 (nouveau)** : récap visuel (« Tu vas gérer 3 espèces depuis Plouguerneau »), 3 conseils courts (`+ Ajouter ton premier client`, `+ Planifier ta première tournée`, `+ Ouvrir le catalogue de prestations`), CTA primary « Démarrer ».
- Mascotte mouton conservée (PNG existant) en filigrane discret bottom-right de l'écran 1, plus mise en avant.
- ActionBar : `[← Retour outline] [Suivant primary]` ou full-width `Démarrer` au step 3.

### 4.5 Client form

Sections numérotées en `AppSectionCard` :

1. **Identité** : nom (required), date depuis client (auto, lecture seule)
2. **Adresse** : autocomplete BAN, code postal, ville
3. **Téléphones** : `ReorderableList` avec drag handle visible (`gripVertical`), bouton `+ Ajouter un numéro`, formatter d'input FR existant. Helper text : « Le premier numéro sera utilisé pour Appeler/SMS depuis la map ».
4. **Animaux** : `AnimalCountsEditor` existant, redessiné aux nouveaux tokens
5. **Couleur du marqueur** : `ColorSwatchPicker` redesigné en grille 6 swatches + checkbox `Utiliser la couleur du statut` (par défaut on)
6. **Notes** : textarea multi-line

- Validation inline (§2.4) sur tous les champs.
- ActionBar : `[Annuler outline] [Enregistrer primary]`.
- Discard dialog si back avec changements.

### 4.6 Client history

- **Header** : titre `Historique de Mme Kervella`, sous-titre `14 interventions · saison 2025-2026`.
- **`AppKpiRow`** : `14 interventions · 1 240 € · 12h30 · depuis 2024`.
- **Filtre par saison** : chips horizontaux scrollables `[Saison en cours] [2025] [2024] [2023] [Tout]` sticky sous KpiRow.
- **Group headers par mois** : `Septembre 2025` en `caption` UPPERCASE muted, séparateur 0.5px hairline.
- **`AppTimelineRow`** par entrée — pictogramme `cl_shears` (tournée) ou `cl_clip_check` (manuel), date, breakdown prestations en italique, montant + durée tabular à droite.
- **`AppFAB`** « + Tonte manuelle ».
- État vide : illustration + body « Aucune intervention enregistrée. Ajoute-en une manuellement ou planifie une tournée. » + CTAs.

### 4.7 Tour draft (création/édition)

Stepper en haut (3 steps visibles, sticky) :

1. **Quand** — date + heure
2. **Qui** — sélection des clients (multi-picker, suggestions par proximité existantes)
3. **Quoi** — prestations par client + ordre des stops + résumé

- Step `Quand` : un seul écran avec date picker + time picker visibles côte à côte, défaut = aujourd'hui matin 9h.
- Step `Qui` : `WaitingClientsMultiPicker` existant + onglets « Suggérés à proximité » et « Autres » (déjà en place), avec **count en titre d'onglet** (`Suggérés (5)`).
- Step `Quoi` :
  - Reorderable list des stops avec drag handle, position numérotée, distance depuis le précédent calculée live.
  - Tap sur un stop → sheet `PrestationPickerSheet` existante.
  - **Mini-map preview** sticky en haut (h ~140dp) montrant la route et les pins numérotés en temps réel.
  - Bouton `Optimiser l'ordre` outline en haut → recompute ordre via use case existant + confirmation.
- **Résumé live** dans une `AppKpiRow` sticky bottom au-dessus de l'`AppActionBar` : `5 stops · 47 km · 6h12 · 480 €`.
- ActionBar : `[← Étape précédente outline] [Suivante / Créer la tournée primary]`.

### 4.8 Tour optimized config

- **Form simple** : selector commune (chips horizontaux scrollables des communes ayant ≥1 client waiting + count `(5)`), slider durée cible (4h-10h, défaut 8h), CTA `Proposer une tournée` primary.
- **Preview live** sous le selector quand une commune est sélectionnée : *« 5 clients waiting à Plouguerneau »*.
- Si aucune proposition trouvée : empty state inline « Pas assez de clients waiting dans cette commune pour la durée demandée. Élargis le rayon ou choisis une autre commune. »
- Si proposition trouvée : push `/tours/draft` pré-rempli (comportement actuel).

### 4.9 Catalogue prestations

- Header + search field + filter button (filtre : `Toutes / Par espèce / Libres / Archivées`).
- **`AppKpiRow`** : `5 actives · 1 archivée · revenu mois X €`. Le `revenu mois` nécessite une dérivation côté provider (agrégation sur tournées complétées du mois en filtrant par prestation).
- **Sections par espèce** repliables avec count `Mouton (3)`, libre = `Sans catégorie (1)`, archivées en bas (collapsed default).
- **`AppListTile`** par prestation : title `Tonte Petit`, subtitle italique `Mouton`, metadata `60 € · 15 min`, suffix chevron.
- **`AppFAB`** « + Prestation » → push `/settings/prestations/new`.

### 4.10 Prestation edit

- `AppSectionCard` unique :
  - Champ `Nom` (required, validation inline)
  - Selector `Bind to category` : `Mouton / Petit` ou bouton « Libre (sans catégorie) ». Sheet picker au tap.
  - Champs `Prix unitaire (€)` et `Durée (min)` côte à côte
  - Switch `Archivée` (uniquement en édition)
- ActionBar : `[Supprimer destructive sm] [Annuler outline] [Enregistrer primary]` en édition ; `[Annuler] [Créer]` en création.

### 4.11 Species management

- **`AppKpiRow`** : `3 actives · 1 archivée · 7 catégories au total`.
- Sections actives + archivées (collapsed). `AppListTile` par espèce : title nom, subtitle italique `4 catégories · 12 prestations actives`, suffix chevron → species edit.
- **`AppFAB`** « + Espèce » → choix sheet (`Restaurer un template seed` ou `Ajouter custom`).

### 4.12 Species edit

- Header + sous-titre `4 catégories · 8 prestations`.
- ReorderableList des catégories actives + section archivées collapsed.
- `AppListTile` par catégorie : title nom, subtitle italique `Petit, Grand` (variantes ou rien), pas de chevron mais un menu `⋯` → renommer/archiver.
- **`AppFAB`** « + Catégorie » → bottom sheet form `AnimalCategoryFormSheet` existante (redessinée).

### 4.13 Proximity

- Header + sous-titre `Clients à proximité de Mme Kervella`.
- **Slider rayon** sticky en haut (1-50 km, défaut 10 km), affiche le rayon courant en label.
- **`AppKpiRow` live** : `5 clients trouvés · 3 sélectionnés · 2.3 km moy.` — count refresh selon rayon.
- **Tabs `Liste / Carte`** sticky sous slider (au lieu de toggle invisible).
- **Liste** : `AppListTile rich` par candidat — distance routière depuis pivot affichée en tabular, checkbox de sélection à gauche.
- **Carte** : pins numérotés selon ordre de sélection, route prévisualisée si ≥2 clients sélectionnés.
- ActionBar : `[Annuler outline] [Planifier la tournée (3) primary]` — count visible dans le label CTA.

---

## 5. Phasing d'implémentation

Le plan détaillé sera produit à l'étape suivante (writing-plans). Les grandes phases prévues :

1. **Foundations** — palette, typo Inter unique, design tokens v3, motion durations, icon set custom (8-10 SVG métier).
2. **Composants signature** — refactor `AppPrimaryButton` / `AppSectionCard` / `AppEmptyState` / `AppBadge` aux nouveaux tokens ; nouveaux composants (cf. §1.6) ; drop `AppHeroCard`.
3. **Patterns globaux** — `AppHeader` partout, `AppActionBar` sur écrans-détail, validation inline, confirm destructifs unifiés, search/filter pattern, haptiques.
4. **Top 4 écrans** — Tour detail, Client detail, Tour completion, Map.
5. **Sweep restant** — Onboarding, Clients list, Tours list, Settings, Client form, Client history, Tour draft, Tour optimized config, Catalogue prestations, Prestation edit, Species management/edit, Proximity.
6. **Cleanup** — supprimer `AppHeroCard`, font Fraunces, ancienne `app_typography.dart`, code mort éventuel.

## 6. Risques & points de vigilance

- **Drop Fraunces** = identité actuelle disparaît d'un coup. Choix fort, mentionné pour alignement.
- **`AppCommandPalette`** est ambitieuse. Si l'implémentation devient lourde, descope au phase 2 — l'app reste fonctionnelle sans. À évaluer dans le plan.
- **Mini-map preview** (Tour detail / Tour draft) = nouveau widget. Réutilise le `flutter_map` déjà en place, mais demande de construire un `_MiniMap` non-interactif (gestures disabled, fit-to-route auto). À budgeter.
- **`AppDiffRow`** sur Tour completion nécessite que les `plannedPrestations` (snapshots) soient lus en parallèle des `actualPrestations` éditables. La data est en place côté DB — refactor du widget uniquement.
- **KPI `revenu mois`** sur Catalogue prestations = nouvelle dérivation (agrégation sur tournées complétées du mois en filtrant par prestation). Faisable, à valider dans le plan ou descoper si trop coûteux.
- **Touch targets descendant à 44/48dp** (vs 56dp actuels) : conforme aux specs Material/iOS, mais moins « confortable débutant ». Si tests terrain trouvent trop serré, on remonte.
- **Light mode = mode principal** : les compromis entre light et dark se font en faveur du light.
- **A11y** : on respecte les bonnes pratiques (contraste WCAG AA 4.5:1, touch targets, sémantique des labels) mais on ne lance pas un audit complet automatisé.

## 7. Critères de succès

- Toutes les routes/écrans existants sont rendus avec le design system v3 (palette + typo + composants signature).
- Les 4 écrans prioritaires (Tour detail, Client detail, Tour completion, Map) affichent les KPIs et infos additionnelles décrites en §3.
- Aucun écran n'utilise plus `AppHeroCard`, Fraunces, ou un `FTile` direct (tous remplacés par `AppListTile`).
- Tous les écrans-détail ont un `AppActionBar` sticky pour leurs actions principales.
- Validation inline active sur tous les formulaires (`ClientForm`, `PrestationEdit`, `Settings`, `Onboarding`, `ManualHistoryEntrySheet`).
- Tous les confirms destructifs passent par le pattern unifié §2.5.
- Tous les états loading/empty/error utilisent les composants standardisés (`AppSkeleton`, `AppEmptyState`, `AppErrorState`).
- 186 tests existants restent verts (refonte UI pure, pas de changement de logique).
- Smoke tests manuels OK : créer/éditer/supprimer un client, planifier/compléter/éditer une tournée, ajouter une intervention manuelle, naviguer la map, exporter/importer.
