# Business model — design

**Date :** 2026-05-12
**Branch target :** `main` (RN/Expo)
**Statut :** Spec validée en brainstorming, prêt pour writing-plans.
**Nature :** Spec produit + business. Quelques décisions techniques (cutover ORS, tables Supabase, webhooks stores) sont à la frontière et seront implémentées via un plan dédié.

## Goal

Définir le modèle économique de Coup'Laine avant l'ouverture publique : pricing, gating, distribution, stratégie de lancement, et cadre de mesure. La décision impacte directement les prérequis techniques de publication (cutover ORS, intégration IAP, instrumentation analytique).

L'objectif financier ancré : **revenu principal pour l'auteur de l'app** (~3 000 €/mois net à l'horizon 12-18 mois).

## Non-goals

- **Multi-seat / plans famille / multi-praticien partagé.** Out of scope v1. Le marché cible est essentiellement solo (AE).
- **Stripe ou paiement web direct.** Out of scope v1. Distribution mobile uniquement via App Store + Play Store.
- **Pro+ ou tier supérieur** au plan unique. Réservé comme option future, pas implémenté en v1.
- **Anglicisation et expansion EU non-francophone.** Out of scope v1. À reconsidérer phase 4 si la traction francophone est validée.
- **Promo de lancement à durée illimitée ou code promo générique.** Une seule promo "Early Supporter" cappée, pas de mécanique récurrente.

## Synthèse exécutive

| Dimension | Décision |
|---|---|
| Modèle | **Abonnement Pro unique** (pas de freemium, pas de one-shot) |
| Prix mensuel | **12,90 €/mois** |
| Prix annuel | **99 €/an** (–36 % vs. mensuel équivalent) |
| Trial | **30 jours**, démarrage différé au 1er événement réel (création de la 1ère tournée). Pas de CB exigée |
| Post-trial | **Soft paywall lecture seule** (données visibles, écriture bloquée, export RGPD + suppression compte restent dispo) |
| Promo de lancement | **−20 % la 1ère année** pour les **100 premiers abonnés** (mensuel ou annuel mixés). Activation auto, badge "Early Supporter" |
| Distribution | App Store + Play Store, IAP obligatoire. Apple Small Business Program (15 %). Compte Google Play en mode "organization" |
| Géographie launch | FR uniquement en soft launch → FR/BE/CH/LU au public |
| Cartographie backend | **Self-host ORS sur VPS Hetzner, ~15 €/mois au démarrage et jusqu'à ~35 € à 1 000 users.** Migration obligatoire avant ouverture Phase 2 |
| Cible MRR à 12 mois | ≥ 3 000 €, soit ~380 abonnés mix 70/30 annuel/mensuel |

## 1. Modèle de coûts & seuil de rentabilité

### Hypothèses d'usage par utilisateur actif / mois (saison)

| Item | Valeur estimée |
|---|---|
| Clients en base | ~50 |
| Tournées planifiées / mois | ~15 |
| Recalculs matrix ORS par tournée draft (~10 clients × 3 recalculs) | ~500 entries |
| **Total entries matrix ORS / user / mois** | **~7 500** |
| Routings simples ORS | ~10 |
| Backup cloud actif (3 glissants × ~100 kB gzipped) | ~300 kB storage |
| Bandwidth Storage / mois | ~5 MB |

### Coûts plateformes

#### Cartographie — décision : self-host ORS

L'API publique d'OpenRouteService (plan Standard, 0 €) est plafonnée à **500 matrix/jour collectivement** — saturée dès 2-3 utilisateurs actifs. Le plan Collaborative gratuit est interdit aux usages commerciaux. **HeiGIT n'offre pas de plan commercial managé public** (confirmé par leur forum officiel : *« we don't offer commercial plans »*).

Options évaluées :

| Provider | Coût / user / mois | Viable | Note |
|---|---|---|---|
| Google Maps Compute Route Matrix | ~33 € | ❌ | $5/1 000 éléments × 7 500 = prohibitif |
| Mapbox Matrix | ~9-10 € | ❌ | Discount volume insuffisant pour ce prix de subscription |
| ORS commercial managé | N/A | ❌ | N'existe pas publiquement |
| **ORS self-host (GPLv3)** | **~0,03 € (fixe VPS)** | ✅ | Drop-in, zéro migration app-side |
| Valhalla self-host (MIT) | ~0,03 € (fixe VPS) | ✅ (plan B) | Migration API ~1 semaine, pas justifiée |

