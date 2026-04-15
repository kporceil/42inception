#!/bin/sh
# =============================================================
# Inception — test suite
# Lance ce script depuis la racine du projet après "make"
# Usage : sh tests/test.sh
# =============================================================

DOMAIN="kporceil.42.fr"
PASS=0
FAIL=0

# ─── helpers ──────────────────────────────────────────────────

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
RESET='\033[0m'

ok() {
    printf "${GREEN}[PASS]${RESET} %s\n" "$1"
    PASS=$((PASS + 1))
}

fail() {
    printf "${RED}[FAIL]${RESET} %s\n" "$1"
    FAIL=$((FAIL + 1))
}

section() {
    printf "\n${YELLOW}=== %s ===${RESET}\n" "$1"
}

# ─── 1. CONTAINERS ────────────────────────────────────────────

section "Containers"

for name in nginx wordpress mariadb; do
    status=$(docker inspect --format '{{.State.Status}}' "$name" 2>/dev/null)
    if [ "$status" = "running" ]; then
        ok "Container '$name' is running"
    else
        fail "Container '$name' is not running (status: ${status:-not found})"
    fi
done

# ─── 2. HEALTHCHECK MARIADB ───────────────────────────────────

section "MariaDB healthcheck"

health=$(docker inspect --format '{{.State.Health.Status}}' mariadb 2>/dev/null)
if [ "$health" = "healthy" ]; then
    ok "MariaDB is healthy"
else
    fail "MariaDB healthcheck status: '${health:-unknown}'"
fi

# ─── 3. IMAGES — pas de pull DockerHub ────────────────────────

section "Docker images"

for name in nginx wordpress mariadb; do
    image=$(docker inspect --format '{{.Config.Image}}' "$name" 2>/dev/null)
    # Une image buildée localement n'a pas de ":" avec un tag DockerHub
    # Elle est référencée par son nom de projet compose
    built=$(docker images --format '{{.Repository}}' | grep "inception-${name}\|inception_${name}" | head -1)
    if [ -n "$built" ]; then
        ok "Image '$name' is built locally (not pulled)"
    else
        fail "Image '$name' not found as a local build"
    fi
done

# ─── 4. RÉSEAU ────────────────────────────────────────────────

section "Docker network"

net=$(docker network ls --format '{{.Name}}' | grep "inception")
if [ -n "$net" ]; then
    ok "Docker network 'inception' exists ($net)"
else
    fail "Docker network 'inception' not found"
fi

# Vérifie que chaque container est bien sur le réseau inception
for name in nginx wordpress mariadb; do
    connected=$(docker inspect "$name" --format '{{range $k, $v := .NetworkSettings.Networks}}{{$k}} {{end}}' 2>/dev/null | grep "inception")
    if [ -n "$connected" ]; then
        ok "Container '$name' is on the inception network"
    else
        fail "Container '$name' is NOT on the inception network"
    fi
done

# ─── 5. VOLUMES ───────────────────────────────────────────────

section "Volumes"

for vol in inception_db_data inception_wp_data; do
    exists=$(docker volume ls --format '{{.Name}}' | grep "^${vol}$")
    if [ -n "$exists" ]; then
        ok "Volume '$vol' exists"
    else
        fail "Volume '$vol' not found"
    fi
done

# Vérifie que les données sont bien dans /home/kporceil/data/
for path in /home/kporceil/data/db /home/kporceil/data/wordpress; do
    if [ -d "$path" ] && [ "$(ls -A $path 2>/dev/null)" ]; then
        ok "Host data directory '$path' exists and is not empty"
    else
        fail "Host data directory '$path' is missing or empty"
    fi
done

# ─── 6. PORTS ─────────────────────────────────────────────────

section "Ports"

# Port 443 doit être ouvert
if curl -sk --max-time 5 "https://${DOMAIN}" -o /dev/null -w "%{http_code}" | grep -qE "^[23]"; then
    ok "Port 443 (HTTPS) is open and responding"
else
    # Essai avec l'IP directement
    code=$(curl -sk --max-time 5 "https://127.0.0.1" -o /dev/null -w "%{http_code}")
    if echo "$code" | grep -qE "^[23]"; then
        ok "Port 443 (HTTPS) is open and responding (via 127.0.0.1)"
    else
        fail "Port 443 (HTTPS) is not responding (HTTP code: $code)"
    fi
fi

# Port 80 ne doit PAS être accessible
code=$(curl -s --max-time 3 "http://${DOMAIN}" -o /dev/null -w "%{http_code}" 2>/dev/null)
if [ "$code" = "000" ] || [ -z "$code" ]; then
    ok "Port 80 (HTTP) is correctly closed"
else
    fail "Port 80 (HTTP) is open — should be closed (HTTP code: $code)"
fi

