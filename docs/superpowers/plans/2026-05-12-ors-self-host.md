# ORS Self-Host & Proxy Cutover Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remplacer l'API publique OpenRouteService par une instance auto-hébergée sur VPS Hetzner, derrière un reverse proxy Caddy avec auth par token, et re-pointer la Supabase Edge Function `ors-proxy` sur cette instance — sans changement côté app.

**Architecture:** VPS Hetzner CCX13 (2 vCPU dédié AMD, 8 GB RAM, 80 GB NVMe, Falkenstein). Docker compose orchestre 2 containers : `ors` (openrouteservice officiel) + `caddy` (TLS Let's Encrypt + token gate + reverse proxy). DNS via Cloudflare sur sous-domaine `coup-laine-ors.ravnkode.com`. Extract OSM France téléchargé de Geofabrik et reconstruit mensuellement par cron. Le Supabase Edge Function `ors-proxy` lit `ORS_BASE_URL` depuis une secret env var ; seul ce paramètre change pour basculer entre l'instance publique (fallback) et l'instance privée.

**Tech Stack:** Hetzner Cloud, Ubuntu 24.04 LTS, Docker Engine + Compose v2, openrouteservice Docker image officielle (v8 stable), Caddy 2.x, Cloudflare DNS, Bash scripts, Supabase Edge Function (Deno).

---

## File Structure

Tous les nouveaux fichiers sont sous `infra/ors-self-host/`. Convention : ce dossier contient l'infrastructure-as-code de l'instance privée ORS — il sera lu et exécuté sur la VPS (pas dans l'app RN).

| Fichier | Rôle |
|---|---|
| `infra/ors-self-host/README.md` | Runbook : provisioning d'une VPS neuve, refresh manuel, troubleshooting, rollback |
| `infra/ors-self-host/docker-compose.yml` | Stack ORS + Caddy + volumes |
| `infra/ors-self-host/Caddyfile` | Reverse proxy TLS + gate token sur header `X-ORS-Token` |
| `infra/ors-self-host/.env.example` | Template des secrets (domaine, token, version d'image) |
| `infra/ors-self-host/.gitignore` | Ignore `.env`, `data/`, `graphs/` |
| `infra/ors-self-host/scripts/install-vps.sh` | One-shot init : Docker, ufw, cloner repo |
| `infra/ors-self-host/scripts/refresh-osm.sh` | Cron mensuel : download PBF + rebuild graphes + restart + smoke test |
| `infra/ors-self-host/scripts/smoke-test.sh` | Vérification matrix + directions via curl (réutilisable manuellement) |
| `supabase/functions/ors-proxy/index.ts` | **Modifié** : `ORS_BASE` lu depuis env `ORS_BASE_URL`, header auth générique |

---

## Décisions ancrées (à appliquer telles quelles)

- **VPS** : Hetzner CCX13 (2 vCPU dédié AMD, 8 GB RAM, 80 GB NVMe SSD, 20 TB traffic) en datacenter Falkenstein (FSN1) — ~13 € HT/mois. RGPD-EU.
- **Image ORS** : tag `openrouteservice/openrouteservice:v8.1.1` (latest stable au moment du plan). Pinné, pas de `latest`.
- **Image Caddy** : tag `caddy:2.8-alpine`.
- **Domaine** : `coup-laine-ors.ravnkode.com` (sous-domaine du domaine que tu possèdes déjà pour les pages légales RGPD).
- **OSM extract** : `france-latest.osm.pbf` depuis `download.geofabrik.de/europe/france-latest.osm.pbf`.
- **Stratégie de refresh OSM** : stop-and-rebuild (downtime ~30-60 min/mois). Blue-green directories documenté comme amélioration future, pas en v1.
- **Auth scheme** : header `Authorization: Bearer <ORS_API_TOKEN>`. Caddy gate. Le proxy mobile-side continue d'envoyer ce header — comportement transparent pour l'app.
- **Profils ORS activés** : `driving-car` uniquement (seul profil utilisé par l'app). Réduit RAM build et runtime.

---

## Tasks

### Task 1: Créer le squelette `infra/ors-self-host/`

**Files:**
- Create: `infra/ors-self-host/README.md`
- Create: `infra/ors-self-host/.gitignore`
- Create: `infra/ors-self-host/.env.example`

- [ ] **Step 1: Créer le dossier et le `.gitignore`**

Run:
```bash
mkdir -p infra/ors-self-host/scripts
```

Create `infra/ors-self-host/.gitignore`:
```
.env
data/
graphs/
*.osm.pbf
*.osm.pbf.md5
backup/
logs/
```

- [ ] **Step 2: Créer le `.env.example`**

Create `infra/ors-self-host/.env.example`:
```
# Domaine public servant l'instance ORS (utilisé par Caddy pour le TLS Let's Encrypt).
ORS_DOMAIN=coup-laine-ors.ravnkode.com

# Secret partagé : tout client doit envoyer "Authorization: Bearer ${ORS_API_TOKEN}".
# Generate via: openssl rand -hex 32
ORS_API_TOKEN=replace-me-with-openssl-rand-hex-32

# Email utilisé par Caddy pour les notifications Let's Encrypt.
CADDY_ACME_EMAIL=rgauthier@expertime.com

# Version d'image ORS pinnée (pas "latest").
ORS_IMAGE_TAG=v8.1.1

# Version d'image Caddy pinnée.
CADDY_IMAGE_TAG=2.8-alpine
```

- [ ] **Step 3: Créer le README skeleton**

Create `infra/ors-self-host/README.md`:
```markdown
# ORS Self-Host

Instance privée OpenRouteService utilisée par l'app Coup'Laine.
Remplace l'API publique HeiGIT qui n'autorise pas les usages commerciaux
au-delà du plan Standard (500 matrix/jour).

## Architecture

- **VPS** : Hetzner CCX13 (FSN1), Ubuntu 24.04 LTS.
- **Containers** : `ors` (openrouteservice) + `caddy` (reverse proxy + TLS).
- **Domaine** : `coup-laine-ors.ravnkode.com`.
- **Auth** : header `Authorization: Bearer <ORS_API_TOKEN>` validé par Caddy.
- **Refresh OSM** : cron mensuel le 1er du mois à 03h00 UTC.

## Provisioning d'une nouvelle VPS

Voir `scripts/install-vps.sh`.

## Refresh manuel de l'extract OSM

```bash
cd /opt/coup-laine/infra/ors-self-host
sudo ./scripts/refresh-osm.sh
```

## Smoke test

```bash
./scripts/smoke-test.sh
```

## Rollback

Pour repasser sur l'API publique HeiGIT en cas d'incident :
1. Dans Supabase Dashboard → Project Settings → Edge Functions → Secrets
2. Set `ORS_BASE_URL=https://api.openrouteservice.org`
3. Set `ORS_API_TOKEN=<clé publique HeiGIT existante>`
4. Redéployer la fonction `ors-proxy`

## Plan B documenté

Si cette instance ORS pose des problèmes opérationnels chroniques après
6 mois en prod, évaluer un switch vers Valhalla self-host (licence MIT,
backé par Interline). Décision business actée dans
`docs/superpowers/specs/2026-05-12-business-model-design.md`.
```

- [ ] **Step 4: Commit**

```bash
git add infra/ors-self-host/.gitignore infra/ors-self-host/.env.example infra/ors-self-host/README.md
git commit -m "feat(infra): ors-self-host skeleton (README, .env.example, .gitignore)"
```

---

### Task 2: Rédiger `docker-compose.yml` ORS + Caddy

**Files:**
- Create: `infra/ors-self-host/docker-compose.yml`

- [ ] **Step 1: Écrire le compose**

Create `infra/ors-self-host/docker-compose.yml`:
```yaml
services:
  ors:
    image: openrouteservice/openrouteservice:${ORS_IMAGE_TAG}
    container_name: coup-laine-ors
    restart: unless-stopped
    environment:
      - XMS=2g
      - XMX=6g
      - REBUILD_GRAPHS=False
      - ors.engine.source_file=/home/ors/files/france-latest.osm.pbf
      - ors.engine.profiles.driving-car.enabled=true
      - ors.engine.profiles.driving-hgv.enabled=false
      - ors.engine.profiles.cycling-regular.enabled=false
      - ors.engine.profiles.cycling-mountain.enabled=false
      - ors.engine.profiles.cycling-road.enabled=false
      - ors.engine.profiles.cycling-electric.enabled=false
      - ors.engine.profiles.foot-walking.enabled=false
      - ors.engine.profiles.foot-hiking.enabled=false
      - ors.engine.profiles.wheelchair.enabled=false
    volumes:
      - ./data:/home/ors/files
      - ./graphs:/home/ors/graphs
      - ./logs:/home/ors/logs
    healthcheck:
      test: ["CMD", "wget", "--spider", "-q", "http://localhost:8080/ors/v2/health"]
      interval: 30s
      timeout: 10s
      retries: 20
      start_period: 1800s
    networks:
      - internal

  caddy:
    image: caddy:${CADDY_IMAGE_TAG}
    container_name: coup-laine-caddy
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    environment:
      - ORS_DOMAIN=${ORS_DOMAIN}
      - ORS_API_TOKEN=${ORS_API_TOKEN}
      - CADDY_ACME_EMAIL=${CADDY_ACME_EMAIL}
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile:ro
      - caddy_data:/data
      - caddy_config:/config
    depends_on:
      - ors
    networks:
      - internal

volumes:
  caddy_data:
  caddy_config:

networks:
  internal:
    driver: bridge
```

- [ ] **Step 2: Lint le YAML**

Run:
```bash
docker compose -f infra/ors-self-host/docker-compose.yml --env-file infra/ors-self-host/.env.example config > /dev/null
```
Expected: exit code 0, pas de message d'erreur. Si Docker n'est pas dispo localement, sauter cette vérif et compter sur la run sur VPS.

- [ ] **Step 3: Commit**

```bash
git add infra/ors-self-host/docker-compose.yml
git commit -m "feat(infra): docker-compose for ors + caddy"
```

---

### Task 3: Rédiger le `Caddyfile`

**Files:**
- Create: `infra/ors-self-host/Caddyfile`

- [ ] **Step 1: Écrire la conf Caddy**

Create `infra/ors-self-host/Caddyfile`:
```
{
    email {$CADDY_ACME_EMAIL}
    # Limite explicite : pas d'admin endpoint exposé (sécurité par défaut).
    admin off
}

{$ORS_DOMAIN} {
    # Tout requête doit présenter "Authorization: Bearer <token>".
    @authed header Authorization "Bearer {$ORS_API_TOKEN}"

    handle @authed {
        # Strip le header Authorization avant de forwarder à ORS
        # (ORS ne l'utilise pas, on évite toute confusion / log de token).
        request_header -Authorization
        reverse_proxy ors:8080
    }

    handle {
        respond "Unauthorized" 401
    }

    log {
        output stdout
        format console
        level INFO
    }

    # Headers de sécurité minimaux.
    header {
        -Server
        Strict-Transport-Security "max-age=31536000"
        X-Content-Type-Options "nosniff"
    }
}
```

- [ ] **Step 2: Valider la syntaxe Caddyfile**

Run (si Caddy dispo localement, sinon différer à la run VPS) :
```bash
docker run --rm -v "$(pwd)/infra/ors-self-host/Caddyfile:/etc/caddy/Caddyfile:ro" caddy:2.8-alpine caddy validate --config /etc/caddy/Caddyfile
```
Expected: `Valid configuration` ou un warning sur env vars manquantes (acceptable).

- [ ] **Step 3: Commit**

```bash
git add infra/ors-self-host/Caddyfile
git commit -m "feat(infra): caddy reverse proxy with bearer-token auth"
```

---

### Task 4: Rédiger `scripts/install-vps.sh`

**Files:**
- Create: `infra/ors-self-host/scripts/install-vps.sh`

- [ ] **Step 1: Écrire le script de provisioning**

Create `infra/ors-self-host/scripts/install-vps.sh`:
```bash
#!/usr/bin/env bash
# One-shot bootstrap pour une VPS Ubuntu 24.04 LTS fraîche.
# À exécuter en root sur la VPS, juste après l'install OS.
# Idempotent : ré-exécution safe.

set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root."
    exit 1
fi

REPO_URL="${REPO_URL:-https://github.com/<REPLACE_WITH_YOUR_GITHUB_USER>/coupe-laine.git}"
REPO_DIR="/opt/coup-laine"

echo "==> 1/6 Update apt + install base packages"
apt-get update -y
apt-get install -y --no-install-recommends \
    ca-certificates curl gnupg ufw fail2ban git cron

echo "==> 2/6 Install Docker Engine + Compose plugin (official Docker repo)"
if ! command -v docker > /dev/null 2>&1; then
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
        https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
        > /etc/apt/sources.list.d/docker.list
    apt-get update -y
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    systemctl enable --now docker
fi

echo "==> 3/6 Configure ufw (allow 22, 80, 443)"
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

echo "==> 4/6 Enable fail2ban defaults"
systemctl enable --now fail2ban

echo "==> 5/6 Clone repo to ${REPO_DIR}"
if [ ! -d "${REPO_DIR}/.git" ]; then
    git clone "${REPO_URL}" "${REPO_DIR}"
else
    git -C "${REPO_DIR}" pull --ff-only
fi

echo "==> 6/6 Done"
echo
echo "Next steps:"
echo "  1. cd ${REPO_DIR}/infra/ors-self-host"
echo "  2. cp .env.example .env  &&  edit .env to fill ORS_DOMAIN, ORS_API_TOKEN, etc."
echo "  3. ./scripts/refresh-osm.sh  (initial download + build, ~30-60 min)"
echo "  4. docker compose up -d"
echo "  5. ./scripts/smoke-test.sh"
```

- [ ] **Step 2: Rendre exécutable + sanity check shellcheck**

Run:
```bash
chmod +x infra/ors-self-host/scripts/install-vps.sh
```

Si `shellcheck` est dispo localement :
```bash
shellcheck infra/ors-self-host/scripts/install-vps.sh
```
Expected: pas de SC2xxx en erreur. Warnings cosmétiques OK.

- [ ] **Step 3: Commit**

```bash
git add infra/ors-self-host/scripts/install-vps.sh
git commit -m "feat(infra): vps bootstrap script (docker + ufw + clone repo)"
```

---

### Task 5: Rédiger `scripts/smoke-test.sh`

**Files:**
- Create: `infra/ors-self-host/scripts/smoke-test.sh`

- [ ] **Step 1: Écrire le smoke test**

Create `infra/ors-self-host/scripts/smoke-test.sh`:
```bash
#!/usr/bin/env bash
# Smoke test pour une instance ORS auto-hébergée.
# Vérifie : (1) health endpoint, (2) directions, (3) matrix.
# À lancer depuis la VPS ou depuis n'importe quelle machine ayant le token.

set -euo pipefail

# Charge .env du dossier parent si présent (mode local sur VPS).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/../.env"
if [ -f "${ENV_FILE}" ]; then
    # shellcheck disable=SC1090
    set -a; . "${ENV_FILE}"; set +a
fi

ORS_DOMAIN="${ORS_DOMAIN:?ORS_DOMAIN must be set}"
ORS_API_TOKEN="${ORS_API_TOKEN:?ORS_API_TOKEN must be set}"
BASE="https://${ORS_DOMAIN}"
AUTH="Authorization: Bearer ${ORS_API_TOKEN}"

echo "==> 1/3 Health endpoint"
http_code="$(curl -fsS -o /dev/null -w '%{http_code}' -H "${AUTH}" "${BASE}/ors/v2/health")"
if [ "${http_code}" != "200" ]; then
    echo "FAIL: health returned ${http_code}"
    exit 1
fi
echo "OK"

echo "==> 2/3 Directions Paris → Lyon (driving-car)"
http_code="$(curl -fsS -o /tmp/ors-directions.json -w '%{http_code}' \
    -H "${AUTH}" -H "Content-Type: application/json" \
    -X POST "${BASE}/ors/v2/directions/driving-car/json" \
    -d '{"coordinates":[[2.3522,48.8566],[4.8357,45.7640]]}')"
if [ "${http_code}" != "200" ]; then
    echo "FAIL: directions returned ${http_code}"
    cat /tmp/ors-directions.json
    exit 1
fi
distance="$(grep -oE '"distance":[0-9.]+' /tmp/ors-directions.json | head -1)"
echo "OK (${distance})"

echo "==> 3/3 Matrix 3x3 (driving-car)"
http_code="$(curl -fsS -o /tmp/ors-matrix.json -w '%{http_code}' \
    -H "${AUTH}" -H "Content-Type: application/json" \
    -X POST "${BASE}/ors/v2/matrix/driving-car" \
    -d '{"locations":[[2.3522,48.8566],[4.8357,45.7640],[5.3698,43.2965]],"metrics":["duration","distance"]}')"
if [ "${http_code}" != "200" ]; then
    echo "FAIL: matrix returned ${http_code}"
    cat /tmp/ors-matrix.json
    exit 1
fi
echo "OK"

echo
echo "==> Auth gate test (no token, must 401)"
http_code="$(curl -fsS -o /dev/null -w '%{http_code}' "${BASE}/ors/v2/health" || true)"
if [ "${http_code}" != "401" ]; then
    echo "FAIL: unauthed request returned ${http_code} (expected 401)"
    exit 1
fi
echo "OK"

echo
echo "All smoke tests passed."
```

- [ ] **Step 2: chmod + shellcheck**

Run:
```bash
chmod +x infra/ors-self-host/scripts/smoke-test.sh
shellcheck infra/ors-self-host/scripts/smoke-test.sh || true
```

- [ ] **Step 3: Commit**

```bash
git add infra/ors-self-host/scripts/smoke-test.sh
git commit -m "feat(infra): smoke test script (health, directions, matrix, auth gate)"
```

---

### Task 6: Rédiger `scripts/refresh-osm.sh`

**Files:**
- Create: `infra/ors-self-host/scripts/refresh-osm.sh`

- [ ] **Step 1: Écrire le script de refresh mensuel**

Create `infra/ors-self-host/scripts/refresh-osm.sh`:
```bash
#!/usr/bin/env bash
# Refresh mensuel de l'extract OSM France.
# Stratégie v1 : stop-and-rebuild (downtime ~30-60 min).
# Lancé manuellement OU via cron mensuel (cf. crontab dans README).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
DATA_DIR="${COMPOSE_DIR}/data"
GRAPHS_DIR="${COMPOSE_DIR}/graphs"
BACKUP_DIR="${COMPOSE_DIR}/backup"

PBF_URL="https://download.geofabrik.de/europe/france-latest.osm.pbf"
PBF_MD5_URL="${PBF_URL}.md5"
PBF_NAME="france-latest.osm.pbf"

mkdir -p "${DATA_DIR}" "${BACKUP_DIR}"

echo "==> 1/6 Download new PBF + checksum"
curl -fsSL -o "${DATA_DIR}/${PBF_NAME}.new" "${PBF_URL}"
curl -fsSL -o "${DATA_DIR}/${PBF_NAME}.md5.new" "${PBF_MD5_URL}"

echo "==> 2/6 Verify MD5"
cd "${DATA_DIR}"
# Geofabrik MD5 file format: "<md5>  <filename>"
expected_md5="$(awk '{print $1}' "${PBF_NAME}.md5.new")"
actual_md5="$(md5sum "${PBF_NAME}.new" | awk '{print $1}')"
if [ "${expected_md5}" != "${actual_md5}" ]; then
    echo "FAIL: MD5 mismatch (expected ${expected_md5}, got ${actual_md5})"
    rm -f "${PBF_NAME}.new" "${PBF_NAME}.md5.new"
    exit 1
fi
echo "OK"

echo "==> 3/6 Backup current PBF + graphs"
if [ -f "${PBF_NAME}" ]; then
    mv "${PBF_NAME}" "${BACKUP_DIR}/${PBF_NAME}.$(date +%Y%m%d)"
fi
if [ -d "${GRAPHS_DIR}" ] && [ "$(ls -A "${GRAPHS_DIR}" 2>/dev/null)" ]; then
    tar -C "${GRAPHS_DIR}" -czf "${BACKUP_DIR}/graphs.$(date +%Y%m%d).tar.gz" .
fi

echo "==> 4/6 Swap new PBF in place + force rebuild"
mv "${PBF_NAME}.new" "${PBF_NAME}"
mv "${PBF_NAME}.md5.new" "${PBF_NAME}.md5"
rm -rf "${GRAPHS_DIR}"/*

echo "==> 5/6 Stop + start ORS to rebuild graphs"
cd "${COMPOSE_DIR}"
docker compose stop ors
# REBUILD_GRAPHS=True forces graph rebuild on next start.
docker compose run --rm -e REBUILD_GRAPHS=True ors echo "graphs rebuilt"
docker compose up -d ors

echo "==> 6/6 Wait for ORS to be healthy + smoke test"
# Wait up to 30 min for healthcheck to flip to "healthy".
for i in $(seq 1 60); do
    status="$(docker inspect -f '{{.State.Health.Status}}' coup-laine-ors 2>/dev/null || echo "starting")"
    if [ "${status}" = "healthy" ]; then
        break
    fi
    echo "  waiting (${i}/60) — status=${status}"
    sleep 30
done

if [ "${status}" != "healthy" ]; then
    echo "FAIL: ORS did not become healthy within 30 min"
    exit 1
fi

"${SCRIPT_DIR}/smoke-test.sh"

# Retention: keep last 3 backups.
cd "${BACKUP_DIR}"
ls -1t ${PBF_NAME}.* 2>/dev/null | tail -n +4 | xargs -r rm
ls -1t graphs.*.tar.gz 2>/dev/null | tail -n +4 | xargs -r rm

echo
echo "Refresh OSM completed successfully."
```

- [ ] **Step 2: chmod + shellcheck**

Run:
```bash
chmod +x infra/ors-self-host/scripts/refresh-osm.sh
shellcheck infra/ors-self-host/scripts/refresh-osm.sh || true
```

- [ ] **Step 3: Commit**

```bash
git add infra/ors-self-host/scripts/refresh-osm.sh
git commit -m "feat(infra): monthly osm refresh script (download, verify, rebuild, smoke test)"
```

---

### Task 7: Compléter le README avec sections opérationnelles

**Files:**
- Modify: `infra/ors-self-host/README.md`

- [ ] **Step 1: Ajouter les sections "Initial provisioning", "Cron", "Troubleshooting"**

Append à `infra/ors-self-host/README.md` :
```markdown

## Initial provisioning (étapes complètes)

### Côté Hetzner Cloud

1. Créer un projet "coup-laine".
2. Créer un serveur **CCX13** (2 vCPU dédié AMD, 8 GB, 80 GB NVMe), **Falkenstein FSN1**, Ubuntu 24.04 LTS.
3. Ajouter ta clé SSH publique au moment de la création.
4. Noter l'IPv4 publique de la VPS.

### Côté Cloudflare DNS

1. Aller dans la zone `ravnkode.com`.
2. Créer un enregistrement **A** : `coup-laine-ors` → `<IPv4 VPS>`. Proxy status : **DNS only** (gris, pas orange).
   - Raison : Caddy fait sa propre TLS via Let's Encrypt en HTTP-01 challenge. Si Cloudflare proxie, le challenge passe par Cloudflare ce qui complique. Pour la simplicité v1, on bypass.
3. TTL : auto.

### Côté VPS

```bash
# SSH en root
ssh root@<IPv4 VPS>

# Bootstrap (clone repo + Docker + ufw)
curl -fsSL https://raw.githubusercontent.com/<your-user>/coupe-laine/main/infra/ors-self-host/scripts/install-vps.sh | bash
# OU si déjà cloné :
cd /opt/coup-laine
bash infra/ors-self-host/scripts/install-vps.sh

# Configurer les secrets
cd /opt/coup-laine/infra/ors-self-host
cp .env.example .env
# Générer un token (à reporter aussi dans Supabase Secrets ensuite) :
echo "ORS_API_TOKEN=$(openssl rand -hex 32)"
# Éditer .env : ORS_DOMAIN, ORS_API_TOKEN (le token généré), CADDY_ACME_EMAIL
nano .env

# Premier build : download PBF + rebuild graphes (~30-60 min)
./scripts/refresh-osm.sh

# Si refresh-osm.sh a échoué avant le up final, lancer la stack
docker compose up -d

# Smoke test
./scripts/smoke-test.sh
```

## Cron mensuel — refresh OSM

Installer un cron root sur la VPS pour exécuter le refresh le 1er du mois à 03h00 UTC :

```bash
sudo crontab -e
```

Ajouter la ligne :
```
0 3 1 * * cd /opt/coup-laine/infra/ors-self-host && ./scripts/refresh-osm.sh >> /var/log/ors-refresh.log 2>&1
```

Logrotate à mettre en place séparément si le log grossit.

## Troubleshooting

### ORS ne devient pas "healthy" après le build initial
- Vérifier la RAM dispo : `free -h`. Le build France demande ~6 GB de heap (XMX=6g dans compose). Sur une VPS 8 GB, ça doit passer.
- Vérifier les logs : `docker compose logs ors --tail 200`.
- En cas d'OOM kill, passer temporairement à `XMX=5g` et `XMS=1g` dans compose (mais perf matrix réduite).

### Caddy ne provisionne pas le certificat
- Vérifier que le port 80 est ouvert et que le DNS pointe bien sur la VPS : `curl -I http://coup-laine-ors.ravnkode.com` doit toucher Caddy.
- Vérifier les logs : `docker compose logs caddy --tail 100`.
- Si erreur "rate limit" Let's Encrypt, attendre 1h.

### Le proxy Supabase répond 502
- Vérifier que la Edge Function a bien les bonnes secrets : `supabase secrets list`.
- Tester directement l'instance ORS via smoke-test.sh.

### Rollback rapide vers ORS public
Voir section "Rollback" en haut de ce README.

## Limites connues

- **Downtime ~30-60 min/mois** lors du refresh OSM (stratégie stop-and-rebuild). Acceptable v1.
- **Single point of failure** : une seule VPS, pas de HA. Si la VPS tombe, l'app perd la cartographie. Plan B : rollback temporaire vers ORS public en éditant les Supabase Secrets (5 min de downtime).
- **Backup ne couvre pas l'OS** : si la VPS est détruite, il faut re-provisionner et re-télécharger le PBF. Tolérable car aucune donnée utilisateur n'est sur cette VPS — c'est un service stateless.
```

- [ ] **Step 2: Commit**

```bash
git add infra/ors-self-host/README.md
git commit -m "docs(infra): ors-self-host operational runbook"
```

---

### Task 8: Modifier `ors-proxy/index.ts` pour lire `ORS_BASE_URL` depuis env

**Files:**
- Modify: `supabase/functions/ors-proxy/index.ts`

- [ ] **Step 1: Inspecter le code actuel**

Le code actuel hard-code `ORS_BASE = 'https://api.openrouteservice.org'`. On veut :
- Lire `ORS_BASE_URL` depuis env (avec fallback sur l'URL publique pour rétrocompat).
- Renommer mentalement `ORS_API_KEY` → token Bearer (le format change pour notre instance privée).

- [ ] **Step 2: Réécrire `index.ts`**

Replace le contenu de `supabase/functions/ors-proxy/index.ts` par :

```typescript
// supabase/functions/ors-proxy/index.ts
import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';

// Base URL of the upstream ORS instance.
// - Public HeiGIT API: "https://api.openrouteservice.org"
// - Self-hosted (Hetzner + Caddy): "https://coup-laine-ors.ravnkode.com/ors"
const ORS_BASE = Deno.env.get('ORS_BASE_URL') ?? 'https://api.openrouteservice.org';

// Authorization header value sent upstream.
// - Public HeiGIT: the raw API key, sent as "Authorization: <key>".
// - Self-hosted: "Bearer <token>" matching the Caddy gate.
// Reads ORS_API_TOKEN first (new), falls back to ORS_API_KEY (legacy) for rollback compat.
const ORS_AUTH = Deno.env.get('ORS_API_TOKEN') ?? Deno.env.get('ORS_API_KEY');

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
        'Access-Control-Allow-Headers': 'authorization, content-type',
      },
    });
  }

  if (!ORS_AUTH) {
    return new Response('ORS_API_TOKEN (or legacy ORS_API_KEY) not configured', {
      status: 500,
      headers: {
        'Content-Type': 'text/plain',
        'Access-Control-Allow-Origin': '*',
      },
    });
  }

  const url = new URL(req.url);
  const subPath = url.pathname.replace(/^\/ors-proxy\/?/, '');
  if (!subPath) {
    return new Response('Missing ORS sub-path', {
      status: 400,
      headers: {
        'Content-Type': 'text/plain',
        'Access-Control-Allow-Origin': '*',
      },
    });
  }

  const targetUrl = `${ORS_BASE}/${subPath}`;
  const body = req.method === 'POST' ? await req.text() : undefined;

  let orsResponse: Response;
  try {
    orsResponse = await fetch(targetUrl, {
      method: req.method,
      headers: {
        'Authorization': ORS_AUTH,
        'Content-Type': 'application/json',
      },
      body,
    });
  } catch (e) {
    return new Response(`Upstream fetch failed: ${e}`, {
      status: 502,
      headers: {
        'Content-Type': 'text/plain',
        'Access-Control-Allow-Origin': '*',
      },
    });
  }

  const upstreamContentType =
    orsResponse.headers.get('content-type') ?? 'application/json';
  const relayedHeaders: Record<string, string> = {
    'Content-Type': upstreamContentType,
    'Access-Control-Allow-Origin': '*',
  };
  const upstreamCacheControl = orsResponse.headers.get('cache-control');
  if (upstreamCacheControl) {
    relayedHeaders['Cache-Control'] = upstreamCacheControl;
  }
  return new Response(await orsResponse.text(), {
    status: orsResponse.status,
    headers: relayedHeaders,
  });
});
```

Key changes vs. ancien code :
- `ORS_BASE` lu depuis env `ORS_BASE_URL` avec fallback public.
- Variable d'auth renommée `ORS_AUTH`, lue de `ORS_API_TOKEN` (nouveau) puis `ORS_API_KEY` (legacy fallback).
- Aucun changement de comportement public si seule la legacy var est set.

- [ ] **Step 3: Lint / typecheck local Deno (optionnel)**

Si tu as Deno installé localement :
```bash
deno check supabase/functions/ors-proxy/index.ts
```
Expected: pas d'erreur. Le `deno.json` du dossier devrait suffire à la résolution.

- [ ] **Step 4: Commit**

```bash
git add supabase/functions/ors-proxy/index.ts
git commit -m "feat(ors-proxy): read ORS_BASE_URL + ORS_API_TOKEN from env (legacy ORS_API_KEY fallback)"
```

---

### Task 9: Provisionner la VPS Hetzner et la configurer

**Files:** Aucun (opération sur infrastructure externe).

- [ ] **Step 1: Créer la VPS dans Hetzner Cloud Console**

1. Aller sur https://console.hetzner.cloud → créer projet "coup-laine".
2. Add Server :
   - Location : Falkenstein (FSN1)
   - Image : Ubuntu 24.04
   - Type : **CCX13** (2 vCPU dédié AMD, 8 GB)
   - Networking : IPv4 + IPv6 publiques
   - SSH Keys : ajouter ta clé publique (`~/.ssh/id_ed25519.pub`)
   - Name : `coup-laine-ors-fsn1`
3. Create & Buy now (~13 € HT/mois facturé à l'heure).
4. Noter l'IPv4 publique.

- [ ] **Step 2: Configurer le DNS Cloudflare**

1. Cloudflare Dashboard → zone `ravnkode.com` → DNS records.
2. Add record :
   - Type : **A**
   - Name : `coup-laine-ors`
   - IPv4 : `<IPv4 VPS>`
   - Proxy status : **DNS only** (nuage gris, pas orange)
   - TTL : Auto
3. Vérifier :
```bash
dig coup-laine-ors.ravnkode.com +short
```
Expected : l'IPv4 de la VPS.

- [ ] **Step 3: SSH vers la VPS + bootstrap**

```bash
ssh root@<IPv4 VPS>
# Sur la VPS :
apt-get update -y && apt-get install -y git
git clone https://github.com/<your-user>/coupe-laine.git /opt/coup-laine
cd /opt/coup-laine
bash infra/ors-self-host/scripts/install-vps.sh
```

Expected : le script affiche "Done" sans erreur. Docker, ufw, fail2ban actifs.

- [ ] **Step 4: Configurer `.env` sur la VPS**

```bash
cd /opt/coup-laine/infra/ors-self-host
cp .env.example .env
# Générer le token :
TOKEN=$(openssl rand -hex 32)
echo "Generated ORS_API_TOKEN=${TOKEN}"
# (NOTER ce token, il sera reporté dans Supabase Secrets en Task 11.)
# Éditer .env pour renseigner :
#   ORS_DOMAIN=coup-laine-ors.ravnkode.com
#   ORS_API_TOKEN=<le token>
#   CADDY_ACME_EMAIL=rgauthier@expertime.com
nano .env
```

- [ ] **Step 5: Premier run + build des graphes ORS (~30-60 min)**

```bash
cd /opt/coup-laine/infra/ors-self-host
./scripts/refresh-osm.sh
```

Expected : download PBF (~3.5 GB), MD5 OK, build graphes en ~30-60 min, ORS healthy, smoke test PASS.

Si le smoke test échoue car la TLS Caddy n'est pas encore prête, attendre 2 min et relancer :
```bash
./scripts/smoke-test.sh
```

- [ ] **Step 6: Installer le cron mensuel**

```bash
sudo crontab -e
```

Ajouter :
```
0 3 1 * * cd /opt/coup-laine/infra/ors-self-host && ./scripts/refresh-osm.sh >> /var/log/ors-refresh.log 2>&1
```

Sauver, vérifier :
```bash
sudo crontab -l
```

---

### Task 10: Smoke test depuis l'extérieur (laptop dev)

**Files:** Aucun (test de vérification).

- [ ] **Step 1: Test depuis ton laptop**

Sur ta machine de dev (pas sur la VPS) :
```bash
TOKEN="<le token généré en Task 9 Step 4>"
curl -fsS -H "Authorization: Bearer ${TOKEN}" \
    https://coup-laine-ors.ravnkode.com/ors/v2/health
```
Expected : `{"status":"ready"}` (ou similaire status 200).

- [ ] **Step 2: Test matrix end-to-end depuis le laptop**

```bash
curl -fsS -H "Authorization: Bearer ${TOKEN}" \
    -H "Content-Type: application/json" \
    -X POST https://coup-laine-ors.ravnkode.com/ors/v2/matrix/driving-car \
    -d '{"locations":[[2.3522,48.8566],[4.8357,45.7640],[5.3698,43.2965]],"metrics":["duration","distance"]}' \
    | python -m json.tool | head -20
```
Expected : JSON valide avec `durations` et `distances`, status 200.

- [ ] **Step 3: Test auth gate (sans token, doit 401)**

```bash
curl -i -s https://coup-laine-ors.ravnkode.com/ors/v2/health | head -1
```
Expected : `HTTP/2 401`.

---

### Task 11: Mettre à jour les Supabase Secrets et déployer la fonction

**Files:** Aucun en local (opération sur Supabase).

- [ ] **Step 1: Mettre à jour les secrets via Supabase CLI**

```bash
# Depuis le repo local, login si pas déjà fait.
supabase login
supabase link --project-ref <ton-project-ref>

# Set les nouvelles secrets (le token doit matcher celui de la VPS) :
supabase secrets set ORS_BASE_URL="https://coup-laine-ors.ravnkode.com/ors"
supabase secrets set ORS_API_TOKEN="Bearer <le-token-généré>"
# Note: ORS_API_TOKEN contient le préfixe "Bearer " car le proxy
# le passe tel quel dans le header Authorization vers Caddy.

# Optionnel: garder ORS_API_KEY pour rollback rapide.
supabase secrets list
```

Expected: la liste montre `ORS_BASE_URL`, `ORS_API_TOKEN`, et l'ancien `ORS_API_KEY`.

- [ ] **Step 2: Déployer la fonction `ors-proxy`**

```bash
supabase functions deploy ors-proxy
```
Expected : `Function deployed successfully`.

- [ ] **Step 3: Smoke test via la Edge Function**

```bash
SUPABASE_URL="<https://xxx.supabase.co>"
SUPABASE_ANON_KEY="<anon key>"
curl -fsS -X POST \
    -H "Authorization: Bearer ${SUPABASE_ANON_KEY}" \
    -H "Content-Type: application/json" \
    "${SUPABASE_URL}/functions/v1/ors-proxy/v2/matrix/driving-car" \
    -d '{"locations":[[2.3522,48.8566],[4.8357,45.7640]],"metrics":["duration","distance"]}' \
    | head -50
```
Expected : JSON ORS valide. Le path `v2/matrix/...` est forwardé vers `https://coup-laine-ors.ravnkode.com/ors/v2/matrix/...`.

---

### Task 12: Tester depuis le dev client RN

**Files:** Aucun (test bout en bout).

- [ ] **Step 1: Lancer le dev client**

```bash
cd C:\Users\rapha\Documents\Development\coupe-laine
pnpm start
```

- [ ] **Step 2: Réaliser une création de tournée draft de bout en bout**

Sur le device/simulateur :
1. Lancer l'app (déjà signé/onboardé).
2. Aller dans Tours → Nouvelle tournée.
3. Sélectionner ≥ 3 clients géolocalisés.
4. Valider, déclencher l'optimisation auto.
5. Vérifier que la tournée s'affiche avec distances et durées **non-nulles**.

Expected :
- Aucune erreur réseau côté app.
- Distances/durées affichées cohérentes.
- Côté VPS, `docker compose logs caddy --tail 20` montre des requêtes 200 sur `/ors/v2/matrix/driving-car`.

- [ ] **Step 3: Test de charge léger (optionnel mais recommandé)**

Depuis le laptop :
```bash
TOKEN="<token>"
for i in $(seq 1 20); do
    curl -fsS -o /dev/null -w '%{http_code} %{time_total}\n' \
        -H "Authorization: Bearer ${TOKEN}" \
        -H "Content-Type: application/json" \
        -X POST https://coup-laine-ors.ravnkode.com/ors/v2/matrix/driving-car \
        -d '{"locations":[[2.3522,48.8566],[4.8357,45.7640],[5.3698,43.2965],[1.4442,43.6047]],"metrics":["duration","distance"]}'
done
```
Expected : 20 × `200 0.x` (latence < 2s par requête). Si > 5s, vérifier saturation CPU sur la VPS via `htop`.

---

### Task 13: Mettre en place le monitoring d'uptime

**Files:** Aucun en local (opération externe).

- [ ] **Step 1: Créer un monitor UptimeRobot (free tier)**

1. https://uptimerobot.com → créer compte.
2. Add New Monitor :
   - Type : HTTP(s)
   - Friendly Name : `coup-laine ORS`
   - URL : `https://coup-laine-ors.ravnkode.com/ors/v2/health`
   - HTTP Headers : `Authorization: Bearer <token>`
   - Monitoring Interval : 5 min
   - Alert Contacts : email rgauthier@expertime.com
3. Create.

Expected : status `Up` après ~5 min.

- [ ] **Step 2: Test alerting**

Stopper temporairement Caddy sur la VPS :
```bash
docker compose stop caddy
```
Attendre 10-15 min : UptimeRobot doit envoyer un email d'incident.

Relancer :
```bash
docker compose start caddy
```

Expected : email "Up" reçu après détection.

---

### Task 14: Documenter la décision de cutover + mettre à jour le TODO

**Files:**
- Modify: `TODO.md`

- [ ] **Step 1: Ajouter une entrée dans la section "Livrées"**

Le plan business model #4 reste en À venir, mais ORS self-host (qui en est un prérequis) est livré. Ajouter sous "Livrées" :

```markdown
### ORS self-host & proxy cutover
**Mergé sur `main`** — 2026-MM-DD (commit XXX)
**Plan :** `docs/superpowers/plans/2026-05-12-ors-self-host.md`
**Spec business model parent :** `docs/superpowers/specs/2026-05-12-business-model-design.md`

#### Ce qui a été livré

- VPS Hetzner CCX13 (Falkenstein, ~13 € HT/mois) avec Ubuntu 24.04 + Docker + ufw + fail2ban.
- Stack `infra/ors-self-host/` : docker-compose ORS v8.1.1 + Caddy 2.8 (TLS Let's Encrypt + bearer-token gate).
- Domaine `coup-laine-ors.ravnkode.com` (Cloudflare DNS only, pas de proxy).
- Cron mensuel `refresh-osm.sh` : download Geofabrik France + MD5 verify + rebuild graphes + smoke test.
- `supabase/functions/ors-proxy/index.ts` lit `ORS_BASE_URL` + `ORS_API_TOKEN` depuis env (fallback legacy `ORS_API_KEY` préservé pour rollback).
- Monitoring UptimeRobot 5 min sur l'endpoint health.
- Runbook complet : provisioning, refresh manuel, troubleshooting, rollback.

#### Pourquoi

Le plan ORS Standard public (gratuit, 500 matrix/jour collectif) sature dès 2-3 utilisateurs actifs et HeiGIT n'offre pas de plan commercial managé public. Self-host = coût fixe ~13 €/mois indépendant du volume.

#### Plan B documenté

Si l'instance ORS pose des problèmes opérationnels chroniques après 6 mois, évaluer Valhalla self-host (licence MIT). Décision actée dans le spec parent §1.
```

- [ ] **Step 2: Commit final**

```bash
git add TODO.md
git commit -m "docs(todo): mark ORS self-host livré"
```

---

## Self-Review

### Spec coverage check

La spec business model §1 décrit la cartographie self-host (Section 1, sous-section "Cartographie — décision : self-host ORS" + Section 4 sous-section "Provisionnement ORS self-host"). Couverture :

| Exigence spec | Task(s) |
|---|---|
| Provisionner VPS Hetzner | Task 9 |
| Déployer ORS via Docker compose officiel | Tasks 2, 9 |
| Extract Geofabrik France | Tasks 6, 9 |
| Endpoint privé sécurisé (auth) | Tasks 3, 9 |
| Re-pointer `ors-proxy` via env var | Tasks 8, 11 |
| Cron mensuel refresh OSM | Tasks 6, 9 |
| Smoke test bout en bout | Tasks 5, 10, 11, 12 |
| Plan B Valhalla documenté | Tasks 1 (README), 14 (TODO) |
| Rollback path validé | Task 1 (README rollback section) |
| Monitoring | Task 13 |

Tout couvert.

### Placeholder scan

Recherche des patterns interdits ("TBD", "TODO", "appropriate error handling", "similar to Task N", etc.). Une seule occurrence acceptable : `<REPLACE_WITH_YOUR_GITHUB_USER>` dans le script `install-vps.sh` — c'est un placeholder de runtime explicitement signalé pour l'opérateur, pas un trou dans le plan. Le `<ton-project-ref>` dans Task 11 est idem : valeur Supabase spécifique à l'environnement, normale.

### Type consistency

- `ORS_BASE_URL` utilisé cohéremment de Task 8 à Task 11.
- `ORS_API_TOKEN` cohérent du `.env` (Task 1) au Supabase secret (Task 11).
- `coup-laine-ors.ravnkode.com` cohérent partout.
- Script names cohérents (`install-vps.sh`, `refresh-osm.sh`, `smoke-test.sh`).
- Image tags pinnés cohéremment (`v8.1.1`, `2.8-alpine`).

Aucune divergence détectée.

---

## Execution Handoff

**Plan complete and saved to `docs/superpowers/plans/2026-05-12-ors-self-host.md`.**

Deux options d'exécution :

**1. Subagent-Driven (recommended)** — un subagent frais par task, revue entre tâches, itération rapide. Adapté ici car les tasks 1-8 sont du code/fichier classique, et les tasks 9-13 sont des opérations externes (Hetzner, Cloudflare, Supabase Dashboard, UptimeRobot) que tu devras valider à la main de toute façon.

**2. Inline Execution** — exécution dans cette session via executing-plans, batch avec checkpoints. Approprié si tu veux suivre pas à pas.

Note importante : les tasks 9-13 nécessitent des actions hors-codebase (création VPS payante ~13 €/mois, configuration DNS Cloudflare, secrets Supabase, monitoring). À tes commandes pour savoir si tu lances ces opérations maintenant ou si on s'arrête après les tasks 1-8 (préparation code/scripts dans le repo) en attendant que tu fasses les opérations admin.

**Quelle approche ?**