**Décision : self-host ORS sur VPS Hetzner CX32 (4 vCPU, 8 GB) ~5,99 € HT/mois ou CCX13 dédié ~13 €/mois.** Plan B documenté : Valhalla self-host si l'instance ORS pose des problèmes opérationnels chroniques après 6 mois en prod.

Justification du choix ORS vs Valhalla :
- Le proxy actuel (`supabase/functions/ors-proxy/`) est un thin pass-through → switch = changer une var d'env d'upstream URL. **Zéro changement app-side**.
- ORS backend GPLv3 : la GPL régit la *redistribution*, pas l'usage interne en SaaS. HeiGIT exploite eux-mêmes ORS en SaaS public.
- 100 % parité features (même codebase que l'API publique).
- L'argument MIT > GPL pour Valhalla est légitime mais ne justifie pas le coût de migration (~1 semaine dev + tests).

#### Supabase

| Tier | Coût | Couvre |
|---|---|---|
| Free | 0 € | ~50 users actifs |
| **Pro** | **23 €/mois fixe** | Plusieurs milliers d'users (8 GB DB, 100 GB storage, 250 GB bandwidth, 100k MAU) |

#### Stores

- Apple Small Business Program : **15 %** sur tous revenus < 1 M $/an. **À activer dès création compte.**
- Google Play : 15 % sur les premiers 1 M $/an. Identique.
- **Coût marginal stores = 15 % du prix affiché.**

#### TVA

- Stores = "merchant of record" : collectent et reversent la TVA. Le dev reçoit le net hors TVA.
- Pas de blocage avec franchise TVA AE (les stores gèrent à leur niveau).

### Synthèse coûts mensuels

| Volume users actifs | Cartographie (self-host ORS) | Supabase | Total /mois | Par user |
|---|---|---|---|---|
| 50 | 15 € (CX32 + backup space) | 0 € (free) | 15 € | 0,30 € |
| 200 | 15 € (même VPS, sous-utilisé) | 23 € | 38 € | 0,19 € |
| 500 | 20 € (upgrade CCX13) | 23 € | 43 € | 0,09 € |
| 1 000 | 35 € (CCX23 ou équivalent) | 23 € | 58 € | 0,06 € |

Le coût cartographie est essentiellement fixe par palier de VPS. La ramp 15 → 35 € correspond à 2-3 upgrades successifs au fur et à mesure que la charge CPU/RAM du matrix engine sature, pas à un coût marginal par requête.

### Seuil de rentabilité — atteinte de l'objectif "revenu principal" (~3 000 €/mois net)

Avec net par user = prix affiché × 0,85 − coût serveur (~0,30 €) :

| Mix annuel/mensuel | Net moyen / user / mois | Users payants pour 3 000 € |
|---|---|---|
| 50/50 | 8,69 € | ~345 |
| **70/30 (cible)** | **7,90 €** | **~380** |
| 80/20 | 7,50 € | ~400 |

Sur marché élargi ~2 000 utilisateurs, pénétration cible ~19-22 %. Ambitieux mais cohérent avec accès organique au métier (auteur du métier / proche directe).

## 2. Structure de pricing

### Plans

| Plan | Prix affiché | Mensuel équivalent | Net après stores 15 % | Net après serveur (~0,30 €) |
|---|---|---|---|---|
| **Mensuel** | **12,90 €/mois** | 12,90 € | 10,97 € | **10,67 €/mois** |
| **Annuel** | **99 €/an** | 8,25 €/mois | 84,15 € (7,01 €/mois) | **6,71 €/mois** |

### Trial

- **Durée : 30 jours.**
- **Démarrage différé : au premier événement signalant un usage réel** (création de la 1ère tournée), pas à l'installation. Évite qu'un utilisateur qui télécharge en off-season consomme son trial avant la saison.
- **Pas de CB exigée** au démarrage du trial. Friction minimale.
- **Prolongation manuelle SAV possible** via un champ `trial_end_override` sur l'utilisateur (Supabase). Geste de support, pas une feature publique exposée.

### Post-trial : soft paywall lecture seule

À l'expiration du trial sans abonnement actif :

- ✅ Visualisation de toutes les données existantes (clients, tournées passées, historiques, prestations).
- ✅ Export RGPD via `useExportData`.
- ✅ Suppression compte cloud.
- ✅ Backup automatique continue (filet de sécurité — `BackupScheduler` ne s'arrête pas).
- ❌ Création/modification de tout objet métier (clients, tournées, prestations, statuts manuels, historique manuel).
- ❌ Calcul d'itinéraires (matrix ORS).
- Bandeau persistant in-app : « Réactivez votre abonnement pour continuer à créer des tournées ».

Choix de design délibéré aligné avec CLAUDE.md *« user data is sacred »*. Pas de hard paywall qui bloquerait l'accès aux données.

### Promo de lancement — "Early Supporter"

| Paramètre | Valeur |
|---|---|
| **Cible** | **100 premiers abonnés payants** (mensuel ou annuel mixés) |
| **Réduction** | **−20 % sur la 1ère année** uniquement |
| **Tarifs effectifs** | Mensuel **10,32 €/mois** pendant 12 mois<br>Annuel **79,20 €** la 1ère année |
| **Activation** | Auto sur les 100 premiers, sans code à saisir. Badge "Early Supporter" affiché in-app |
| **Renouvellement** | Au plein tarif après 12 mois |
| **Communication** | Bandeau in-app + store listing : « Early Supporter — les 100 premiers paient −20 % la 1re année. Plus que X places. » |
| **Coût maximum foregone** | ~320 € de revenu (100 × 16 €/an d'écart) |

### Versionnement de prix (grandfathering)

- Les abonnés existants conservent leur tarif tant que leur abonnement reste actif (comportement par défaut Apple/Google sur auto-renew).
- Une hausse de prix s'applique aux nouveaux abonnements et aux renouvellements seulement.
- Communication email + in-app 30 jours avant toute hausse.
- Une baisse de prix s'applique immédiatement à tous, y compris existants (geste de bonne foi, automatique côté stores au prochain renouvellement).

### Devise

- EUR comme référence. Les stores gèrent les conversions automatiques par région utilisateur.
- Pas de pricing custom par marché en v1.

## 3. Périmètre fonctionnel & gating

### Plan Pro — toutes les features actuelles + court terme

Liste exhaustive incluse dans l'abonnement :

- Gestion clients (illimités)
- Tournées planifiées, optimisées, complétées (illimitées)
- Catalogue prestations (illimité)
- Statuts personnalisés système + manuels (illimités)
- Multi-praticien (espèces & catégories illimitées)
- Historique manuel + tournées
- Cartographie & matrix routing
- Sync cloud (backups quotidiens + restore)
- Recherche full-text, KPIs, statuts
- Système d'aide (tutos, coach-marks Phase 1 + 2)
- Export RGPD, anonymisation client, suppression compte
- Themes light/dark, accessibilité WCAG AA

### Ce qui sort du plan (paywall)

Pas de feature « gratuite à vie ». Post-trial sans abonnement = soft paywall (cf. section 2).

### Réserve stratégique pour un futur Pro+ (PAS implémenté en v1)

Documentation des candidats pour ne pas peindre dans un coin si on veut introduire un tier supérieur après ~12 mois :

| Candidate Pro+ | Lien TODO existant | Sensibilité prix |
|---|---|---|
| Génération facture PDF + envoi client | #7 (long terme) | Élevée |
| Mention RGPD imprimable pour les clients du tondeur | Spec RGPD §post-MVP "B.bis" | Moyenne |
| Intégrations compta (Tiime, Indy, Henrri export) | Pas encore au TODO | Élevée |
| Sync multi-device temps-réel | Cloud Phase 2 (out of scope actuel) | Élevée |
| Multi-seat (apprenti, conjoint) | Pas au TODO | Très élevée |
| Analytics avancés / bilan annuel exportable | Pas au TODO | Faible-moyenne |

**Décision actée :** pas de Pro+ en v1. Réserve à revisiter à mois 9 post-launch si signal de demande ou besoin d'upsell.

### Mode démo / seed data pendant le trial

**Pas de seed démo** en v1. L'onboarding existant (RGPD info → adresse → espèces → premier client) couvert par les coach-marks Phase 1 + 2 suffit. Évite code en plus + risque de confusion avec vraies données.

## 4. Distribution & stratégie de lancement

### Canaux

- **Apple App Store** — abonnement IAP via StoreKit 2 (`react-native-iap` ou `expo-store-kit`).
- **Google Play Store** — abonnement IAP via Google Play Billing Library.
- **Pas de Stripe / paiement web direct** en v1.

### Comptes développeur à provisionner

| Compte | Coût | Délai | Pré-requis |
|---|---|---|---|
| Apple Developer Program | 99 $/an | 1-3 jours | Identité AE + RIB pour payouts |
| Apple Small Business Program | gratuit | Demande à soumettre dès l'inscription au Developer Program ; activation au cycle fiscal suivant | < 1 M $/an de revenu |
| Google Play Console (mode **organization**) | 25 $ one-time | ~1-2 semaines (vérification org) | SIRET + justificatif INSEE |

**Critique** : créer le compte Google Play en mode **"organization"** (pas "personal") dès le départ. Une AE avec SIRET y est éligible. Bénéfice : exonération de la contrainte récente *« 12 testeurs × 14 jours »* qui ne s'applique qu'aux comptes personnels créés après 13/11/2023.

### Stratégie en 3 phases

#### Phase 1 — Beta privée (6-8 semaines)

| Item | Valeur |
|---|---|
| Cible | 12-20 testeurs recrutés via réseau direct |
| Canal | TestFlight (iOS) + Google Play Internal Testing |
| Paywall | **Désactivé** (flag serveur "trial illimité" pour les testeurs) |
| ORS backend | **API publique** tant que le volume reste sous quota (à surveiller, plan Standard 500 matrix/jour) |
| Objectif | Valider la willingness-to-pay |
| Méthode | Entretiens 30 min × testeur en semaine 4 + form in-app fin de beta |

Les entretiens semaine 4 portent sur : *« À combien tu paierais ? »*, *« 9 / 15 / 20 € — tu prendrais quoi ? »*, *« Quelle feature tu paierais en plus ? »*. Form in-app semaine 7-8 : slider 0-50 € sur la valeur perçue.

**Provisionnement ORS self-host pendant la beta** (calendrier indicatif) :
- Semaines 1-2 : provisionner VPS Hetzner.
- Semaine 3 : déployer ORS via Docker compose officiel + extract Geofabrik France.
- Semaine 4 : câbler endpoint privé sécurisé, re-pointer `ors-proxy` via env var.
- Semaine 5 : observation stabilité 7 jours, rollback path validé.
- Semaine 6 : cron mensuel de refresh OSM extract.
- Semaines 7-8 : buffer.

#### Phase 2 — Soft launch FR (4-6 semaines)

| Item | Valeur |
|---|---|
| Cible | 100 premiers Early Supporters (tarif −20 % activé) |
| Géo | FR uniquement (lock store sur la région) |
| Paywall | **Activé** avec trial 30 j (start différé) |
| ORS | **Self-host obligatoirement opérationnel** avant ouverture |
| Distribution | Organique (groupes FB tondeurs, syndicats, salons) |
| Objectif KPI | Conversion trial → payant ≥ 30 % |

#### Phase 3 — Launch public (à partir de Phase 2 + 6 semaines, si KPIs OK)

| Item | Valeur |
|---|---|
| Géo | FR + BE + CH + LU |
| Paywall | Tarif catalog 12,90 €/mois ou 99 €/an, promo Early Supporter close ou pleine |
| Distribution | Organique + landing page statique sur `ravnkode.com/coup-laine/` (domaine déjà utilisé pour pages légales RGPD) |
| Anglicisation | Pas en v1 |

### Seuil pivot KPI entre Phase 1 et Phase 2

Si la **willingness-to-pay médiane** issue des entretiens beta tombe **sous 8 €/mois**, baisser le tarif catalog à **9,90 €/mois et 79 €/an** **avant** d'activer le paywall Phase 2. Réviser projections financières en conséquence.

### Refunds

Géré entièrement par les stores (Apple via `reportaproblem.apple.com`, Google automatique sous 48 h). Pas de promesse "satisfait ou remboursé" affichée — le trial 30 j fait ce rôle.

## 5. Validation, KPIs et révision post-launch

### KPIs Cercle 1 — santé du business

| KPI | Cible 6 mois | Cible 12 mois | Calcul |
|---|---|---|---|
| **MRR** | ≥ 1 200 € | ≥ 3 000 € | Σ abonnements actifs ramenés au mois |
| **Conversion trial → payant** | ≥ 25 % | ≥ 30 % | trials convertis / trials terminés |
| **Churn mensuel** | ≤ 5 % | ≤ 3 % | résiliés ce mois / abonnés début de mois |
| **Abonnés payants** | ≥ 150 | ≥ 380 | mensuels + annuels actifs |

### KPIs Cercle 2 — signaux d'usage prédictifs

| Signal | Pourquoi |
|---|---|
| Tournées créées / user actif / mois | Sous 3/mois → risque churn saison suivante |
| Clients en base par utilisateur | Sous 10 → user "essaie", pas encore engagé |
| Backups cloud effectifs | Indicateur d'opt-in cloud → user investi |
| Délai install → 1ère tournée | > 7 jours = friction d'onboarding |

### KPIs Cercle 3 — feedback humain

- **NPS** : sondage in-app à 90 jours d'abonnement actif. Échelle 0-10 + commentaire libre.
- **Mails de churn** : trigger auto sur résiliation : *« Tu peux nous dire pourquoi ? »*.
- **Veille community** : groupes FB tondeurs, forums pro. 1 fois/mois manuel.

### Seuils de décision

| Symptôme observé | Décision proposée |
|---|---|
| Conversion < 20 % à 3 mois | Problème d'onboarding ou valeur perçue. Réinterview 10 churns. Fix UX d'abord, pas le prix |
| Conversion < 20 % ET churners disent "trop cher" | Baisser à 9,90 €/mois et 79 €/an |
| Conversion ≥ 30 % ET volume saturé ~300 payants à 12 mois | Élargir géo (EU non-francophone), lancer Pro+ |
| Churn > 7 % en saison creuse | Promouvoir l'annuel plus agressivement |
| MRR < 800 € à 9 mois | Signal pivot — revoir hypothèse marché + canaux. Reconsidérer freemium |
| MRR > 4 000 € à 18 mois | Modèle valide, opportunité d'expansion. Pro+ + géo + investir localisation |

### Cadence de revue

| Cadence | Format | Décisions possibles |
|---|---|---|
| Hebdomadaire | 15 min, dashboard simple (signups, trial starts, conversions, MRR) | Alerte si déviation aberrante. Pas de décision systémique |
| Mensuelle | 1 h, 4 KPIs + signaux usage + feedbacks churn | Ajustements opérationnels : onboarding, copy, coach-marks |
| Trimestrielle | Demi-journée, revue stratégique | Pricing, Pro+ go/no-go, géo expansion |

### Révision du pricing

- **Pas de révision avant 6 mois** post-launch public.
- **Première fenêtre formelle : mois 9.**
- Hausse → grandfathering, communication 30 j avant.
- Baisse → automatique pour tous au prochain renouvellement.
- Ajout Pro+ → Pro reste 12,90 €, Pro+ se positionne ~19,90-24,90 €/mois selon features.

### Infrastructure data minimale

Pas d'outil analytics tiers en v1.

**Tables à créer dans Supabase** (sera implémenté dans le plan dédié) :

- `subscription_events` : log append-only des events (trial_started, trial_ended, subscribed, churned) avec timestamps + plan.
- `usage_metrics` : snapshot mensuel par user (tour_count, client_count, mau_flag).

**Edge Function `subscription-webhook`** : reçoit les notifications App Store Server API + Google Play Real-time Developer Notifications → écrit dans `subscription_events`.

**Dashboard** : SQL ad-hoc Supabase Studio + Google Sheet exporté manuellement. Migrer vers Metabase / Supabase Dashboards si besoin émerge après 6 mois.

### Risques systémiques à surveiller

1. **Concurrence directe** : veille mensuelle App Store FR sur "tonte", "tondeur", "pareur", "tournée".
2. **Politique stores qui change** (commission, exigences nouvelles) : préparer scénarios de repli (Stripe web + activation in-app via DMA/Epic settlement).
3. **Coût ORS self-host dérive** : surveille saturation CPU/RAM VPS, plan d'upgrade.
4. **Saisonnalité churn** : observer si abonnés mensuels souscrits en mars/avril résilient massivement en septembre. Si oui, push annuel renforcé.

## Open questions (déférées)

- **Choix exact entre `react-native-iap` et `expo-store-kit`** pour l'intégration IAP côté app. Trade-off compatibility / maintenance / DX. À trancher en début de plan d'implémentation.
- **Mécanisme exact d'identification "100 premiers Early Supporters"** : compteur Supabase atomique vs. enregistrement à la souscription. Cas de concurrence à traiter dans le plan.
- **Format précis du badge "Early Supporter"** dans l'UI (in-app uniquement, ou aussi visible publiquement type "founder member" ?). UX à brainstormer si jugé nécessaire.
- **Choix du VPS provider** (Hetzner allemand, Hetzner Falkenstein vs. OVH France pour proximité RGPD avec Supabase Paris). Pas un sujet bloquant, à trancher en plan d'implémentation.
- **Format de la landing page** `ravnkode.com/coup-laine/` (Phase 3) : statique simple vs. mini-site avec captures. Hors scope de cette spec, à reprendre en pre-launch Phase 3.

## Décisions à exporter vers d'autres documents

- **TODO.md** — marquer #4 livré (cette spec) une fois le plan d'implémentation également produit. Le bouclage final = ouverture publique de l'app.
- **CLAUDE.md** — pas de modification immédiate. Si une convention durable émerge du plan d'implémentation (ex. naming des events `subscription_events`), elle sera ajoutée à ce moment-là.
- **Spec future** — un "launch readiness checklist" comme document opérationnel à part (pas dans cette spec) : provisionnement comptes stores, screenshots ASO, copy store listing, contacts beta.

## References / sources

- [openrouteservice — Plans (Standard / Collaborative / On-Premise)](https://staging.openrouteservice.org/plans/)
- [openrouteservice — License (GPLv3 backend)](https://github.com/GIScience/openrouteservice/blob/main/LICENSE)
- [openrouteservice — System requirements for self-hosting](https://giscience.github.io/openrouteservice/run-instance/system-requirements)
- [openrouteservice — Forum "Price for Commercial use of OPS"](https://ask.openrouteservice.org/t/price-for-commercial-use-of-ops/409)
- [HeiGIT contact (custom enterprise quote)](https://openrouteservice.org/contact/)
- [Valhalla GitHub (MIT)](https://github.com/valhalla/valhalla)
- [Self-hosting Valhalla with Docker tutorial](https://blog.rtwilson.com/simple-self-hosted-openstreetmap-routing-using-valhalla-and-docker/)
- [Google Maps Platform — billing & pricing](https://developers.google.com/maps/billing-and-pricing/pricing)
- [Google Maps — Compute Route Matrix billed per element](https://developers.google.com/maps/documentation/routes/usage-and-billing)
- [Mapbox pricing — Matrix API per-element](https://www.mapbox.com/pricing)
- [Google Play — App testing requirements for new personal developer accounts (12 testers × 14 days, personal accounts only)](https://support.google.com/googleplay/android-developer/answer/14151465)
- [Apple Small Business Program (15 % rate)](https://developer.apple.com/app-store/small-business-program/)
- [Coup'Laine TODO.md — entry #4](../../TODO.md)
- [Coup'Laine spec — Cloud sync Phase 1 (architecture Supabase + ORS proxy)](2026-05-01-cloud-sync-design.md)
- [Coup'Laine spec — RGPD MVP (export, anonymization, account deletion)](2026-05-06-rgpd-mvp-design.md)
- [Coup'Laine spec — Force update + version gate](2026-05-07-version-gate-design.md)
