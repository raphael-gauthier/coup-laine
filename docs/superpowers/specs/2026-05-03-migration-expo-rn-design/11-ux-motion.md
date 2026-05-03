# 11. UX, esthétique & motion

## Priorité explicite

L'UX est un **objectif de premier rang** de la migration, au même titre que la parité fonctionnelle. Trois axes:

1. **Simplicité d'usage** — l'utilisateur passe un appel client → planifie une tournée en quelques taps, pas de friction
2. **Esthétique soignée** — typographie, espacement, palette Modern Craft cohérents partout, niveau "produit fini" et non "MVP fonctionnel"
3. **Motion intentionnelle** — transitions, micro-interactions, retours haptiques pour une sensation de fluidité native

Cette priorité **infuse chaque jalon**, ce n'est pas un sprint de polish à la fin.

## Principes UX

### Simplicité d'usage

- **Tap-count minimal** sur les actions fréquentes (toggle "en attente", composer une tournée à partir d'un appel)
- **Smart defaults** partout: pré-remplir avec les choix les plus probables (date du jour, dernière prestation utilisée, départ depuis la base)
- **Progressive disclosure**: l'écran principal montre l'essentiel, les détails accessibles en un tap
- **Confirmation seulement pour les actions destructives** (supprimer un client, restaurer un backup). Pas de "êtes-vous sûr ?" sur les actions réversibles
- **Pas de modales bloquantes** sauf nécessité absolue. Préférer sheets, popovers, inline editing
- **Recherche full-text omniprésente** sur les listes — le scroll de 200 éléments doit être l'exception, pas la règle
- **Command palette** (style ⌘K mobile) accessible via geste rapide depuis n'importe où, pour sauter à un client / créer une tournée / aller aux settings

### Esthétique

- **Typographie:** une famille de police choisie au Jalon 0, échelle typographique fixe (display / heading / body / caption / micro)
- **Espacement:** échelle 4pt (4 / 8 / 12 / 16 / 24 / 32 / 48 / 64) appliquée partout, jamais de valeur ad hoc
- **Hiérarchie visuelle:** poids de police + taille + couleur, pas plus de 3 niveaux par écran
- **Palette Modern Craft:** chaleur, naturel, lisibilité haute en light comme en dark
- **Iconographie:** lucide-react-native exclusivement, pas de mix de styles
- **Illustrations:** pour les empty states et l'onboarding, illustrations sur mesure ou Lottie, pas d'emoji ni d'icônes Material génériques
- **Photos / images:** non requises pour l'instant (pas de photo de client en v1)

### Motion

Trois niveaux de motion à intégrer:

**1. Transitions de navigation (gérées par Expo Router + Reanimated)**

- Stack push: slide horizontal natif (default Expo Router)
- Modale plein écran (création client / création tournée): slide vertical avec backdrop fade
- Tabs: pas de transition (instantané)
- Custom: shared element entre liste client et détail client (image / pin / nom qui transitionne)

**2. Layout animations (composants qui réagissent au changement d'état)**

- Insertion / suppression d'items dans une liste (clients, tour stops): fade + slide
- Toggle "en attente": badge qui apparaît avec un spring scale
- Réordonnancement drag-and-drop d'une tournée: spring physics natif, le stop déplacé "soulève" légèrement (shadow + scale)
- Filtres / chips qui s'activent: scale + color tween

**3. Micro-interactions (réactions immédiates au tap)**

- Tous les boutons primaires: scale 0.97 sur press, retour à 1 avec spring
- Tous les CTAs critiques: haptic feedback léger (`Haptics.selectionAsync()`)
- Actions de succès (tournée clôturée, backup créé): haptic medium + animation de confirmation (checkmark animé)
- Erreurs: haptic notification error + shake horizontal sur le composant en erreur
- Pull-to-refresh: animation custom avec illustration ou progression

**Skeleton loaders > spinners** — toujours préférer un skeleton qui anticipe la forme du contenu plutôt qu'un spinner indéterminé.

**Map:**

- Camera animations smooth (zoom, pan) avec easing
- Pin drop animation au premier rendu
- Cercle de proximité: pulse léger pour signaler qu'il est interactif (radius slidable)
- Polyline tournée: animation de tracé progressive au premier rendu

**Performance:**

- Toutes les animations sur le thread UI natif (Reanimated worklets, jamais de setState animations)
- 60 FPS minimum sur device milieu de gamme (test sur device physique pas simulator)
- Si une animation pose problème de perf: la simplifier ou la supprimer, pas la dégrader

## Stack motion

| Lib | Rôle |
|---|---|
| `react-native-reanimated` v3+ | Toutes les animations sur thread UI (worklets) |
| `react-native-gesture-handler` | Drag-and-drop, swipe, pan |
| `moti` | API déclarative au-dessus de Reanimated pour animations simples |
| `expo-haptics` | Retours haptiques (light / medium / heavy / selection / notification) |
| `react-native-skia` | Animations complexes / illustrations (à utiliser avec parcimonie, optional v1) |
| `lottie-react-native` | Illustrations animées (empty states, success states) |

## Tokens motion

Définis dans `src/ui/theme/motion-tokens.ts`:

```ts
export const motion = {
  duration: {
    instant: 100,
    fast: 200,
    normal: 300,
    slow: 500,
  },
  easing: {
    standard: 'cubic-bezier(0.4, 0.0, 0.2, 1)',  // material standard
    decelerate: 'cubic-bezier(0.0, 0.0, 0.2, 1)',
    accelerate: 'cubic-bezier(0.4, 0.0, 1, 1)',
    spring: { damping: 15, stiffness: 150 },     // spring config par défaut
  },
};
```

Utiliser **toujours** ces tokens, jamais de durées ou d'easings ad hoc.

## Critères "feature done" augmentés (cf. §8)

Pour qu'une feature soit considérée terminée, en plus des critères techniques de §8:

- ✅ Transitions de navigation cohérentes avec le reste de l'app
- ✅ Layout animations sur les listes / collections affectées
- ✅ Haptic feedback sur les actions critiques
- ✅ Skeletons (pas de spinner) pour les chargements > 200ms
- ✅ Empty state designé (illustration + message + CTA)
- ✅ Error state designé (pas un toast générique "Une erreur est survenue")

## Risque produit revu

Le risque n'est plus "trop d'animations en début de projet" mais l'inverse: **livrer des features fonctionnelles mais visuellement plates qu'on devra retravailler ensuite**. Mieux vaut faire moins de features avec une UX soignée que toutes les features en mode squelette.

Si un compromis vélocité/UX se présente: **on coupe une feature secondaire**, on ne dégrade pas l'UX d'une feature livrée.
