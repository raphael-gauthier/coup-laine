# RGPD MVP — Surfaces légales (Section A) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Brancher trois documents légaux hébergés (mentions légales, politique de confidentialité, CGU+DPA) à l'app via un nouvel écran Réglages, et ajouter des encarts d'information dans `welcome.tsx` et `login.tsx`.

**Architecture:** Constantes URL centralisées dans `src/infra/config/legal-urls.ts`. Nouvel écran `app/(tabs)/settings/legal.tsx` qui ouvre chaque URL via `expo-web-browser.openBrowserAsync` (sheet in-app type SFSafariViewController / Custom Tabs). Encarts statiques dans `welcome.tsx` (onboarding) et `login.tsx` (auth). Aucune logique métier, aucune nouvelle dépendance npm (`expo-web-browser` et `expo-constants` déjà installés).

**Tech Stack:** TypeScript, Expo Router, NativeWind, i18next, `expo-web-browser`, `expo-constants`.

---

## Spec reference

Implements Section A de `docs/superpowers/specs/2026-05-06-rgpd-mvp-design.md`. Re-lire la spec si quelque chose ci-dessous est flou.

## Conventions (from CLAUDE.md)

- Package manager : **pnpm**.
- Tous identifiants / chemins / clés i18n en **anglais**. Le français vit uniquement dans `src/i18n/locales/fr.json` (valeurs).
- Tests : `pnpm test` (vitest + jest). Typecheck : `pnpm typecheck`. Lint : `pnpm lint`.
- Écran TS strict, pas de `any`.
- Pressables via `<PressScale>`, haptics via `@/ui/motion/haptics`.

## Préalable hors-spec

Les 3 URLs HTML doivent être servies en ligne **avant le merge en prod**. Par défaut :
- `https://ravnkode.com/coup-laine/legal/mentions-legales.html`
- `https://ravnkode.com/coup-laine/legal/politique-confidentialite.html`
- `https://ravnkode.com/coup-laine/legal/cgu.html`

Si tu changes l'hébergement (Cloudflare Pages, Github Pages, sous-domaine), modifie uniquement `src/infra/config/legal-urls.ts` à la fin du chantier — tout le reste pointe vers ces constantes.

## File structure

### Created

- `src/infra/config/legal-urls.ts`
- `app/(tabs)/settings/legal.tsx`

### Modified

- `app/(tabs)/settings/index.tsx` (ajout d'une section + ligne « Légal & confidentialité »)
- `app/onboarding/welcome.tsx` (encart info sous le CTA)
- `app/auth/login.tsx` (encart info sous le bouton « Recevoir le code »)
- `src/i18n/locales/fr.json` (~15 nouvelles clés)

### Deleted

Aucun.

---

## Task 1 — Créer les constantes d'URL

**Files:**
- Create: `src/infra/config/legal-urls.ts`

- [ ] **Step 1 : Créer le fichier**

```ts
export const LEGAL_URLS = {
  legalNotices:  'https://ravnkode.com/coup-laine/legal/mentions-legales.html',
  privacyPolicy: 'https://ravnkode.com/coup-laine/legal/politique-confidentialite.html',
  terms:         'https://ravnkode.com/coup-laine/legal/cgu.html',
} as const;

export type LegalUrlKey = keyof typeof LEGAL_URLS;
```

- [ ] **Step 2 : Typecheck**

Run : `pnpm typecheck`
Expected : OK.

- [ ] **Step 3 : Commit**

```bash
git add src/infra/config/legal-urls.ts
git commit -m "feat(rgpd): add legal-urls constants"
```

---

## Task 2 — Ajouter les clés i18n

**Files:**
- Modify: `src/i18n/locales/fr.json`

- [ ] **Step 1 : Ajouter les nouvelles clés**

Ajouter ces blocs dans `src/i18n/locales/fr.json` (places exactes : la racine `settings`, la racine `onboarding.welcome`, la racine `auth`).

Dans `settings.*`, ajouter (à côté des autres `section_*` existants) :

```json
"section_legal": "Légal",
"legal": {
  "row_label": "Légal & confidentialité",
  "row_hint": "Mentions légales, politique de confidentialité, CGU",
  "screen_title": "Légal & confidentialité",
  "legal_notices": "Mentions légales",
  "privacy_policy": "Politique de confidentialité",
  "terms": "CGU et accord de sous-traitance",
  "app_version": "Version de l'app : {{version}}"
}
```

Dans `onboarding.welcome.*` (à côté des clés existantes `title`, `message`, `cta`) :

```json
"privacy_intro": "Coup'Laine fonctionne en local sur votre appareil. L'autocomplétion d'adresse (BAN) et les calculs d'itinéraire (OpenRouteService) nécessitent une connexion internet. La sauvegarde cloud est optionnelle.",
"privacy_link": "En savoir plus"
```

Dans `auth.*` (à côté des clés existantes `email`, `send_code_cta`, etc.) :

```json
"terms_notice": "En vous connectant, vous acceptez les CGU et l'accord de sous-traitance. Vos données métier seront sauvegardées sur Supabase (eu-west-3, Paris).",
"terms_link": "Lire les CGU",
"privacy_link": "Politique de confidentialité"
```

- [ ] **Step 2 : Vérifier le JSON**

Run : `node -e "JSON.parse(require('fs').readFileSync('src/i18n/locales/fr.json','utf-8'))"`
Expected : aucune sortie (parse OK).

- [ ] **Step 3 : Commit**

```bash
git add src/i18n/locales/fr.json
git commit -m "feat(rgpd): add i18n keys for legal screen, onboarding and login notices"
```

---

## Task 3 — Créer l'écran `legal.tsx`

**Files:**
- Create: `app/(tabs)/settings/legal.tsx`

L'écran liste les 3 documents et affiche la version de l'app. Chaque ligne ouvre l'URL via `expo-web-browser.openBrowserAsync` (sheet in-app, retour propre à l'app au close).

