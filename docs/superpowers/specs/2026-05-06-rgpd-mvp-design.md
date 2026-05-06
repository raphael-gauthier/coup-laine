# RGPD MVP — design

**Date:** 2026-05-06
**Scope:** Mise en conformité RGPD minimale viable pour ouverture publique sur Play Store + App Store. Couvre les surfaces légales in-app + hébergées, l'anonymisation d'un client (droit à l'effacement art. 17), la suppression du compte cloud (art. 17 sur le compte utilisateur) et l'export portabilité (art. 20).

## 1. Goals

- Publier 3 documents légaux hébergés (mentions légales, politique de confidentialité, CGU + accord de sous-traitance art. 28) accessibles depuis l'app via `expo-web-browser`.
- Informer l'utilisateur des traitements externes (Supabase, OpenRouteService, BAN) au premier lancement (information art. 13, sans consentement bloquant : la base légale est l'exécution du contrat).
- Permettre la suppression d'un client par anonymisation (scrub de l'identité + adresse + notes, préservation des éléments comptables conformément à l'art. L123-22 du Code de commerce).
- Permettre la suppression complète du compte cloud (backups + identité Supabase Auth) en 1 clic, avec confirmation typée.
- Permettre l'export portabilité des données (snapshot JSON décompressé, partagé via share-sheet natif).

## 2. Non-goals

