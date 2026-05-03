# 6. Theming & i18n

## Theming Modern Craft (light + dark)

### Tokens

Un seul fichier de vérité dans `src/ui/theme/tokens.ts`, deux variants:

```ts
// Structure conceptuelle
export const tokens = {
  light: {
    // palette Modern Craft existante (à extraire de lib/core/theme/app_color_scheme.dart)
    background: '#...',     // crème/beige cassé
    foreground: '#...',     // brun foncé
    primary: '#...',
    accent: '#...',
    muted: '#...',
    border: '#...',
    danger: '#...',
    success: '#...',
    // sémantique métier
    waiting: '#...',        // état "en attente" (orange chaud)
    shorn: '#...',          // récemment tondu (vert sourd)
  },
  dark: {
    // déclinaison sombre — à concevoir au démarrage du projet
    // règle: garder l'identité Modern Craft (chaleur, naturel) sans virer cliniquement noir
    background: '#...',     // brun très sombre, pas pur noir
    foreground: '#...',     // crème claire
    // ...
  },
};
```

### Intégration NativeWind v4

- `tailwind.config.js` consomme les tokens et définit les classes sémantiques (`bg-background`, `text-foreground`, `border-border`, etc.)
- `darkMode: 'class'` — un attribut `className="dark"` sur le `<View>` racine bascule tout l'arbre
- React provider `<ThemeProvider>` lit le settings store (`theme_mode`) + `useColorScheme()` du système → calcule `isDark` → applique la classe

### Switch utilisateur

- Écran Settings → Apparence: toggle 3-positions
  - **Système** (default — suit `useColorScheme`)
  - **Clair**
  - **Sombre**
- Choix persisté dans la table `settings` (`key='theme_mode'`)
- Changement appliqué immédiatement (pas de redémarrage)

### Composants react-native-reusables

Tous viennent avec dark mode out-of-the-box via les classes NativeWind sémantiques. On les copie dans `src/ui/primitives/` et on les édite si besoin (pas de dépendance npm opaque).

## i18n

### Lib

`i18next` + `react-i18next` + `expo-localization` (détection langue système).

### Setup

- Locales dans `src/i18n/locales/` — un fichier JSON par langue (`fr.json` seul en v1)
- Fichier organisé par domaine: `clients.list.title`, `tours.draft.cta_continue`, `errors.network.title`, etc.
- Hook `useTranslation()` partout — pas de strings en dur dans les composants
- **Pluralisation FR** native dans i18next (gère "1 client" vs "2 clients")
- **Format dates** via `date-fns` avec locale `fr` (`format(date, 'PPP', { locale: fr })`)
- **Format nombres** via `Intl.NumberFormat('fr-FR')` natif

### Bénéfices vs ARB Flutter

- Pas de codegen
- Tooling LLM excellent (i18next ultra-standard)
- Si un jour on veut anglais → on duplique `fr.json` en `en.json` et c'est tout

### Convention v1

100% des strings UI passent par `t('...')` même si on n'a qu'une langue. Coût quasi-nul, dette zéro plus tard.