- [ ] **Step 1 : Créer le fichier**

```tsx
// app/(tabs)/settings/legal.tsx
import { ScrollView, View } from 'react-native';
import { useTranslation } from 'react-i18next';
import * as WebBrowser from 'expo-web-browser';
import Constants from 'expo-constants';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { ScreenHeader } from '@/ui/components/screen-header';
import { SettingsRow } from '@/ui/components/settings-row';
import { LEGAL_URLS } from '@/infra/config/legal-urls';

const APP_VERSION = Constants.expoConfig?.version ?? '0.0.0';

export default function LegalScreen() {
  const { t } = useTranslation();

  const open = async (url: string) => {
    await WebBrowser.openBrowserAsync(url);
  };

  return (
    <Surface className="flex-1">
      <ScreenHeader title={t('settings.legal.screen_title')} />
      <ScrollView contentContainerClassName="px-4 pb-8">
        <SettingsRow
          label={t('settings.legal.legal_notices')}
          onPress={() => open(LEGAL_URLS.legalNotices)}
        />
        <SettingsRow
          label={t('settings.legal.privacy_policy')}
          onPress={() => open(LEGAL_URLS.privacyPolicy)}
        />
        <SettingsRow
          label={t('settings.legal.terms')}
          onPress={() => open(LEGAL_URLS.terms)}
        />

        <View className="mt-8 px-4">
          <Text variant="muted" className="text-xs text-center">
            {t('settings.legal.app_version', { version: APP_VERSION })}
          </Text>
        </View>
      </ScrollView>
    </Surface>
  );
}
```

- [ ] **Step 2 : Typecheck + lint**

Run : `pnpm typecheck && pnpm lint`
Expected : OK.

- [ ] **Step 3 : Commit**

```bash
git add app/(tabs)/settings/legal.tsx
git commit -m "feat(rgpd): add legal screen with three doc rows + app version"
```

---

## Task 4 — Brancher l'écran depuis Réglages

**Files:**
- Modify: `app/(tabs)/settings/index.tsx`

Ajout d'une section « Légal » en bas de l'écran (après la section Cloud existante).

- [ ] **Step 1 : Modifier le fichier**

Dans `app/(tabs)/settings/index.tsx`, après le bloc `<SectionHeader title={t('settings.section_cloud')} />` + sa `<SettingsRow>` (autour de `app/(tabs)/settings/index.tsx:78-83` au moment de la rédaction), ajouter :