# ─── 7. TLS ───────────────────────────────────────────────────

section "TLS"

# Vérifie le protocole TLS utilisé
tls=$(echo | openssl s_client -connect "${DOMAIN}:443" 2>/dev/null | grep "Protocol")
if echo "$tls" | grep -qE "TLSv1\.[23]"; then
    ok "TLS protocol is TLSv1.2 or TLSv1.3 ($tls)"
else
    fail "TLS protocol check failed: $tls"
fi

# ─── 8. WORDPRESS ─────────────────────────────────────────────

section "WordPress"

# La page d'accueil doit renvoyer du HTML WordPress
body=$(curl -sk --max-time 10 "https://${DOMAIN}")
if echo "$body" | grep -qi "wordpress\|wp-content"; then
    ok "WordPress homepage is serving content"
else
    fail "WordPress homepage does not look like a WordPress site"
fi

# La page wp-login.php doit être accessible
code=$(curl -sk --max-time 5 "https://${DOMAIN}/wp-login.php" -o /dev/null -w "%{http_code}")
if [ "$code" = "200" ]; then
    ok "WordPress login page (/wp-login.php) is accessible"
else
    fail "WordPress login page returned HTTP $code"
fi

# ─── 9. MARIADB — base et utilisateurs ───────────────────────

section "MariaDB database"

DB_PASS=$(cat secrets/db_password.txt 2>/dev/null | tr -d '[:space:]')
ROOT_PASS=$(cat secrets/db_root_password.txt 2>/dev/null | tr -d '[:space:]')
DB_USER=$(grep MYSQL_USER srcs/.env | cut -d= -f2)
DB_NAME=$(grep MYSQL_DATABASE srcs/.env | cut -d= -f2)

if [ -z "$DB_PASS" ] || [ -z "$ROOT_PASS" ]; then
    fail "Cannot read secrets files — skipping MariaDB checks"
else
    # Vérifie que la base wordpress existe
    db_exists=$(docker exec mariadb mariadb -u root -p"${ROOT_PASS}" -e "SHOW DATABASES;" 2>/dev/null | grep "^${DB_NAME}$")
    if [ -n "$db_exists" ]; then
        ok "Database '${DB_NAME}' exists"
    else
        fail "Database '${DB_NAME}' not found"
    fi

    # Vérifie que l'utilisateur wordpress existe
    user_exists=$(docker exec mariadb mariadb -u root -p"${ROOT_PASS}" -e "SELECT User FROM mysql.user;" 2>/dev/null | grep "^${DB_USER}$")
    if [ -n "$user_exists" ]; then
        ok "Database user '${DB_USER}' exists"
    else
        fail "Database user '${DB_USER}' not found"
    fi

    # Vérifie que l'utilisateur peut se connecter
    conn=$(docker exec mariadb mariadb -u "${DB_USER}" -p"${DB_PASS}" -e "SELECT 1;" 2>/dev/null)
    if echo "$conn" | grep -q "1"; then
        ok "Database user '${DB_USER}' can connect successfully"
    else
        fail "Database user '${DB_USER}' cannot connect"
    fi
fi

# ─── 10. SECRETS ─────────────────────────────────────────────

section "Secrets"

for secret in db_password db_root_password credentials wp_user_password; do
    # Vérifie que le secret est bien monté dans le container concerné
    case "$secret" in
        db_password|db_root_password)   container="mariadb" ;;
        credentials|wp_user_password)   container="wordpress" ;;
    esac
    mounted=$(docker exec "$container" ls /run/secrets/ 2>/dev/null | grep "^${secret}$")
    if [ -n "$mounted" ]; then
        ok "Secret '$secret' is mounted in '$container'"
    else
        fail "Secret '$secret' is NOT mounted in '$container'"
    fi
done

# ─── 11. RESTART POLICY ───────────────────────────────────────

section "Restart policy"

for name in nginx wordpress mariadb; do
    policy=$(docker inspect --format '{{.HostConfig.RestartPolicy.Name}}' "$name" 2>/dev/null)
    if [ "$policy" = "unless-stopped" ] || [ "$policy" = "always" ]; then
        ok "Container '$name' has restart policy: $policy"
    else
        fail "Container '$name' restart policy is '$policy' (expected unless-stopped or always)"
    fi
done

# ─── RÉSUMÉ ───────────────────────────────────────────────────

TOTAL=$((PASS + FAIL))
printf "\n${YELLOW}=== Results ===${RESET}\n"
printf "${GREEN}Passed: %d${RESET} / %d\n" "$PASS" "$TOTAL"
if [ "$FAIL" -gt 0 ]; then
    printf "${RED}Failed: %d${RESET} / %d\n" "$FAIL" "$TOTAL"
    exit 1
else
    printf "${GREEN}All tests passed.${RESET}\n"
    exit 0
fi
