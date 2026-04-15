#!/bin/sh
set -e

WP_PATH="/var/www/wordpress"

# WP_CLI_ALLOW_ROOT=1 évite de passer --allow-root sur chaque commande wp
export WP_CLI_ALLOW_ROOT=1

# Lecture des secrets depuis les fichiers montés dans /run/secrets/
MYSQL_PASSWORD=$(cat /run/secrets/db_password)
WP_ADMIN_PASSWORD=$(cat /run/secrets/credentials)
WP_USER_PASSWORD=$(cat /run/secrets/wp_user_password)

if [ ! -f "${WP_PATH}/wp-config.php" ]; then

    echo "[WordPress] First start — installing..."

    mkdir -p "${WP_PATH}"
    wp core download --path="${WP_PATH}"

    wp config create \
        --path="${WP_PATH}" \
        --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="${MYSQL_PASSWORD}" \
        --dbhost="mariadb"

    wp core install \
        --path="${WP_PATH}" \
        --url="https://${DOMAIN_NAME}" \
        --title="Inception" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --skip-email

    # Crée un utilisateur normal (non-admin)
    wp user create "${WP_USER}" "${WP_USER_EMAIL}" \
        --path="${WP_PATH}" \
        --role=author \
        --user_pass="${WP_USER_PASSWORD}"

    echo "[WordPress] Installation complete."
fi

echo "[WordPress] Starting PHP-FPM..."
exec php-fpm -F -R