```tsx
<SectionHeader title={t('settings.section_legal')} />
<SettingsRow
  label={t('settings.legal.row_label')}
  hint={t('settings.legal.row_hint')}
  onPress={() => router.push('/(tabs)/settings/legal' as never)}
/>
```

- [ ] **Step 2 : Typecheck + lint**

Run : `pnpm typecheck && pnpm lint`
Expected : OK.

- [ ] **Step 3 : Smoke test manuel**

Run : `pnpm start`, ouvrir l'app, naviguer Réglages → ligne « Légal & confidentialité » apparaît. Le tap navigue vers le nouvel écran. Les 3 lignes ouvrent bien le navigateur in-app sur leur URL respective. Pied de page affiche la version de l'app.

(Si les URLs ne sont pas encore servies, le navigateur affichera 404 — c'est normal, c'est le préalable hors-spec.)

- [ ] **Step 4 : Commit**

```bash
git add app/(tabs)/settings/index.tsx
git commit -m "feat(rgpd): wire legal screen from settings index"
```

---

## Task 5 — Encart info dans l'onboarding `welcome.tsx`

**Files:**
- Modify: `app/onboarding/welcome.tsx`

Ajoute un encart d'information sous le CTA « Démarrer », sans checkbox bloquante. Lien « En savoir plus » qui ouvre la politique de confidentialité.

- [ ] **Step 1 : Modifier le fichier**

Remplacer le contenu actuel par :

```tsx
import { View } from 'react-native';
import { useRouter } from 'expo-router';
import { useTranslation } from 'react-i18next';
import * as WebBrowser from 'expo-web-browser';
import { ArrowRight, Scissors } from 'lucide-react-native';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { Button } from '@/ui/primitives/button';
import { PressScale } from '@/ui/motion/press-scale';
import { useOnContrastColor, usePrimaryColor } from '@/ui/theme/colors';
import { LEGAL_URLS } from '@/infra/config/legal-urls';

export default function WelcomeScreen() {
  const { t } = useTranslation();
  const router = useRouter();
  const onContrast = useOnContrastColor();
  const primary = usePrimaryColor();

  const openPrivacy = async () => {
    await WebBrowser.openBrowserAsync(LEGAL_URLS.privacyPolicy);
  };

  return (
    <Surface className="flex-1 items-center justify-center px-8">
      <View className="items-center gap-6 max-w-sm">
        <Scissors size={64} color={primary} />
        <Text className="text-4xl font-bold text-center">{t('onboarding.welcome.title')}</Text>
        <Text variant="muted" className="text-center text-base">
          {t('onboarding.welcome.message')}
        </Text>
        <Button
          onPress={() => router.push('/onboarding/base' as never)}
          className="mt-4"
          accessibilityLabel={t('onboarding.welcome.cta')}
        >
          <Text variant="onPrimary" className="font-semibold">{t('onboarding.welcome.cta')}</Text>
          <ArrowRight size={18} color={onContrast} />
        </Button>

        <Surface variant="muted" className="rounded-2xl px-4 py-3 mt-4">
          <Text variant="muted" className="text-xs text-center">
            {t('onboarding.welcome.privacy_intro')}
          </Text>
          <PressScale onPress={openPrivacy} accessibilityLabel={t('onboarding.welcome.privacy_link')}>
            <Text className="text-xs text-center mt-2 underline">
              {t('onboarding.welcome.privacy_link')}
            </Text>
          </PressScale>
        </Surface>
      </View>
    </Surface>
  );
}
```

- [ ] **Step 2 : Typecheck + lint**

Run : `pnpm typecheck && pnpm lint`
Expected : OK.

- [ ] **Step 3 : Smoke test manuel**

Wipe local (Réglages → Cloud → Se déconnecter, ou désinstall+reinstall) pour atterrir sur `/onboarding/welcome`. Vérifier que l'encart info apparaît sous le CTA. Le lien « En savoir plus » ouvre la politique de confid.

- [ ] **Step 4 : Commit**

```bash
git add app/onboarding/welcome.tsx
git commit -m "feat(rgpd): add privacy info notice to onboarding welcome"
```

