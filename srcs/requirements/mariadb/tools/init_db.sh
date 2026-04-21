#!/bin/sh

set -e

MYSQL_PASSWORD=$(cat /run/secrets/db_password)
MYSQL_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)

if [ ! -d "/var/lib/mysql/${MYSQL_DATABASE}" ]; then

    echo "[MariaDB] First start detected — initializing database..."

    mysql_install_db --user=mysql --datadir=/var/lib/mysql > /dev/null

    mysqld --user=mysql --skip-networking &
    TEMP_PID=$!

    echo "[MariaDB] Waiting for server to be ready..."
    until mysqladmin ping --silent; do
        sleep 1
    done

    echo "[MariaDB] Server ready. Running setup SQL..."

    mysql -u root << EOF

CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;

CREATE USER IF NOT EXISTS \`${MYSQL_USER}\`@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';

GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO \`${MYSQL_USER}\`@'%';

ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';

DELETE FROM mysql.user WHERE User='';

FLUSH PRIVILEGES;

EOF

    echo "[MariaDB] Setup complete. Stopping temporary server..."

    mysqladmin -u root -p"${MYSQL_ROOT_PASSWORD}" shutdown

    wait $TEMP_PID

    echo "[MariaDB] Initialization done."
fi

echo "[MariaDB] Starting MariaDB server..."
exec mysqld --user=mysql --datadir=/var/lib/mysql --bind-address=0.0.0.0 --port=3306 --skip-networking=0