- Modèle de mention d'information imprimable destiné aux clients du tondeur (= v2 RGPD, Section B.bis).
- Durée de conservation configurable (en MVP : 3 backups glissants déjà en place + 10 ans pour la compta = mention dans la politique, pas d'UI).
- Cookie banner (sans objet, app native).
- Soft-delete du compte avec annulation 30 jours (la suppression est immédiate et irréversible).
- DPO désigné (non obligatoire pour AE sous les seuils art. 37 RGPD).
- Politique d'incident publique (interne).

## 3. Cartographie des responsabilités

| Acteur | Statut | Périmètre |
|---|---|---|
| Éditeur (toi, AE, SIRET) | **Responsable de traitement** | Email utilisateur, uid Supabase, logs Auth |
| Éditeur | **Sous-traitant art. 28** | Backups cloud (contenu = données métier de l'utilisateur) |
| Utilisateur (tondeur) | **Responsable de traitement** | Données de ses propres clients (identité, coordonnées, notes, historique) |
| Supabase Inc. (eu-west-3 / AWS Luxembourg) | **Sous-sous-traitant** | Auth + Storage + Edge Functions |
| HeiGIT (OpenRouteService, Heidelberg) | **Sous-sous-traitant** | Calcul d'itinéraires (coords GPS) |
| BAN data.gouv.fr | **Sous-sous-traitant** | Autocomplétion d'adresses (chaîne tapée + résultats) |

## 4. Architecture d'ensemble

Trois blocs fonctionnels indépendants, sans dépendance technique entre eux. Livrables séquentiellement ou en parallèle.

```
A. Surfaces légales (3 docs hébergés + écran in-app + encarts onboarding/login)
B. Anonymisation client (use case pur + repo + UI fiche client)
C. Suppression compte cloud + export portabilité (Edge Function + UI Cloud)
```

Ordre de livraison recommandé : **A → C → B** (A et C sont bloquants pour la sortie sur les stores ; B est utile mais peut sortir en patch).

---

## 5. Section A — Surfaces légales

### 5.1 Documents hébergés

Trois documents HTML statiques servis sur `ravnkode.com/coup-laine/legal/` (chemin par défaut, configurable). Constantes centralisées dans `src/infra/config/legal-urls.ts` :

```ts
export const LEGAL_URLS = {
  mentionsLegales: 'https://ravnkode.com/coup-laine/legal/mentions-legales.html',
  privacyPolicy:   'https://ravnkode.com/coup-laine/legal/politique-confidentialite.html',
  terms:           'https://ravnkode.com/coup-laine/legal/cgu.html',
} as const;
```

**Document 1 — Mentions légales** (~1 page, LCEN art. 6) :
- Éditeur : nom, prénom, statut AE, SIRET, adresse pro, email
- Directeur de la publication : idem
- Contact RGPD : `rgpd-couplaine@ravnkode.com`
- Hébergeur backups : Supabase Inc., 970 Toa Payoh North #07-04 Singapore, région eu-west-3 opérée par AWS EMEA SARL, 38 avenue John F. Kennedy, L-1855 Luxembourg
- Hébergeur du site légal : selon choix final (cf §11)

**Document 2 — Politique de confidentialité** (~3-4 pages, art. 13 RGPD) :
1. Identité du responsable de traitement
2. Données collectées :
   - Compte cloud (opt-in) : email, uid Supabase, timestamps connexion
   - Données métier saisies par l'utilisateur (clients, tournées, prestations) — traitées comme sous-traitant quand backupées
   - Aucune télémétrie / analytics / publicité
3. Bases légales :
   - Compte cloud → exécution du contrat (art. 6.1.b)
   - Données métier dans le cloud → sous-traitance art. 28
   - ORS / BAN → intérêt légitime + nécessité technique
4. Sous-traitants : Supabase, OpenRouteService, BAN
5. Durées de conservation :
   - Backups cloud : 3 backups glissants (rotation auto)
   - Compte Auth : tant que pas de demande de suppression
   - Données locales : sur l'appareil tant que pas de désinstallation / wipe
   - Données comptables (montants, dates, prestations) : 10 ans (Code de commerce art. L123-22)
6. Droits : accès, rectification, effacement, portabilité, opposition, limitation. Modalité : `rgpd-couplaine@ravnkode.com`. Délai 1 mois.
7. Réclamation CNIL : lien `cnil.fr/plaintes`
8. Cookies : aucun
9. Date de dernière mise à jour en pied de page

**Document 3 — CGU + accord de sous-traitance** (~3 pages, deux parties) :
- Partie 1 — CGU : objet, gratuité (statut à confirmer cf #4 du TODO), comportement attendu, propriété intellectuelle, responsabilité limitée, droit français, juridiction.
- Partie 2 — Accord de sous-traitance art. 28 : objet, durée (vie du compte), nature et finalité, catégories de données, obligations du sous-traitant (sécurité, confidentialité, sous-sous-traitants listés, assistance DSR, notification de violation sous 72h, restitution / suppression en fin de contrat), obligations du RT (licéité du traitement, info des personnes concernées). Mention finale : « L'acceptation des présentes CGU lors de la création du compte cloud vaut signature de l'accord de sous-traitance. »

### 5.2 Écran in-app

Nouveau fichier `app/(tabs)/settings/legal.tsx` :

```
┌─ Légal & confidentialité ────────┐
│  > Mentions légales              │
│  > Politique de confidentialité  │
│  > CGU et accord de sous-       │
│    traitance                     │
│                                   │
│  Version de l'app : 1.x.y        │
└──────────────────────────────────┘
```

Chaque ligne ouvre l'URL via `expo-web-browser.openBrowserAsync` (sheet in-app type SFSafariViewController / Custom Tabs, retour propre à l'app au close). Plus propre qu'une vraie WebView intégrée : zéro dépendance supplémentaire, gestion correcte des fonts/JS/cookies/a11y, pas d'alourdissement du bundle.

Nouvelle entrée `SettingsRow` dans `app/(tabs)/settings/index.tsx`, dans une section dédiée `settings.section_legal` placée en bas de l'écran (après la section Cloud).

### 5.3 Encart info onboarding (welcome)

Modif `app/onboarding/welcome.tsx` :
- Ajout d'un encart `Surface variant="muted"` sous le bouton CTA actuel :
  > « Coup'Laine fonctionne en local sur votre appareil. L'autocomplétion d'adresse (BAN) et les calculs d'itinéraire (OpenRouteService) nécessitent une connexion internet. La sauvegarde cloud est optionnelle. »
  > [En savoir plus →] (lien vers politique de confidentialité)
- Pas de checkbox bloquante — information art. 13, pas consentement.
- Wording évite « j'accepte » (la base légale est l'exécution du contrat, pas le consentement).

### 5.4 Encart info pré-magic-link

Modif `app/auth/login.tsx` :
- Sous le champ email + bouton « Recevoir le lien », ajouter :
  > « En vous connectant, vous acceptez les CGU et l'accord de sous-traitance. Vos données métier seront sauvegardées sur Supabase (eu-west-3, Paris). »
  > [Lire les CGU →] [Politique de confidentialité →]
- L'envoi du magic link vaut consentement (acte positif clair).

---

## 6. Section B — Anonymisation client

### 6.1 Schéma DB

Ajout d'une colonne sur `clients` :

```ts
anonymizedAt: text('anonymized_at'),  // ISO timestamp, null si actif
```

Migration Drizzle générée via `pnpm db:generate`. Colonne nullable, pas de backfill nécessaire.

**Backup schema bump v3 → v4** : `ClientRow` ajoute `anonymizedAt: optStr`. Helper `migrateV3ToV4` qui injecte `anonymizedAt: null` partout (forward-only, même pattern que `migrateV2ToV3` existant). Conserver `BackupSnapshotV3Schema` exporté pour la compatibilité descendante.

### 6.2 Use case domaine

Nouveau fichier `src/domain/use-cases/anonymize-client.ts` — pure, testable, pas d'I/O :

```ts
export const ANONYMIZED_DISPLAY_NAME = 'Client supprimé';

export interface AnonymizationPlan {
  client: { id: string; updates: Partial<Client> };
  tourStopUpdates: Array<{ id: string; clientNameSnapshot: string; notes: null }>;
  manualEntryUpdates: Array<{ id: string; notes: null }>;
  distanceMatrixDeletes: Array<{ fromId: string; toId: string }>;
}

export function planAnonymization(
  client: Client,
  tourStops: TourStop[],
  manualEntries: ManualHistoryEntry[],
  distanceMatrix: DistanceMatrixEntry[],
  now: string,
): AnonymizationPlan;
```

Décisions de scrub :

| Champ | Décision | Raison |
|---|---|---|
| `clients.displayName` | → `'Client supprimé'` | placeholder lisible dans historiques |
| `clients.phones` | → `[]` | identifiant direct |
| `clients.addressLabel/City/Postcode` | → `null` | identifiant indirect |
| `clients.latitude/longitude` | → `null` | identifiant indirect (géoloc) |
| `clients.animalCounts` | → `[]` | non requis pour la compta |
| `clients.lastShearingDate` | gardé | KPI utile, non identifiant |
| `clients.markerColorHex` | gardé | pref UI, non identifiant |
| `clients.isWaiting` | → `false` | sortir des listes actives |
| `clients.isBanned` | → `false` | idem |
| `clients.anonymizedAt` | → `now` | marqueur |
| `tour_stops.clientNameSnapshot` | → `'Client supprimé'` | scrub identité |
| `tour_stops.notes` | → `null` | peuvent contenir données perso |
| `tour_stops.travelFeeCents`, montants, paymentMethod, dates, isPaid | gardés | obligation comptable 10 ans (L123-22) |
| `manual_history_entries.notes` | → `null` | peuvent contenir données perso |
| `manual_history_entries.services`, montants, dates | gardés | comptable |
| `distance_matrix` (lignes from=id ou to=id) | supprimées | dérivées GPS, plus exploitables |

Idempotence : si `client.anonymizedAt != null`, le plan retourne tableaux vides + updates client vides (no-op).

### 6.3 Repository

Nouvelle méthode `ClientRepository.anonymize(id, now)` exécutée dans une transaction unique :

1. SELECT client + tour_stops + manual_entries + distance_matrix lignes concernées
2. `planAnonymization(...)` (use case pur)
3. UPDATE clients (champs scrubbés)
4. UPDATE tour_stops where clientId = id (clientNameSnapshot + notes)
5. UPDATE manual_history_entries where clientId = id (notes)
6. DELETE distance_matrix lignes touchées

L'ancienne méthode `ClientRepository.delete(id)` est conservée (utilisée par `wipeLocalDatabase` et tests). Pas de dépréciation.

### 6.4 Filtrage UI

Toutes les requêtes liste de clients ajoutent `WHERE anonymizedAt IS NULL`. Centralisation dans `ClientRepository` via un helper `activeClientsFilter` réutilisé dans `list`, `listWaiting`, `searchByText`, etc.

L'écran de détail client `app/(tabs)/clients/[id].tsx` :
- Si `anonymizedAt != null` chargé directement par URL : redirige vers la liste avec un toast « Ce client a été supprimé ».
- Sinon : nouveau bouton « Supprimer ce client » (variant `destructive`) en bas de l'écran, en dehors du formulaire.

### 6.5 Dialog de confirmation

Réutilise `ConfirmTypedDialog` (déjà utilisé pour le restore) :
- Titre : « Supprimer ce client ? »
- Message : « Cette action est irréversible. Le nom, les coordonnées, l'adresse et les notes seront effacés immédiatement. L'historique financier (montants, dates, prestations) est conservé conformément à vos obligations comptables. »
- Mot à taper : `SUPPRIMER`
- CTA : « Supprimer définitivement »

### 6.6 Mécanique de cascade FK

Aujourd'hui `tour_stops.clientId` est `notNull()` sans `onDelete: 'cascade'`. La méthode existante `ClientRepository.delete(id)` planterait sur un client avec tournées (bug latent). L'anonymisation n'utilise pas DELETE sur clients, donc ce bug latent n'est ni créé ni corrigé par ce chantier — il reste tel quel.

---

## 7. Section C — Suppression compte cloud + export portabilité

### 7.1 Edge Function `delete-account`

Nouveau dossier `supabase/functions/delete-account/` (parallèle à `ors-proxy/`).

**Auth & autorisation** :
- Reçoit le JWT utilisateur via header `Authorization: Bearer <jwt>`.
- Crée un client Supabase avec `service_role` key pour les opérations admin.
- Crée un client Supabase avec le JWT utilisateur pour vérifier l'identité (`auth.getUser()` → uid).
- Refus 403 si `is_anonymous === true` (les sessions anonymes expirent toutes seules, et ne contiennent ni email ni backup utile).

**Logique** (3 étapes idempotentes) :
1. Lister tous les objects dans `backups/{uid}/` → `storage.from('backups').remove([...])`
2. `from('backups').delete().eq('user_id', uid)` (purge la table d'index)
3. `auth.admin.deleteUser(uid)` (purge identité Auth : email, sessions, magic link history, refresh tokens)

**Réponse** : `200 { ok: true }` ou `4xx/5xx` avec message d'erreur. Aucune donnée sensible renvoyée.

**CORS** : preflight + headers identiques à `ors-proxy`.

### 7.2 Hook `useDeleteAccount` (côté app)

Ajout dans `src/state/queries/auth.ts` :

```ts
export function useDeleteAccount() {
  return useMutation({
    mutationFn: async () => {
      const { error } = await supabase.functions.invoke('delete-account');
      if (error) throw error;
      await wipeLocalDatabase();
      await supabase.auth.signOut().catch(() => {});  // best-effort
      await ensureSession();  // nouvelle session anonyme pour ORS proxy
    },
    onSuccess: () => {
      queryClient.clear();  // purge tous les caches
    },
  });
}
```

**UX onSuccess** : redirige vers `/onboarding/welcome` (l'app repart fresh). Toast : « Votre compte cloud a été supprimé. »

**UX onError** : `mutationErrorToast`. Le user reste connecté, peut retenter. Cas critique : si l'EF plante après remove storage mais avant `deleteUser`, le user a un compte vide → retry idempotent (l'EF redélétera le vide puis supprimera l'auth).

### 7.3 Surface UI suppression

Modif `app/(tabs)/settings/cloud.tsx` :
- Nouveau bouton **« Supprimer mon compte cloud »** (variant `danger`), placé sous le bouton « Se déconnecter du cloud » existant, séparé par un `SectionHeader` « Zone de danger ».
- Visible uniquement si `session && !session.user.is_anonymous`.
- Au clic : `ConfirmTypedDialog` :
  - Titre : « Supprimer définitivement votre compte ? »
  - Message : « Cette action est irréversible. Tous vos backups cloud seront supprimés (vos données locales sur cet appareil aussi). Vous pourrez recréer un compte plus tard, mais sans pouvoir restaurer ce qui aura été effacé. »
  - Mot à taper : `SUPPRIMER`
  - CTA : « Supprimer mon compte »

### 7.4 Bouton « Télécharger mes données » (portabilité art. 20)

Modif `app/(tabs)/settings/cloud.tsx`, au-dessus de la zone de danger :

Nouveau bouton **« Télécharger mes données »** (variant `secondary`) qui :
1. Crée un backup à la volée si nécessaire (réutilise `useCreateBackup`)
2. Télécharge le snapshot JSON depuis Storage (les backups actuels sont stockés en JSON brut, pas gzippés — cf `src/infra/cloud/backups.ts:72` : upload avec `contentType: 'application/json'` sans compression)
3. Écrit dans un fichier temporaire via `expo-file-system` (`coup-laine-export-{ISO}.json`)
4. Ouvre le share-sheet natif via `expo-sharing.shareAsync(uri)` (« Save to Files », « Mail », etc.)

Coût estimé : ~30 lignes de code, matérialise le droit à la portabilité côté UX sans passer par un email manuel. **Nouvelles dépendances à ajouter** : `expo-file-system` et `expo-sharing` (à vérifier dans `package.json` au moment de l'implémentation, ajouter via `pnpm` si absentes).

### 7.5 Note infra : SDK Supabase admin dans Edge Functions

L'Edge Function `delete-account` doit pouvoir appeler `auth.admin.deleteUser`, ce qui nécessite la `service_role` key (pas l'anon key). **À configurer comme nouveau secret Supabase** (l'EF `ors-proxy` existante n'utilise que `ORS_API_KEY`, donc rien de pré-existant à réutiliser). Convention : `SUPABASE_SERVICE_ROLE_KEY`, lue via `Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')`. À ajouter dans le dashboard Supabase → Project Settings → Edge Functions → Secrets.

---

## 8. Footprint i18n

~33 nouvelles clés dans `src/i18n/locales/fr.json` :

**Section A** (~15 clés) :
- `settings.section_legal`
- `settings.legal.row_label`, `.row_hint`, `.screen_title`
- `settings.legal.mentions_legales`, `.privacy_policy`, `.terms`
- `settings.legal.app_version`
- `onboarding.welcome.privacy_intro`, `.privacy_link`
- `auth.login.terms_notice`, `.terms_link`, `.privacy_link`

**Section B** (~10 clés) :
- `clients.detail.delete_button`
- `clients.delete.confirm_title`, `.confirm_message`, `.typed_word`, `.cta`
- `clients.delete.success_toast`, `.error_toast`
- `clients.list.anonymized_redirect_toast`

**Section C** (~8 clés) :
- `cloud.delete_account.section_title`, `.cta`
- `cloud.delete_account.confirm_title`, `.confirm_message`, `.typed_word`
- `cloud.delete_account.success_toast`, `.error_toast`
- `cloud.export_data.cta`, `.success_toast`, `.error_toast`

---

## 9. Tests

| Couche | Sujet | Tests |
|---|---|---|
| Vitest pur (`tests/domain/`) | `planAnonymization` | 8 cas : sans tours, avec tours, avec manual entries, avec distance_matrix, idempotence (déjà anonymisé), préservation montants comptables, préservation lastShearingDate, scrub complet |
| Jest data (`tests/data/`) | `ClientRepository.anonymize` | 3 cas : transaction atomique (rollback FK), filtrage post-anonymisation, tour stop accessible avec snapshot scrubbé |
| Jest data | Backup roundtrip post-anonymisation | 1 cas : export → import préserve `anonymizedAt` et tous les scrubs |
| Jest data | Backup migration v3 → v4 | 1 cas : ancien backup importé reçoit `anonymizedAt: null` partout |
| Jest infra (`tests/infra/`) | `useDeleteAccount` (mocks Supabase) | 3 cas : happy path appelle EF puis wipe puis ensureSession ; EF échoue → pas de wipe ; wipe échoue après EF success → log + continue |
| Manuel scripté (PR) | Edge Function `delete-account` | parcours réel sur projet de test |
| Manuel scripté (PR) | Export portabilité | parcours réel sur device |

Pas de tests UI / widget (cohérent avec la base actuelle quasi vide en widget tests).

---

## 10. Plan de migration

1. **Migration Drizzle** : `pnpm db:generate` après ajout de `anonymizedAt` → fichier généré dans `src/infra/db/migrations/`. À committer tel quel.
2. **Backup schema bump** : version 3 → 4. Helper `migrateV3ToV4` ajouté dans `src/infra/cloud/backup-schema.ts`. Logique de restore mise à jour dans `src/infra/cloud/backups.ts` pour appeler la chaîne v2 → v3 → v4.
3. **Pas de breaking change** côté UX : les backups existants restent restorables.

---

## 11. Open questions (à résoudre avant publication, pas bloquantes pour l'implémentation code)

- **Hébergement effectif des docs légaux** : URL par défaut `ravnkode.com/coup-laine/legal/{...}.html`. À confirmer + servir avant le merge. Alternatives : sous-domaine `legal.ravnkode.com`, domaine séparé `coup-laine.fr`, ou Github Pages `coup-laine.github.io`. C'est juste 3 constantes à changer dans `legal-urls.ts`.
- **Identité AE complète** à inscrire dans les mentions légales : nom, prénom, SIRET, adresse pro. À fournir au moment de la rédaction des HTML, sinon placeholders `{{TO_FILL}}` à remplir absolument avant publication.
- **Hébergeur du site légal** : Cloudflare Pages, Github Pages, autre. Conditionne le bloc « Hébergeur » des mentions légales.
- **Version de l'app affichée dans l'écran Légal** (section 5.2) : à lire via `Constants.expoConfig?.version` (`expo-constants` déjà installé).

---

## 12. Sources réglementaires

- [CNIL — Recommandation applications mobiles (avril 2025)](https://www.cnil.fr/sites/default/files/2025-04/recommandation-applications-mobiles-modifiee.pdf)
- [CNIL — Appliquer le RGPD dans une TPE/PME](https://www.cnil.fr/fr/appliquer-le-rgpd-dans-une-tpe-ou-pme-les-questionsreponses-de-la-cnil)
- [CNIL — Registre des activités de traitement (art. 30)](https://www.cnil.fr/fr/RGPD-le-registre-des-activites-de-traitement)
- [CNIL — Programme de travail 2026](https://www.cnil.fr/fr/accompagnement-des-professionnels-le-programme-de-travail-de-la-cnil-pour-2026)
- RGPD art. 6 (bases légales), 13 (information), 17 (effacement), 20 (portabilité), 28 (sous-traitance)
- LCEN art. 6 (mentions légales obligatoires)
- Code de commerce art. L123-22 (conservation comptable 10 ans)