---

## Task 6 — Encart info dans `login.tsx`

**Files:**
- Modify: `app/auth/login.tsx`

Ajoute un encart d'information sous le bouton « Recevoir le code », visible uniquement en mode email (pas pendant la saisie du code OTP). Deux liens : « Lire les CGU » et « Politique de confidentialité ».

- [ ] **Step 1 : Modifier le fichier**

Dans `app/auth/login.tsx`, ajouter l'import :

```tsx
import * as WebBrowser from 'expo-web-browser';
import { LEGAL_URLS } from '@/infra/config/legal-urls';
```

Puis, à l'intérieur du composant `LoginScreen`, ajouter ces helpers avant `return` (autour de `app/auth/login.tsx:122` au moment de la rédaction) :

```tsx
const openTerms = () => WebBrowser.openBrowserAsync(LEGAL_URLS.terms);
const openPrivacy = () => WebBrowser.openBrowserAsync(LEGAL_URLS.privacyPolicy);
```

Enfin, dans le branchement `else` (étape email, lignes ~179-196 actuellement), juste après le `<Button>` `send_code_cta`, insérer :

```tsx
<Surface variant="muted" className="rounded-2xl px-4 py-3 mt-2">
  <Text variant="muted" className="text-xs text-center">
    {t('auth.terms_notice')}
  </Text>
  <View className="flex-row justify-center gap-4 mt-2">
    <PressScale onPress={openTerms} accessibilityLabel={t('auth.terms_link')}>
      <Text className="text-xs underline">{t('auth.terms_link')}</Text>
    </PressScale>
    <PressScale onPress={openPrivacy} accessibilityLabel={t('auth.privacy_link')}>
      <Text className="text-xs underline">{t('auth.privacy_link')}</Text>
    </PressScale>
  </View>
</Surface>
```

L'encart n'apparaît PAS en étape OTP code (déjà saisi l'email + accepté implicitement → pas besoin de re-montrer).

- [ ] **Step 2 : Typecheck + lint**

Run : `pnpm typecheck && pnpm lint`
Expected : OK.

- [ ] **Step 3 : Smoke test manuel**

Naviguer Réglages → Cloud → bouton « Se connecter ». L'écran login affiche l'encart sous le bouton « Recevoir le code ». Les deux liens ouvrent les bonnes URLs in-app. Après envoi du code, l'encart n'est plus visible (étape OTP).

- [ ] **Step 4 : Commit**

```bash
git add app/auth/login.tsx
git commit -m "feat(rgpd): add terms+privacy notice on login email step"
```

---

## Task 7 — Vérification finale

- [ ] **Step 1 : Tests**

Run : `pnpm test`
Expected : tous verts (cette section ne touche aucune logique testée, donc pas de régression attendue).

- [ ] **Step 2 : Typecheck + lint**

Run : `pnpm typecheck && pnpm lint`
Expected : OK.

- [ ] **Step 3 : Smoke test parcours complet**

Sur device :
1. Désinstaller l'app puis la réinstaller (ou wipe local).
2. Onboarding welcome → encart info présent, lien fonctionne.
3. Avancer dans l'onboarding jusqu'aux Réglages.
4. Réglages → section « Légal » présente en bas → ouvrir « Légal & confidentialité » → 3 docs ouvrables, version visible en pied.
5. Réglages → Cloud → Se connecter → encart « En vous connectant... » + 2 liens fonctionnent.

- [ ] **Step 4 : Mettre à jour TODO.md (optionnel)**

Si tu veux marquer la Section A comme livrée à part dans le TODO, ajoute une mention sous « Livrées » avec un placeholder de SHA. Sinon, laisse pour quand A+B+C seront tous mergés.

---

## Open questions (pour mémoire — pas bloquantes pour ce plan)

- **Hébergement effectif des 3 URLs** : à servir avant le merge en prod (Cloudflare Pages / Github Pages / autre). Ce plan ne traite pas la création du contenu HTML — uniquement le branchement app.
- **Identité AE complète** dans les mentions légales : à fournir lors de la rédaction des HTML.
- **Hébergeur du site légal** : conditionne le bloc « Hébergeur » des mentions légales.
